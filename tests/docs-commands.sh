#!/usr/bin/env bash
# Every command the documentation names is one the tool accepts: for each
# line of README.md and docs/*.md that names a tool of this repository
# together with a flag, the flag is one the tool lists when asked.
set -eo pipefail
cd "$(dirname "$0")/.."

# verifies: FR-DOC-020
# The pair is what is checked — a flag on its own belongs to nothing, and
# the drift this exists to catch is a document naming the wrong tool for a
# flag it knows. A tool says what it accepts on -h: the argparse ones print
# their help, the hand-parsed ones refuse -h and print their usage line, and
# either output carries every flag. Neither runs the tool for its effect.
python3 - <<'PY'
import glob, re, subprocess, sys

TOOL = re.compile(r"\bsrs_[a-z]+\.py\b")
FLAG = re.compile(r"(?<![\w-])--[a-z][a-z-]*")

accepted = {}
def flags_of(tool):
    if tool not in accepted:
        run = subprocess.run(["python3", "tools/" + tool, "-h"],
                             capture_output=True, text=True)
        accepted[tool] = set(FLAG.findall(run.stdout + run.stderr))
    return accepted[tool]

pairs, failures = 0, []
for path in ["README.md"] + sorted(glob.glob("docs/*.md")):
    carried = None      # the tool a backslash-continued command line started with
    with open(path, encoding="utf-8") as handle:
        for number, line in enumerate(handle, 1):
            # A pair is a tool and a flag on one line — or on the continuation
            # lines of a command the tool's line ended with a backslash.
            spans = [(m.group(), m.end()) for m in TOOL.finditer(line)]
            if carried and not spans:
                spans = [(carried, 0)]
            for index, (tool, start) in enumerate(spans):
                end = len(line)
                if index + 1 < len(spans):
                    end = line.index(spans[index + 1][0], start)
                for flag in FLAG.findall(line[start:end]):
                    pairs += 1
                    if flag not in flags_of(tool):
                        failures.append("%s:%d — %s does not accept %s"
                                        % (path, number, tool, flag))
            carried = spans[-1][0] if line.rstrip().endswith("\\") and spans else None

if pairs == 0:
    sys.exit("docs-commands: no tool-and-flag pair found in the documentation; "
             "the pattern is broken, not the docs")
for text in failures:
    print(text)
if failures:
    sys.exit(1)
print("docs-commands: %d documented command flags are accepted by their tools" % pairs)
PY
