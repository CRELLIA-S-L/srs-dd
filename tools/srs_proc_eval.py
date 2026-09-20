#!/usr/bin/env python3
"""Measure what a procedure costs a fresh agent instance, and what it yields.

Runs a non-interactive Claude Code instance through each scenario in a set —
a task put to one of the shipped procedures, in this repository — and reports,
per run: the tokens the run added to the context beyond its first turn, the
tokens it burned over all its turns, what it wrote out, its turns, and
whether every check the scenario states was met. The checks are read off the run's own trace, so the scoring
asks nobody; so are the tokens, which the client reports per turn. The cost
of the procedure's own text is the file's, and is counted from the file.

A measurement, not a gate: a run varies, the client needs an account and a
network, and the number is read against the number before a change by whoever
made it. Every run's trace is kept, so that a claim about what an instance
read can be checked afterwards. Where no agent client is on the path the
command says so and stops.

    python3 tools/srs_proc_eval.py                     # every scenario, once
    python3 tools/srs_proc_eval.py --runs 3            # each scenario three times
    python3 tools/srs_proc_eval.py --only srs-check    # one scenario
    python3 tools/srs_proc_eval.py --save FILE         # the traces go to FILE (default .srs-eval/)
    python3 tools/srs_proc_eval.py --score FILE        # score saved traces instead of asking
    python3 tools/srs_proc_eval.py --json FILE         # the report as JSON as well

A scenario is a directory under tests/eval/scenarios/ holding prompt.md: a
header of `key: value` lines between two `---` lines, then the prompt. Keys:

    procedure: NAME                 the procedure under test, .claude/skills/NAME
    max_turns: 20                   turns the instance may take (default 24)
    allowed_tools: Read,Grep,...    what the client is allowed (default: reading and the tools)
    free: ID                        an identifier the scenario assumes the specification does not carry
    check: skill NAME               the instance invoked the procedure NAME
    check: ran REGEX                a Bash command matching REGEX was run
    check: not_ran REGEX            no Bash command matches REGEX
    check: no_tool NAME             the tool NAME was never used (Edit, Write, ...)
    check: answer REGEX             the final answer matches REGEX
    check: no_answer REGEX          the final answer does not match REGEX

Every check line is one check; a scenario states as many as it needs, and
at least one.
"""
# implements: FR-SKILL-310, NFR-SPEC-010, CON-SPEC-030

import argparse
import datetime
import glob
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENARIOS = os.path.join(ROOT, "tests", "eval", "scenarios")
SAVE_DIR = os.path.join(ROOT, ".srs-eval")
# Reading, and the project's own tools — both spellings the client documents
# for a command prefix, as srs_cite_eval.py passes them: a declined tool is
# an instance working by hand, which is the failure this measures and must
# not be the harness's doing.
DEFAULT_TOOLS = ("Read,Grep,Glob,Skill,Bash(python3 tools/*),"
                 "Bash(python3 tools/srs_view.py:*),Bash(python3 tools/srs_check.py:*),"
                 "Bash(python3 tools/srs_arch.py:*),Bash(python3 tools/srs_grounds.py:*)")
CHECK_KINDS = ("skill", "ran", "not_ran", "no_tool", "answer", "no_answer")
USAGE_KEYS = ("input_tokens", "cache_creation_input_tokens",
              "cache_read_input_tokens", "output_tokens")


