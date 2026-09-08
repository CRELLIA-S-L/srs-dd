#!/usr/bin/env bash
# The gate for this repository's own architecture layer: it passes its
# checker strictly, and the committed map is what the elements say now.
#
# verifies: FR-ARCH-010, FR-ARCH-100, FR-ARCH-110, FR-ARCH-170, CON-ARCH-020
#
# The comparison is done without `git add`, for the reason grounds-check
# gives: tools/ci_selftest.sh exempts exactly one suite from its index
# check and that exemption belongs to spec-check.
set -eo pipefail

# implements: FR-CI-090
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."
. tools/test_lib.sh

[ -d arch ] || { echo "arch-check: no architecture layer in this repository"; exit 1; }

python3 tools/srs_arch.py --no-write --strict

LAB=/tmp/srs-arch-check
rm -rf "$LAB"; mkdir -p "$LAB"
tar --exclude ./.git --exclude ./.srs-site --exclude ./public \
    --exclude ./__pycache__ -cf - . | tar -xf - -C "$LAB"
( cd "$LAB" && python3 tools/srs_arch.py > /tmp/arch-check.log 2>&1 ) || {
    echo "arch-check: the copy does not pass its own checker:"
    cat /tmp/arch-check.log; exit 1; }

if [ -f arch/90-map.md ]; then
    cmp -s arch/90-map.md "$LAB/arch/90-map.md" || {
        echo "arch-check: arch/90-map.md is stale — run"
        echo "python3 tools/srs_arch.py and commit the result"
        diff arch/90-map.md "$LAB/arch/90-map.md" | head -20
        exit 1; }
else
    echo "arch-check: no map is committed, and one is generated"
    exit 1
fi

# The elements are authored and the checker may not touch them: a run
# rewrites the map and nothing else in the layer.
for f in arch/*.md arch/*.json; do
    [ "$f" = "arch/90-map.md" ] && continue
    cmp -s "$f" "$LAB/$f" || {
        echo "arch-check: a checker run modified $f, and elements are"
        echo "authored, never written"
        exit 1; }
done

echo "arch-check: the layer passes strictly, the map is fresh"
