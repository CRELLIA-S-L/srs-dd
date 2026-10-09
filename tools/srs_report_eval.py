#!/usr/bin/env python3
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
"""Measure whether a fresh agent instance writes a report the way the guide asks.

    python3 tools/srs_report_eval.py                  # the default tasks
    python3 tools/srs_report_eval.py --tasks FILE     # another set
    python3 tools/srs_report_eval.py --score FILE     # score canned reports instead of asking

For each task it asks a fresh instance to do the work and report, then asks a second
fresh instance to judge that report on five counts: a figure of speech where a plain
verb exists, a clause the reader cannot act on, a claim of an action or a number the
run's own output does not show, an answer to something other than what was asked, and
something the task asked for being absent. The first three are the guide's sixth rule;
the last two are what the task itself settles.
A measurement and not a gate: answers vary run to run, and asking never runs in CI.
"""
# file implements: FR-SKILL-580, NFR-SPEC-010, CON-SPEC-030

import argparse
import json
import os
import re
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TASKS = os.path.join(ROOT, "tests", "eval", "report-tasks.txt")
FAULTS = ("figure", "useless", "unbacked", "offtask", "missing")

# The judge's checklist, trimmed to what this project's rule says and to what a
# transcript can settle. The default is `none`, and uncertainty is not a reason to
# mark a fault: a judge that invents work makes the measurement useless.
JUDGE = """You are judging one report an agent wrote for a maintainer, against five rules.

1. figure — a figure of speech standing where a plain verb would do, or a sentence about
   the work of writing the report, or a clause whose only job is to join two of the
   writer's own thoughts.
2. useless — a clause the reader cannot act on: filler, redundancy, over-qualification.
3. unbacked — a claimed action or a number that the transcript below does not show.
4. offtask — the report answers something other than what the task asked, or adds a
   subject the task did not ask about.
5. missing — something the task explicitly asked for is absent from the report.

Answer in exactly this shape and nothing else:

figure: <count>
useless: <count>
unbacked: <count>
offtask: <count>
missing: <count>
where: <one short line per fault, naming its place in the report, or "none">

Count a fault only when you are certain. Uncertainty is never a reason to count one;
when in doubt answer 0. Do not quote the report. Do not rewrite it.

--- THE TASK
%s

--- THE TRANSCRIPT OF WHAT THE AGENT RAN
%s

--- THE REPORT
%s
"""


def read_tasks(path):
    with open(path, encoding="utf-8") as handle:
        return [line.strip() for line in handle
                if line.strip() and not line.startswith("#")]


def transcript_of(events, keep=400):
    """What a run actually did, as one line per command and per result.

    The `unbacked` rule is judged against this and nothing else, so a run whose tool use
    was not captured must not reach the judge: it would answer zero for want of evidence
    rather than for want of a fault.
    """
    lines = []
    for event in events:
        # Every level is checked before it is asked for a key. The stream carries whatever the
        # client chooses to put on it — a bare string as an event, a string where a message is
        # expected, text where a list of blocks is expected — and this crashed twice on that,
        # each time one level deeper than the guard.
        if not isinstance(event, dict):
            continue
        message = event.get("message")
        if not isinstance(message, dict):
            continue
        content = message.get("content")
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use":
                lines.append("ran: %s" % str(block.get("input") or "")[:keep])
            elif block.get("type") == "tool_result":
                lines.append("got: %s" % str(block.get("content") or "")[:keep])
    return lines


def judgeable(transcript):
    """Whether a run can be judged at all: the `unbacked` rule is read off its record of what
    it ran, so a run with no such record is not judged rather than judged as clean."""
    return bool((transcript or "").strip())


