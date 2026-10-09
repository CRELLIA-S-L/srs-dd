#!/usr/bin/env bash
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# The instructions the framework ships are held to the rule they state about a
# report: plain statements, no figure of speech where a plain verb exists.
#
# file implements: FR-SKILL-560
# file verifies: FR-SKILL-560
#
# This is a ratchet and says so: it holds a list of figures that were found in
# these files and taken out, and it fails if one comes back. It cannot judge a
# figure nobody has written yet, and nothing here pretends otherwise — the list
# grows when the next one is found and removed. It is worth having because the
# agent that writes these files is the one with the habit, and a text cleaned
# once decays without something watching it.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

python3 - <<'PY'
import glob
import io
import sys

# Found in these files on 2026-10-09 and removed. Each is a figure standing in
# for a plain verb, which is what the shipped guide's sixth rule forbids.
TAKEN_OUT = (
    "key handed over",
    "teaches every reader",
    "paid for by a reader",
    "a name nobody has found",
    "in passing is a mention",
)


def instructions():
    """The files an agent reads as instruction: the shipped guide and the method, the
    starter of a project's guide, this repository's own, and every procedure."""
    return (["srs-dd/guide.md", "srs-dd/method.md", "AGENTS.md", "skeleton/AGENTS.md"]
            + sorted(glob.glob(".claude/skills/*/SKILL.md")))


def returned(paths, banned=TAKEN_OUT):
    found = []
    for path in paths:
        with io.open(path, encoding="utf-8") as handle:
            text = handle.read()
        found += [(path, phrase) for phrase in banned if phrase in text]
    return found


# The check itself, both ways round: a file holding one of them is red, and one
# holding none is green. Without this pair the suite would pass on an empty list.
import tempfile, os
with tempfile.TemporaryDirectory() as lab:
    clean, dirty = os.path.join(lab, "a.md"), os.path.join(lab, "b.md")
    io.open(clean, "w", encoding="utf-8").write("A report says what happened.\n")
    io.open(dirty, "w", encoding="utf-8").write("The citation is a key handed over.\n")
    assert returned([clean]) == []
    assert returned([dirty]) == [(dirty, "key handed over")]
    assert returned([clean], banned=("happened",)) == [(clean, "happened")]
print("plain-instructions: a figure that came back, and a clean file, are each decided")

back = returned(instructions())
for path, phrase in back:
    print("plain-instructions: %s says again: %s" % (path, phrase))
if back:
    sys.exit(1)
print("plain-instructions: no figure this list has taken out is back (%d files, %d phrases)"
      % (len(instructions()), len(TAKEN_OUT)))
PY
