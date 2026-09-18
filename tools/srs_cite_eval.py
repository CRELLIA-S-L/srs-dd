#!/usr/bin/env python3
"""Measure whether a fresh agent instance names records the way the guide asks.

Asks a non-interactive Claude Code instance the questions in a file, one at a
time, in this repository, and scores each answer: of the records it names —
requirements, elements, register records, decisions — how many are named at
their first mention in the citation form the guide asks for, with the title
the project actually gives them.

A measurement, not a gate: the answers of a model vary run to run, and the
number this prints is read by whoever changes the guides, against the number
before the change. It never runs in CI, and it says so and stops where no
agent CLI is on the path.

    python3 tools/srs_cite_eval.py                       # the default questions
    python3 tools/srs_cite_eval.py --questions FILE      # another set
    python3 tools/srs_cite_eval.py --score FILE          # score canned answers instead of asking
"""
# implements: FR-SKILL-290, NFR-SPEC-010, CON-SPEC-030

import argparse
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUESTIONS = os.path.join(ROOT, "tests", "eval", "citation-questions.txt")
TOOLS = {"E": "srs_arch.py", "H": "srs_grounds.py", "B": "srs_grounds.py",
         "U": "srs_grounds.py", "I": "srs_grounds.py", "F": "srs_grounds.py"}


def read_questions(path):
    with open(path, encoding="utf-8") as handle:
        return [line.strip() for line in handle
                if line.strip() and not line.startswith("#")]


def identifier_pattern(areas):
    """Every identifier this project can name — requirements by the declared
    areas, decisions, and the records of the two layers — as (core, mention,
    span): the bare alternation, the pattern for one mention of it, and the
    pattern for a span written with it at either end."""
    area = "|".join(re.escape(a) for a in areas)
    core = r"(?:FR|NFR|IF|INV|CON)-(?:%s)-\d{3}|ADR-\d{4}|[EHBUIF]-\d{3}" % area
    mention = re.compile(r"\b(%s)\b" % core)
    span = re.compile(SPAN.replace("ID", core))
    return mention, span


def citations(ids):
    """What each tool prints for the identifiers it holds: {id: line}. An
    identifier no tool resolves is left out, and a mention of it is not a
    record of this project."""
    found = {}
    groups = {}
    for rid in ids:
        kind = rid.split("-")[0]
        tool = "srs_view.py" if kind in ("FR", "NFR", "IF", "INV", "CON", "ADR") else TOOLS.get(kind)
        if tool:
            groups.setdefault(tool, []).append(rid)
    for tool, wanted in groups.items():
        path = os.path.join(ROOT, "tools", tool)
        if not os.path.exists(path):
            continue
        run = subprocess.run([sys.executable, path, "--cite"] + sorted(wanted),
                             capture_output=True, text=True, cwd=ROOT)
        for line in run.stdout.splitlines():
            rid = line.split(" — ", 1)[0].strip()
            if rid in wanted:
                found[rid] = line.strip()
    return found


# The far end may be a number alone — "FR-GND-010…540" — which is how a
# span is written when both ends share the area. Assembled with the core
# alternation by identifier_pattern.
SPAN = r"`?(ID)`?\s*(?:through|to|…|\.\.\.|–|—|-)\s*`?(?:(ID)|\d{3})`?"


def mentions(answer, mention, span):
    """Where each record is first named on its own, {id: offset}, in the
    order of naming. The ends of a span — "A through B", "A…B", "A–B" — are
    one name for a set and not a mention of each member, so an occurrence
    inside a span is passed over; the same record named alone elsewhere is a
    mention, and is scored where it stands alone."""
    order = {}
    for match in mention.finditer(answer):
        rid = match.group(1)
        if rid in order:
            continue
        around = answer[max(0, match.start() - 40):match.end() + 40]
        if any(rid in (g for g in m.groups() if g) for m in span.finditer(around)):
            continue
        order[rid] = match.start()
    return order


def score(answer, pattern):
    """`pattern` is what identifier_pattern returned. (cited, retyped, bare, unknown): the records the answer names at their
    first mention with the citation the project prints; the ones named with
    the right title, file and status but not as printed; the ones named bare
    or with a citation the project does not print; and the identifiers that
    are nobody's record here. The ends of a span are not mentions."""
    mention, span = pattern
    order = mentions(answer, mention, span)
    known = citations(list(order))
    cited, retyped, bare, unknown = [], [], [], []
    for rid, first in order.items():
        if rid not in known:
            unknown.append(rid)
            continue
        # The citation is what the tool printed, from the identifier on. A
        # mention that carries the right title, file and status within the
        # next few hundred characters but not as printed — bold around it,
        # the file in backticks, something added inside the brackets — was
        # retyped, and is counted apart: right in substance, and the one form
        # an invented citation can hide in.
        if answer[first:first + len(known[rid])] == known[rid]:
            cited.append(rid)
        else:
            title, rest = known[rid].split(" — ", 1)[1].rsplit(" (", 1)
            path, status = rest.rstrip(")").rsplit(", ", 1)
            window = answer[first:first + len(known[rid]) + 200]
            if title in window and path in window and status in window:
                retyped.append(rid)
            else:
                bare.append(rid)
    return cited, retyped, bare, unknown


