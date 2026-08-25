#!/usr/bin/env bash
# tools/srs_release.py, exercised in a throwaway clone of this repository:
# it edits files that are committed here, and a test that did that to the
# working copy would be a test nobody dares run twice.
#
# verifies: FR-CI-070, INV-SPEC-030, CON-SPEC-030
set -eo pipefail

# implements: FR-CI-090
# A hook runs with GIT_INDEX_FILE and GIT_DIR pointing at the commit being
# prepared, and everything this suite starts inherits them — so a `git add`
# meant for the throwaway target below would write that target's paths into
# the commit in progress (FR-CI-090). Cleared here, once, before anything.
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

FRAMEWORK=$(pwd)

# The shared assertions (FR-CI-080). Sourced from tools/ because a
# file under tests/ would be run as a suite by the self-test.
. tools/test_lib.sh
rm -rf /tmp/srs-rel
git clone --quiet . /tmp/srs-rel
cd /tmp/srs-rel
git config user.email ci@example.com
git config user.name CI

# A clone carries what is committed; what is under test is the working
# tree. Bring it in and commit it, so the command under test is the current
# one and the tree it starts from is a known state.
# The whole working tree, not a chosen few files. A working-tree checker
# judging a committed specification is a pair that never existed, and the
# specification names more than tools and specs: a requirement whose `code`
# field points at a skill fails here the moment that skill is newer than
# HEAD. Copying everything is the only rule that does not need revisiting
# each time the specification learns to reference something else.
( cd "$FRAMEWORK" && tar --exclude ./.git --exclude ./.srs-site \
                       --exclude ./public -cf - . ) | tar -xf -

# The overlay adds and overwrites; it cannot remove. A file the working tree
# has deleted or renamed survives from the clone and is then judged beside
# its replacement — two files claiming the same identifiers, and a failure
# that says nothing about what is under test. So take out whatever this
# clone carries that the working tree no longer has.
git ls-files -z | while IFS= read -r -d "" f; do
    [ -e "$FRAMEWORK/$f" ] || rm -f "$f"
done
# Regenerate the matrix: the copies are new to this clone, and the command
# refuses on a matrix that is not fresh. The output is kept — a suite that
# discards it reports a dead hook and no reason, which is exactly what the
# commands were taught not to do.
python3 tools/srs_check.py > /tmp/rel-precheck.log 2>&1 || {
    echo "the clone does not pass its own checker:"; cat /tmp/rel-precheck.log
    exit 1
}
git add -A
# Only when there is something to commit: in CI the working tree is the
# committed state, so the copies above change nothing and `git commit`
# would fail on an empty one.
git diff --cached --quiet || git commit -qm "the working tree's tooling"

before=$(git rev-parse HEAD)

# No section in the changelog: refused, and nothing touched.
rc=0; python3 tools/srs_release.py 9.9.9 > /tmp/rel-nosec.log 2>&1 || rc=$?
test "$rc" -eq 2
grep -q "no \`## \[9.9.9\]\` section" /tmp/rel-nosec.log
test "$(git rev-parse HEAD)" = "$before"
test -z "$(git status --porcelain)"


# Write the notes a person owes, the way a release actually starts.
python3 - <<'PY'
text = open('CHANGELOG.md', encoding='utf-8').read()
section = """## [9.9.9]

### Added

- A section written by hand, as the release command requires.

### Upgrade notes

- Nothing to do.

"""
# The first `## [` in the file sits inside the format-contract comment;
# only a heading at the start of a line is one.
import re
anchor = re.search(r'^## \[', text, re.M).start()
open('CHANGELOG.md', 'w', encoding='utf-8').write(
    text[:anchor] + section + text[anchor:])
PY

git add -A
git commit -qm "release notes for 9.9.9"
clean=$(git rev-parse HEAD)

# --dry-run says what it would do and writes nothing at all.
python3 tools/srs_release.py 9.9.9 --dry-run --date 2026-01-02 > /tmp/rel-dry.log
grep -q "Dry run: nothing was written" /tmp/rel-dry.log
test "$(git rev-parse HEAD)" = "$clean"
test -z "$(git status --porcelain)"

# The real run edits files and leaves the history alone: no commit, no tag,
# and it says what to commit (CON-SPEC-030).
python3 tools/srs_release.py 9.9.9 --date 2026-01-02 > /tmp/rel-run.log
test "$(git rev-parse HEAD)" = "$clean"
test -z "$(git tag -l 'v9.9.9')"
grep -q '__version__ = "9.9.9"' tools/srs_parse.py
grep -q '## \[9.9.9\] — 2026-01-02' CHANGELOG.md
grep -q "Commit CHANGELOG.md, tools/srs_parse.py" /tmp/rel-run.log

# One home and two re-exports: a bump that reaches the file but not
# the tools reading it announces the old version to everybody who
# runs them, which is the bug this arrangement replaced (ADR-0021).
python3 tools/srs_check.py --no-write > /tmp/rel-ver-spec.log 2>&1
grep -q "(srs_check 9.9.9)" /tmp/rel-ver-spec.log
python3 tools/srs_grounds.py --no-write > /tmp/rel-ver-gnd.log 2>&1
grep -q "(srs_grounds 9.9.9)" /tmp/rel-ver-gnd.log

# A release is not a baseline: it freezes nothing and leaves the log and
# the `spec/v*` namespace alone (INV-SPEC-030).
test -z "$(git tag -l 'spec/v9.9.9')"
git diff --quiet -- specs/92-baselines.md

# Committed with an ordinary client, it is a release like any other.
git add -A
git commit -qm "SRS-DD 9.9.9"
python3 tools/srs_check.py --strict --no-write >/dev/null

# Preparing the same release twice is refused, and the dated section is
# what says so — no git client had to be asked.
rc=0; python3 tools/srs_release.py 9.9.9 > /tmp/rel-twice.log 2>&1 || rc=$?
test "$rc" -eq 2
grep -q "already dated" /tmp/rel-twice.log
test -z "$(git status --porcelain)"

# A failing checker stops it before anything is written.
printf '### FR-BOGUS-999 — no metadata block\n' >> specs/10-fr-chk.md
python3 - <<'PY2'
text = open('CHANGELOG.md', encoding='utf-8').read()
import re
anchor = re.search(r'^## \[', text, re.M).start()
open('CHANGELOG.md', 'w', encoding='utf-8').write(
    text[:anchor] + '## [9.9.10]\n\n### Added\n\n- Another one.\n\n'
    + text[anchor:])
PY2
rc=0; python3 tools/srs_release.py 9.9.10 > /tmp/rel-bad.log 2>&1 || rc=$?
test "$rc" -eq 2
grep -q "checker does not pass" /tmp/rel-bad.log
absent '## \[9.9.10\] —' CHANGELOG.md
grep -q '__version__ = "9.9.9"' tools/srs_parse.py