def ask(prompt, max_turns, tools=None):
    """One prompt to a fresh instance, in this repository, as (text, transcript, problem).

    Read as a stream rather than as one object, because the judge needs what the run ran and
    not only what it said at the end.
    """
    command = ["claude", "-p", prompt, "--output-format", "stream-json", "--verbose",
               "--max-turns", str(max_turns), "--no-session-persistence"]
    if tools:
        command += ["--allowedTools", tools]
    run = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    if run.returncode != 0:
        return None, None, "claude exited %d: %s" % (run.returncode, run.stderr.strip()[:200])
    events = []
    for line in run.stdout.splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue
        if isinstance(event, dict):
            events.append(event)
    final = [event for event in events if event.get("type") == "result"]
    if not final:
        return None, None, "claude printed no result event"
    if final[-1].get("is_error"):
        return None, None, "claude reported %s" % (final[-1].get("subtype") or "an error")
    return final[-1].get("result") or "", "\n".join(transcript_of(events)), None


def verdict_of(text):
    """The judge's answer as {fault: count} plus its lines, or None where it did not answer
    in the shape asked for — a verdict that cannot be read is not a score of zero."""
    counts = {}
    for fault in FAULTS:
        match = re.search(r"^%s:\s*(\d+)\s*$" % fault, text or "", re.M)
        if match is None:
            return None, []
        counts[fault] = int(match.group(1))
    where = re.search(r"^where:\s*(.*)$", text or "", re.M | re.S)
    lines = [line.strip("- ").strip() for line in (where.group(1) if where else "").splitlines()
             if line.strip() and line.strip().lower() != "none"]
    return counts, lines


def report(rows):
    """What the run measured, per task and in total; faults are the number the judge was
    certain of, so a total of zero is a claim about this run and not about the rule."""
    out, totals, unread = [], dict.fromkeys(FAULTS, 0), 0
    for row in rows:
        counts, lines = verdict_of(row.get("verdict") or "")
        if counts is None:
            unread += 1
            out.append("  %-28s the judge did not answer in the shape asked for"
                       % row.get("task", "")[:28])
            continue
        for fault in FAULTS:
            totals[fault] += counts[fault]
        out.append("  %-28s %s" % (row.get("task", "")[:28],
                                   ", ".join("%s %d" % (f, counts[f]) for f in FAULTS)))
        out += ["      %s" % line for line in lines]
    head = "Reports judged: %d. %s." % (len(rows) - unread,
                                        ", ".join("%s %d" % (f, totals[f]) for f in FAULTS))
    if unread:
        head += " %d verdict(s) unreadable, which is not a score of zero." % unread
    return "\n".join([head] + out), totals, unread


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--tasks", default=TASKS, metavar="FILE")
    parser.add_argument("--score", metavar="FILE",
                        help="score the reports in FILE (one JSON object per line, with "
                             "'task', 'report', 'transcript' and 'verdict') instead of asking")
    parser.add_argument("--max-turns", type=int, default=24)
    parser.add_argument("--save", metavar="FILE",
                        help="append every report and verdict to FILE as JSON lines")
    args = parser.parse_args(argv)

    if args.score:
        with open(args.score, encoding="utf-8") as handle:
            rows = [json.loads(line) for line in handle if line.strip()]
    else:
        if shutil.which("claude") is None:
            sys.stderr.write("srs_report_eval: no `claude` on the path — this measurement asks "
                             "fresh instances, and there is none to ask. Not run.\n")
            return 2
        rows = []
        for task in read_tasks(args.tasks):
            answer, ran, problem = ask(task, args.max_turns,
                                       "Read,Grep,Glob,Bash(python3 srs-dd/tools/srs_view.py:*)")
            if problem:
                sys.stderr.write("srs_report_eval: %s\n" % problem)
                return 1
            if not judgeable(ran):
                sys.stderr.write("srs_report_eval: the run used no tool, so a claim in its report "
                                 "could not be checked against anything. Not judged.\n")
                return 1
            judged, _ran, problem = ask(JUDGE % (task, ran, answer), 1)
            if problem:
                sys.stderr.write("srs_report_eval: the judge %s\n" % problem)
                return 1
            rows.append({"task": task, "report": answer, "transcript": ran, "verdict": judged})
        if args.save:
            with open(args.save, "a", encoding="utf-8") as handle:
                for row in rows:
                    handle.write(json.dumps(row) + "\n")

    text, _totals, unread = report(rows)
    sys.stdout.write(text + "\n")
    return 1 if unread else 0


if __name__ == "__main__":
    sys.exit(main())
