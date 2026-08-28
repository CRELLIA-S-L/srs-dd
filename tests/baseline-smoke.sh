#!/usr/bin/env bash
# tools/srs_baseline.py — the command that freezes a specification. It
# writes a row and nothing else: the history belongs to whatever git client
# the project is driven by (CON-SPEC-030). It ships, so the first thing
# checked is that it works in a project that adopted the framework.
#
# verifies: FR-SPEC-010, FR-VIEW-120, INV-SPEC-030, INV-SPEC-040
# verifies: CON-SPEC-030
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

# --- In a fresh target, because this tool travels there.
rm -rf /tmp/srs-base-target
python3 tools/srs_init.py /tmp/srs-base-target --defaults --ci none >/dev/null
cd /tmp/srs-base-target
test -f tools/srs_baseline.py
git init -q .
git config user.email ci@example.com
git config user.name CI
git add -A
git commit -qm "the project as installed"
head=$(git rev-parse HEAD)

python3 tools/srs_baseline.py 1.0.0 --date 2026-01-02 > /tmp/base-first.log
grep -q '`spec/v1.0.0`' specs/92-baselines.md
grep -q 'The first baseline' specs/92-baselines.md
# The placeholder the skeleton carries until there is a row to replace it.
absent 'No baselines yet' specs/92-baselines.md
# Nothing of git was touched: no commit, no tag, and it says what to commit.
test "$(git rev-parse HEAD)" = "$head"
test -z "$(git tag -l)"
grep -q 'Commit specs/92-baselines.md' /tmp/base-first.log

# Committed with an ordinary client, the baseline is real: the row is in
# history and the page finds the revision it froze without any tag.
git add -A
git commit -qm "baseline 1.0.0"
frozen=$(git rev-parse HEAD)
test "$(python3 -c "
import sys; sys.dont_write_bytecode = True; sys.path.insert(0, 'tools')
import srs_view
print(srs_view.baseline_revision('1.0.0'))")" = "$frozen"
python3 tools/srs_view.py --html /tmp/srs-base-target/.srs-site/index.html \
    >/dev/null
grep -q '1.0.0' /tmp/srs-base-target/.srs-site/index.html
python3 tools/srs_check.py --strict --no-write >/dev/null

# A row typed by hand, spaced however the typist felt: it is a baseline
# like any other, and it is located by the commit that added it.
printf '%s\n' '|2.0.0|2026-01-03|spec/v2.0.0|Typed by hand.|' \
    >> specs/92-baselines.md
git add -A
git commit -qm "a hand-written baseline row"
byhand=$(git rev-parse HEAD)
test "$(python3 -c "
import sys; sys.dont_write_bytecode = True; sys.path.insert(0, 'tools')
import srs_view
print(srs_view.baseline_revision('2.0.0'))")" = "$byhand"

# Asked again for a baseline the log already records: refused, nothing done.
rc=0; python3 tools/srs_baseline.py 1.0.0 > /tmp/base-again.log 2>&1 || rc=$?
test "$rc" -eq 2
grep -q "already in specs/92-baselines.md" /tmp/base-again.log
test -z "$(git status --porcelain)"

# History that was squashed, or imported from another forge, is one commit
# holding every row at once. Only the newest of them describes the tree
# that commit left behind; claiming the rest would report a specification
# that never changed.
rm -rf /tmp/srs-base-squashed
git clone --quiet "file:///tmp/srs-base-target" /tmp/srs-base-squashed
(
  cd /tmp/srs-base-squashed
  git config user.email ci@example.com
  git config user.name CI
  git checkout -q --orphan imported
  git add -A
  git commit -qm "imported from elsewhere"
  python3 - <<'PY1'
import subprocess, sys
sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import srs_view
head = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip()
assert srs_view.logged_baselines() == ['1.0.0', '2.0.0'], 'the log still reads'
assert srs_view.baseline_revision('2.0.0') == head, 'the newest is that tree'
assert srs_view.baseline_revision('1.0.0') is None, \
    'the state 1.0.0 froze is not in this repository, and must not be faked'
PY1
)

