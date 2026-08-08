#!/usr/bin/env bash
# tools/srs_release.py, exercised in a throwaway clone of this repository:
# it commits and tags, and a test that does that to the working copy would
# be a test nobody dares run twice.
set -eo pipefail
cd "$(dirname "$0")/.."

FRAMEWORK=$(pwd)
rm -rf /tmp/srs-rel
git clone --quiet . /tmp/srs-rel
cd /tmp/srs-rel
git config user.email ci@example.com
git config user.name CI

# A clone carries what is committed; what is under test is the working
# tree. Bring it in and commit it, so the tree the command inspects is
# clean and the command itself is the current one.
cp "$FRAMEWORK/tools/srs_release.py" "$FRAMEWORK/tools/srs_view.py" \
   "$FRAMEWORK/tools/srs_check.py" tools/
# The baseline log too: the command refuses while the checker complains,
# and a clone taken mid-release inherits exactly that complaint.
cp "$FRAMEWORK/specs/92-baselines.md" specs/
# And regenerate the matrix: the copied files are new to this clone's
# specification, and the command refuses on a matrix that is not fresh.
python3 tools/srs_check.py >/dev/null
git add -A
git commit -qm "the working tree's tooling"

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

# A dirty tree is refused: a half-cut release is worse than an uncut one.
rc=0; python3 tools/srs_release.py 9.9.9 > /tmp/rel-dirty.log 2>&1 || rc=$?
test "$rc" -eq 2
grep -q "working tree is not clean" /tmp/rel-dirty.log

git add -A
git commit -qm "release notes for 9.9.9"
clean=$(git rev-parse HEAD)

# --dry-run says what it would do and writes nothing at all.
python3 tools/srs_release.py 9.9.9 --dry-run --date 2026-01-02 > /tmp/rel-dry.log
grep -q "Dry run: nothing was written" /tmp/rel-dry.log
grep -q "spec/v9.9.9" /tmp/rel-dry.log
test "$(git rev-parse HEAD)" = "$clean"
test -z "$(git status --porcelain)"

# The real run: one commit, two tags, and the row before the tag.
python3 tools/srs_release.py 9.9.9 --date 2026-01-02 > /tmp/rel-run.log
test "$(git rev-parse HEAD)" != "$clean"
test -z "$(git status --porcelain)"
grep -q '__version__ = "9.9.9"' tools/srs_check.py
grep -q '## \[9.9.9\] — 2026-01-02' CHANGELOG.md
grep -q '`spec/v9.9.9`' specs/92-baselines.md
test "$(git rev-list -1 v9.9.9)" = "$(git rev-parse HEAD)"
test "$(git rev-list -1 spec/v9.9.9)" = "$(git rev-parse HEAD)"

# The tag lands on a commit that already describes itself: the row is
# there at the tagged revision, so the checker finds nothing to warn about.
git show spec/v9.9.9:specs/92-baselines.md | grep -q '`spec/v9.9.9`'
python3 tools/srs_check.py --strict --no-write >/dev/null

# Cutting the same release twice is refused.
rc=0; python3 tools/srs_release.py 9.9.9 > /tmp/rel-twice.log 2>&1 || rc=$?
test "$rc" -eq 2
grep -q "already exists" /tmp/rel-twice.log

# A commit can fail on somebody's hook, and by then the files are written.
# That path has to say what it left behind, not raise a traceback over it.
python3 - <<'PY2'
text = open('CHANGELOG.md', encoding='utf-8').read()
import re
anchor = re.search(r'^## \[', text, re.M).start()
open('CHANGELOG.md', 'w', encoding='utf-8').write(
    text[:anchor] + '## [9.9.10]\n\n### Added\n\n- Another one.\n\n'
    + text[anchor:])
PY2
git add -A
git commit -qm "release notes for 9.9.10"
# Inside .git/, so the hook itself does not make the tree dirty and trip
# the earlier check instead of the one under test.
printf '#!/bin/sh\nexit 1\n' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

rc=0; python3 tools/srs_release.py 9.9.10 > /tmp/rel-hook.log 2>&1 || rc=$?
test "$rc" -eq 2
grep -q "the commit failed" /tmp/rel-hook.log
grep -q "git checkout --" /tmp/rel-hook.log
# The advice must be true: the edits are there to undo, and no tag was made.
test -n "$(git status --porcelain)"
test -z "$(git tag -l v9.9.10)"
rm -f .git/hooks/pre-commit
git checkout -- CHANGELOG.md tools/srs_check.py specs/92-baselines.md \
    specs/90-traceability.md
