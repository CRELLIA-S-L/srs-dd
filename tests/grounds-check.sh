#!/usr/bin/env bash
# The gate for this repository's own register: it passes its checker
# strictly, and the committed dashboard is what the records say now.
#
# verifies: FR-GND-010, FR-GND-120, FR-GND-370, CON-GND-020, CON-GND-030
#
# The comparison is done without `git add`. tools/ci_selftest.sh exempts
# exactly one suite from its index check and that exemption belongs to
# spec-check; a second one would make the leak it guards against
# unobservable. So the dashboard is regenerated into a copy and compared
# with cmp, and the working tree is left as it was found.
set -eo pipefail

unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."
. tools/test_lib.sh

[ -d grounds ] || { echo "grounds-check: no register in this repository"; exit 1; }

python3 tools/srs_grounds.py --no-write --strict

# The committed dashboard against a fresh one. The copy is a tree of its
# own so that a difference cannot be created by the act of looking.
LAB=/tmp/srs-grounds-check
rm -rf "$LAB"; mkdir -p "$LAB"
tar --exclude ./.git --exclude ./.srs-site --exclude ./public \
    --exclude ./__pycache__ -cf - . | tar -xf - -C "$LAB"
( cd "$LAB" && python3 tools/srs_grounds.py > /tmp/grounds-check.log 2>&1 ) || {
    echo "grounds-check: the copy does not pass its own checker:"
    cat /tmp/grounds-check.log; exit 1; }

if [ -f grounds/90-dashboard.md ]; then
    cmp -s grounds/90-dashboard.md "$LAB/grounds/90-dashboard.md" || {
        echo "grounds-check: grounds/90-dashboard.md is stale — run"
        echo "python3 tools/srs_grounds.py and commit the result"
        diff grounds/90-dashboard.md "$LAB/grounds/90-dashboard.md" | head -20
        exit 1; }
else
    echo "grounds-check: no dashboard is committed, and one is generated"
    exit 1
fi

# The records themselves are authored and the checker may not touch them:
# a run rewrites the dashboard and nothing else in the register.
for f in grounds/*.md grounds/*.json; do
    [ "$f" = "grounds/90-dashboard.md" ] && continue
    cmp -s "$f" "$LAB/$f" || {
        echo "grounds-check: a checker run modified $f, and records are"
        echo "authored, never written"
        exit 1; }
done

echo "grounds-check: the register passes strictly, the dashboard is fresh"