def read_scenario(directory):
    """One scenario: (scenario, None) or (None, problem). A malformed one is
    a setup fault, reported before anything runs."""
    path = os.path.join(directory, "prompt.md")
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    rel = os.path.relpath(path, ROOT)
    if not text.startswith("---\n") or "\n---\n" not in text[4:]:
        return None, "%s: no `---` header" % rel
    header, prompt = text[4:].split("\n---\n", 1)
    scenario = {"name": os.path.basename(directory.rstrip("/")), "prompt": prompt.strip(),
                "procedure": None, "max_turns": 24, "allowed_tools": DEFAULT_TOOLS,
                "free": [], "checks": []}
    for line in header.split("\n"):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        key, _, value = line.partition(":")
        key, value = key.strip(), value.strip()
        if key == "procedure":
            scenario["procedure"] = value
        elif key == "max_turns":
            if not value.isdigit():
                return None, "%s: max_turns must be a number, not `%s`" % (rel, value)
            scenario["max_turns"] = int(value)
        elif key == "allowed_tools":
            scenario["allowed_tools"] = value
        elif key == "free":
            scenario["free"].append(value)
        elif key == "check":
            kind, _, argument = value.partition(" ")
            if kind not in CHECK_KINDS or not argument.strip():
                return None, "%s: check `%s` — the kinds are %s, each with an argument" % (
                    rel, value, ", ".join(CHECK_KINDS))
            scenario["checks"].append((kind, argument.strip()))
        else:
            return None, "%s: unknown header key `%s`" % (rel, key)
    if not scenario["procedure"]:
        return None, "%s: no `procedure:` line — which procedure is under test" % rel
    if not os.path.isfile(os.path.join(ROOT, ".claude", "skills", scenario["procedure"], "SKILL.md")):
        return None, "%s: procedure `%s` does not ship" % (rel, scenario["procedure"])
    if not scenario["prompt"]:
        return None, "%s: no prompt after the header" % rel
    if not scenario["checks"]:
        return None, "%s: no `check:` line — a scenario states what a good run leaves behind" % rel
    return scenario, None


def read_scenarios(only=None):
    scenarios = []
    for directory in sorted(glob.glob(os.path.join(SCENARIOS, "*"))):
        if not os.path.isfile(os.path.join(directory, "prompt.md")):
            continue
        if only and os.path.basename(directory) not in only:
            continue
        scenario, problem = read_scenario(directory)
        if problem:
            return None, problem
        scenarios.append(scenario)
    if not scenarios:
        return None, "no scenario under %s%s" % (
            os.path.relpath(SCENARIOS, ROOT), " named %s" % ", ".join(only) if only else "")
    return scenarios, None


def procedure_size(name):
    """What the procedure's own text costs, counted from the file: its
    words and its bytes. The turn after the procedure is loaded also
    carries whatever else the client wrote that turn, so the trace is the
    wrong place to read this from."""
    path = os.path.join(ROOT, ".claude", "skills", name, "SKILL.md")
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    return {"words": len(text.split()), "bytes": len(text.encode("utf-8"))}


def run_agent(scenario):
    """One fresh instance through one scenario; the raw stream-json events."""
    command = [
        "claude", "-p", scenario["prompt"], "--output-format", "stream-json", "--verbose",
        "--max-turns", str(scenario["max_turns"]), "--no-session-persistence",
        "--allowedTools", scenario["allowed_tools"],
    ]
    run = subprocess.run(command, capture_output=True, text=True, cwd=ROOT)
    events = []
    for line in run.stdout.split("\n"):
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except ValueError:
            return None, "claude printed a line that is not JSON: %s" % line[:120]
    if not any(event.get("type") == "result" for event in events):
        return None, "claude exited %d without a result: %s" % (
            run.returncode, run.stderr.strip()[:200])
    return events, None