def ask(question, max_turns):
    """One question to a fresh instance, in this repository, reading only."""
    command = [
        "claude", "-p", question, "--output-format", "json",
        "--max-turns", str(max_turns), "--no-session-persistence",
        # Both spellings the client documents for a command prefix, because a
        # declined --cite is an instance citing by hand, which is the failure
        # this measures and must not be the harness's doing.
        "--allowedTools", "Read,Grep,Glob,Bash(python3 tools/*),"
                          "Bash(python3 tools/srs_view.py:*),Bash(python3 tools/srs_arch.py:*),"
                          "Bash(python3 tools/srs_grounds.py:*)",
    ]
    run = subprocess.run(command, capture_output=True, text=True, cwd=ROOT)
    if run.returncode != 0:
        return None, "claude exited %d: %s" % (run.returncode, run.stderr.strip()[:200])
    try:
        payload = json.loads(run.stdout)
    except ValueError:
        return None, "claude printed something other than JSON"
    if payload.get("is_error"):
        return None, "claude reported %s: %s" % (payload.get("subtype", "an error"),
                                                 str(payload.get("result") or "")[:200])
    return payload.get("result") or "", None


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--questions", default=QUESTIONS, metavar="FILE")
    parser.add_argument("--score", metavar="FILE",
                        help="score the answers in FILE (one JSON object per line, "
                             "with 'question' and 'answer') instead of asking an agent")
    parser.add_argument("--max-turns", type=int, default=24)
    parser.add_argument("--save", metavar="FILE",
                        help="append every answer to FILE as JSON lines, so a run can be re-scored")
    args = parser.parse_args(argv)

    model = json.loads(subprocess.run(
        [sys.executable, os.path.join(ROOT, "tools", "srs_view.py"), "--json"],
        capture_output=True, text=True, cwd=ROOT, check=True).stdout)
    pattern = identifier_pattern(model["areas"])

    if args.score:
        with open(args.score, encoding="utf-8") as handle:
            rows = [json.loads(line) for line in handle if line.strip()]
        answers = [(row["question"], row["answer"], None) for row in rows]
    else:
        if shutil.which("claude") is None:
            sys.stderr.write("srs_cite_eval: no `claude` on the path — this measurement asks a "
                             "fresh Claude Code instance, and there is none to ask. Not run.\n")
            return 2
        answers = []
        for question in read_questions(args.questions):
            answer, problem = ask(question, args.max_turns)
            answers.append((question, answer, problem))
            if args.save and answer is not None:
                with open(args.save, "a", encoding="utf-8") as handle:
                    handle.write(json.dumps({"question": question, "answer": answer},
                                            ensure_ascii=False) + "\n")

    totals = {"cited": 0, "retyped": 0, "bare": 0}
    for question, answer, problem in answers:
        sys.stdout.write("Q: %s\n" % question)
        if problem:
            sys.stdout.write("   not answered — %s\n\n" % problem)
            continue
        cited, retyped, bare, unknown = score(answer, pattern)
        totals["cited"] += len(cited)
        totals["retyped"] += len(retyped)
        totals["bare"] += len(bare)
        sys.stdout.write("   cited %d, retyped %d, bare %d%s\n" % (
            len(cited), len(retyped), len(bare),
            ", not this project's: %s" % ", ".join(unknown) if unknown else ""))
        for rid in retyped:
            sys.stdout.write("   retyped: %s\n" % rid)
        for rid in bare:
            sys.stdout.write("   bare: %s\n" % rid)
        sys.stdout.write("\n")
    named = sum(totals.values())
    if named:
        sys.stdout.write("Records named: %d — cited as printed %d (%.0f%%), retyped %d (%.0f%%), bare %d (%.0f%%).\n"
                         % (named, totals["cited"], 100.0 * totals["cited"] / named,
                            totals["retyped"], 100.0 * totals["retyped"] / named,
                            totals["bare"], 100.0 * totals["bare"] / named))
    else:
        sys.stdout.write("Records named: 0.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