# --- In a clone of this repository, where there is history to read.
cd "$FRAMEWORK"
rm -rf /tmp/srs-base
git clone --quiet . /tmp/srs-base
cd /tmp/srs-base
git config user.email ci@example.com
git config user.name CI

# A clone carries what is committed; what is under test is the working
# tree — all of it, not a chosen few files. The specification names skills
# and templates as well as tools, so a partial copy is a pair that never
# existed and fails for a reason that has nothing to do with baselines.
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
python3 tools/srs_check.py > /tmp/base-precheck.log 2>&1 || {
    echo "the clone does not pass its own checker:"; cat /tmp/base-precheck.log
    exit 1
}
git add -A
git diff --cached --quiet || git commit -qm "the working tree's tooling"
clean=$(git rev-parse HEAD)

# --dry-run prints the row and writes nothing at all.
python3 tools/srs_baseline.py 9.9.9 --dry-run --date 2026-01-02 \
    > /tmp/base-dry.log
grep -q "Dry run: nothing was written" /tmp/base-dry.log
grep -q 'spec/v9.9.9' /tmp/base-dry.log
test -z "$(git status --porcelain)"

# The real run writes one file and leaves the history alone.
python3 tools/srs_baseline.py 9.9.9 --date 2026-01-02 > /tmp/base-run.log
test "$(git rev-parse HEAD)" = "$clean"
test -z "$(git tag -l 'spec/v9.9.9')"
grep -q '`spec/v9.9.9`' specs/92-baselines.md
git checkout -- specs/92-baselines.md

# A tag somebody made by hand is described from the tagged revision, not
# from a working tree that has moved on since. This is what makes tagging
# first — the only order some git clients make easy — cost nothing.
git tag spec/v9.9.10
handmade=$(git rev-parse HEAD)
cat >> specs/10-fr-chk.md <<'REQ'

### FR-CHK-990 — Written after the tag was made

```yaml
status: deferred
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
```

The checker **shall** exist, which is all this fixture needs of it.
REQ
python3 tools/srs_baseline.py 9.9.10 > /tmp/base-hand.log
grep -q '`spec/v9.9.10`' specs/92-baselines.md
test "$(git rev-list -1 spec/v9.9.10)" = "$handmade"
# The row read the tag: what the tree gained afterwards is not in it.
absent 'FR-CHK-990' specs/92-baselines.md
git checkout -- specs/92-baselines.md specs/10-fr-chk.md \
    specs/90-traceability.md

# A failing checker stops it before the log is touched.
printf '### FR-BOGUS-999 — no metadata block\n' >> specs/10-fr-chk.md
rc=0; python3 tools/srs_baseline.py 9.9.11 > /tmp/base-bad.log 2>&1 || rc=$?
test "$rc" -eq 2
grep -q "checker does not pass" /tmp/base-bad.log
absent '`spec/v9.9.11`' specs/92-baselines.md
git checkout -- specs/10-fr-chk.md specs/90-traceability.md

# A warning is not a refusal, and this is the only place that says so. The
# statement asks the command to stop on an error; the release command stops
# on a warning too (FR-CI-070), and for years both sentences read the same
# while the two commands did not. A project part-way through describing
# itself carries warnings, and a baseline is the record of where it stands.
cat >> specs/10-fr-chk.md <<'REQ'

### FR-CHK-991 — A draft that already has code

```yaml
status: draft
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

The checker **shall** be pointed at by a requirement nobody has approved.
REQ
# Warnings, and no error: the case the two commands answer differently.
python3 tools/srs_check.py --no-write > /tmp/base-warn-check.log 2>&1
grep -q "is draft but the code field is not empty" /tmp/base-warn-check.log
grep -q "No errors" /tmp/base-warn-check.log
python3 tools/srs_baseline.py 9.9.12 --date 2026-01-04 > /tmp/base-warn.log
grep -q '`spec/v9.9.12`' specs/92-baselines.md
git checkout -- specs/92-baselines.md specs/10-fr-chk.md \
    specs/90-traceability.md
