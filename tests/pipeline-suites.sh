#!/usr/bin/env bash
# The pipeline runs every suite the local gate runs. The local gate lists
# tests/ by itself; the pipeline names its suites one step each, so that a
# failure carries the suite's name, and a list written by hand is the one a
# new suite is left out of. This holds the list to the directory, and
# the table of suites in specs/50-verification.md with it.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# verifies: FR-CI-120, FR-CI-130
python3 - <<'PY'
import glob, os, re, shutil, sys, tempfile

RE_STEP = re.compile(r"^\s+run:\s+tests/([\w.-]+\.sh)\s*$", re.M)
RE_ROW = re.compile(r"^\| `tests/([\w.-]+\.sh)` \|", re.M)


def check(root):
    """[problem] over root: a file in tests/ the pipeline never runs or the
    verification table never names, and a step or a row naming a file that
    is not there."""
    with open(os.path.join(root, ".github/workflows/srs.yml"), encoding="utf-8") as handle:
        stepped = set(RE_STEP.findall(handle.read()))
    present = {os.path.basename(p) for p in glob.glob(os.path.join(root, "tests", "*.sh"))}
    problems = ["tests/%s is not a step of the pipeline" % name for name in sorted(present - stepped)]
    problems += ["the pipeline runs tests/%s, which does not exist" % name for name in sorted(stepped - present)]
    with open(os.path.join(root, "specs/50-verification.md"), encoding="utf-8") as handle:
        tabled = set(RE_ROW.findall(handle.read()))
    problems += ["tests/%s is not in the table of specs/50-verification.md" % name for name in sorted(present - tabled)]
    problems += ["specs/50-verification.md describes tests/%s, which does not exist" % name for name in sorted(tabled - present)]
    return problems


# --- Negation first, on a lab: a suite with no step or no row and a step or
# --- row with no suite must each be reported; a suite named inside a longer
# --- command is not a step of its own, and prose naming one is not a row.
lab = tempfile.mkdtemp()
os.makedirs(os.path.join(lab, ".github/workflows"))
os.makedirs(os.path.join(lab, "tests"))
os.makedirs(os.path.join(lab, "specs"))
open(os.path.join(lab, "specs/50-verification.md"), "w").write(
    "| Suite | Covers |\n|---|---|\n| `tests/kept.sh` | x |\n| `tests/forgotten.sh` | x |\n"
    "| `tests/mentioned.sh` | x |\n| `tests/stale.sh` | x |\n\nProse naming `tests/kept.sh` is no row.\n")
open(os.path.join(lab, "tests/untabled.sh"), "w").write("#!/bin/sh\n")
for name in ("kept.sh", "forgotten.sh", "mentioned.sh"):
    open(os.path.join(lab, "tests", name), "w").write("#!/bin/sh\n")
open(os.path.join(lab, ".github/workflows/srs.yml"), "w").write(
    "jobs:\n  gate:\n    steps:\n"
    "      - name: Kept\n        run: tests/kept.sh\n"
    "      - name: Gone\n        run: tests/gone.sh\n"
    "      - name: Both\n        run: tests/mentioned.sh && echo done\n")
found = check(lab)
assert "tests/forgotten.sh is not a step of the pipeline" in found, found
assert "the pipeline runs tests/gone.sh, which does not exist" in found, found
assert "tests/mentioned.sh is not a step of the pipeline" in found, found
assert "tests/untabled.sh is not a step of the pipeline" in found, found
assert "tests/untabled.sh is not in the table of specs/50-verification.md" in found, found
assert "specs/50-verification.md describes tests/stale.sh, which does not exist" in found, found
assert len(found) == 6, found
shutil.rmtree(lab)
print("pipeline-suites: a suite with no step or no row, a step or row with no suite, and a suite run inside another command are each red")

# --- Then the repository.
found = check(".")
for line in found:
    print("  " + line)
if found:
    print("pipeline-suites: %d problem(s)" % len(found))
    sys.exit(1)
print("pipeline-suites: the pipeline runs every file in tests/ as a step of its own, and the verification table names each (%d)"
      % len(glob.glob("tests/*.sh")))
PY
