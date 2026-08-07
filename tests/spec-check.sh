#!/usr/bin/env bash
# The specification gate: the checker passes strictly, and the committed
# traceability matrix matches what the checker would generate now.
set -eo pipefail
cd "$(dirname "$0")/.."

python3 tools/srs_check.py --strict

git add -N specs/90-traceability.md
git diff --exit-code -- specs/90-traceability.md || {
    echo "specs/90-traceability.md is stale — run python3 tools/srs_check.py and commit the result"
    exit 1
}
