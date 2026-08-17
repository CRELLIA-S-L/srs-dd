#!/usr/bin/env bash
# The specification gate: the checker passes strictly, and the committed
# traceability matrix matches what the checker would generate now.
#
# verifies: FR-CI-010, FR-CHK-120, IF-CI-020, CON-SPEC-010
#
# Two lines answer for four requirements, and it is worth saying what each
# of them gets: the strict run proves the gate exists and that a clean
# specification exits 0; the byte comparison proves the matrix is generated
# and stale output fails the build. The other exit codes, and the refusals
# that happen before a specification is read, are checker-rules' business.
set -eo pipefail
cd "$(dirname "$0")/.."

python3 tools/srs_check.py --strict

git add -N specs/90-traceability.md
git diff --exit-code -- specs/90-traceability.md || {
    echo "specs/90-traceability.md is stale — run python3 tools/srs_check.py and commit the result"
    exit 1
}