def trace_of(events):
    """What the scoring and the accounting read: the tool uses in order,
    the usage of every assistant turn, the final answer, and what the
    client summed up. Kept whole, so that the run can be re-read later."""
    tools, turns, answer, result = [], [], "", {}
    for event in events:
        kind = event.get("type")
        if kind == "assistant":
            message = event.get("message", {})
            for block in message.get("content", []) or []:
                if block.get("type") == "tool_use":
                    tools.append({"name": block.get("name", ""), "input": block.get("input", {})})
                elif block.get("type") == "text":
                    answer = block.get("text", "")
            usage = message.get("usage") or {}
            turns.append({key: int(usage.get(key, 0) or 0) for key in USAGE_KEYS})
        elif kind == "result":
            result = event
            if event.get("result"):
                answer = event["result"]
    return {"tools": tools, "turns": turns, "answer": answer,
            "cost_usd": float(result.get("total_cost_usd", 0) or 0),
            "num_turns": int(result.get("num_turns", len(turns)) or 0),
            # How the run ended, as the client says it: `success`, or the
            # reason it stopped — the turn limit, most often. A run that
            # hit the limit failed its checks for want of turns, and the
            # report says so beside the score rather than leaving the two
            # to be told apart by hand.
            "stop": result.get("subtype") or ("error" if result.get("is_error") else "success"),
            "is_error": bool(result.get("is_error"))}


def context_of(turn):
    return (turn["cache_read_input_tokens"] + turn["cache_creation_input_tokens"]
            + turn["input_tokens"])


def account(trace):
    """The tokens, from the per-turn usage the client reports: the floor
    is the context of the first turn — the client's prompt, its tools, the
    guides — which belongs to the client and not to the procedure; what
    the run added is the context at its last turn beyond that floor."""
    turns = trace["turns"]
    floor = context_of(turns[0]) if turns else 0
    end = context_of(turns[-1]) if turns else 0
    output = sum(turn["output_tokens"] for turn in turns)
    created = sum(turn["cache_creation_input_tokens"] for turn in turns)
    read = sum(turn["cache_read_input_tokens"] for turn in turns)
    fresh = sum(turn["input_tokens"] for turn in turns)
    # Burned: everything that went into the model and came out of it over
    # the whole run, every turn re-reading the context before it — the
    # number a price list multiplies, kept here in tokens.
    return {"floor": floor, "end": end, "added": end - floor, "output": output,
            "cache_created": created, "cache_read": read, "input": fresh,
            "burned": created + read + fresh + output}


def command_of(tool):
    return str(tool["input"].get("command", "")) if tool["name"] == "Bash" else ""


def grade(scenario, trace):
    """Every check of the scenario against the trace: [(kind, argument, passed)]."""
    results = []
    for kind, argument in scenario["checks"]:
        if kind == "skill":
            passed = any(tool["name"] == "Skill" and tool["input"].get("skill") == argument
                         for tool in trace["tools"])
        elif kind == "ran":
            # Searched, not prefixed: an instance chains commands with `&&`
            # and `;`, and a tool run second in a line was run. A regex, so
            # that a scenario can say "a segment that starts with" where a
            # path in an argument must not count.
            passed = any(re.search(argument, command_of(tool)) for tool in trace["tools"])
        elif kind == "not_ran":
            passed = not any(re.search(argument, command_of(tool)) for tool in trace["tools"])
        elif kind == "no_tool":
            passed = not any(tool["name"] == argument for tool in trace["tools"])
        elif kind == "answer":
            passed = re.search(argument, trace["answer"], re.S) is not None
        else:
            passed = re.search(argument, trace["answer"], re.S) is None
        results.append((kind, argument, passed))
    return results


def report_line(name, run, tokens, trace, graded):
    met = sum(1 for _, _, passed in graded if passed)
    stop = trace.get("stop", "success")
    return ("%-14s run %d  floor %6d  added %6d  burned %8d  out %5d  turns %2d  checks %d/%d%s"
            % (name, run, tokens["floor"], tokens["added"], tokens["burned"], tokens["output"],
               trace["num_turns"], met, len(graded),
               "" if stop == "success" else "  stopped: %s" % stop))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--runs", type=int, default=1)
    parser.add_argument("--only", action="append", metavar="NAME")
    parser.add_argument("--save", metavar="FILE",
                        help="where the traces go, one JSON line per run "
                             "(default: .srs-eval/<timestamp>.jsonl)")
    parser.add_argument("--score", metavar="FILE", help="score the runs saved in FILE; ask nobody")
    parser.add_argument("--json", metavar="FILE", help="write the report as JSON too")
    args = parser.parse_args(argv)

    scenarios, problem = read_scenarios(args.only)
    if problem:
        sys.stderr.write("srs_proc_eval: %s\n" % problem)
        return 2
    by_name = {scenario["name"]: scenario for scenario in scenarios}

    runs = []
    if args.score:
        with open(args.score, encoding="utf-8") as handle:
            for line in handle:
                if line.strip():
                    row = json.loads(line)
                    if row["scenario"] in by_name:
                        runs.append((row["scenario"], row["run"], row["trace"]))
        if not runs:
            sys.stderr.write("srs_proc_eval: nothing in %s matches a scenario\n" % args.score)
            return 2
    else:
        if shutil.which("claude") is None:
            sys.stderr.write("srs_proc_eval: no `claude` on the path — this measurement asks a "
                             "fresh agent instance, and there is none to ask here\n")
            return 2
        save = args.save or os.path.join(
            SAVE_DIR, datetime.datetime.now().strftime("%Y%m%d-%H%M%S") + ".jsonl")
        os.makedirs(os.path.dirname(os.path.abspath(save)), exist_ok=True)
        with open(save, "a", encoding="utf-8") as saver:
            for scenario in scenarios:
                for run in range(1, args.runs + 1):
                    events, problem = run_agent(scenario)
                    if problem:
                        sys.stderr.write("srs_proc_eval: %s run %d: %s\n"
                                         % (scenario["name"], run, problem))
                        return 2
                    trace = trace_of(events)
                    # The procedure's size as it was when this run was taken:
                    # a trace scored later, after the procedure was cut, must
                    # report the text the run actually followed.
                    trace["procedure_size"] = procedure_size(scenario["procedure"])
                    runs.append((scenario["name"], run, trace))
                    saver.write(json.dumps({"scenario": scenario["name"], "run": run,
                                            "trace": trace}, ensure_ascii=False) + "\n")
                    saver.flush()
        print("traces: %s" % os.path.relpath(save, ROOT))

    rows = []
    for name, run, trace in runs:
        tokens = account(trace)
        graded = grade(by_name[name], trace)
        rows.append({"scenario": name, "run": run, "procedure": by_name[name]["procedure"],
                     "procedure_size": trace.get("procedure_size")
                     or procedure_size(by_name[name]["procedure"]),
                     "tokens": tokens, "turns": trace["num_turns"],
                     "checks": [{"kind": k, "argument": a, "passed": p} for k, a, p in graded],
                     "stop": trace.get("stop", "success"), "error": trace["is_error"]})
        print(report_line(name, run, tokens, trace, graded))
        for kind, argument, passed in graded:
            if not passed:
                print("    failed: %s %s" % (kind, argument))

    # Per scenario: the procedure's own size, the means of what the runs
    # added and burned, and the share of checks met — what a before/after reads.
    print()
    for scenario in scenarios:
        mine = [row for row in rows if row["scenario"] == scenario["name"]]
        if not mine:
            continue
        n = len(mine)
        # The size the runs were taken under, where the traces carry it;
        # the file as it is now otherwise.
        sizes = {row["procedure_size"]["words"] for row in mine}
        size = "%d" % sizes.pop() if len(sizes) == 1 else "/".join(str(w) for w in sorted(sizes))
        added = sum(row["tokens"]["added"] for row in mine) / n
        burned = sum(row["tokens"]["burned"] for row in mine) / n
        checks = sum(len(row["checks"]) for row in mine)
        met = sum(1 for row in mine for check in row["checks"] if check["passed"])
        print("%-14s %d run(s)  procedure %s %s words  added %6.0f  burned %8.0f  checks met %d of %d" % (
            scenario["name"], n, scenario["procedure"], size, added, burned, met, checks))
    if args.json:
        with open(args.json, "w", encoding="utf-8") as handle:
            json.dump({"runs": rows}, handle, ensure_ascii=False, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
