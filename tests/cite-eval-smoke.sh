#!/usr/bin/env bash
# tools/srs_cite_eval.py scores canned answers exactly, and refuses to run
# where there is no agent to ask. The test asks nobody: the live run is a
# measurement for the register, not a suite.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# verifies: FR-SKILL-290
# Three answers: a full citation and a bare key beside it; a register record
# and a decision cited, a bet bare; a citation whose status is not what the
# project prints. The tool must count exactly that, from what --cite prints.
CANNED=/tmp/srs-cite-eval.jsonl
python3 - > "$CANNED" <<'PY'
import json, subprocess
def cite(tool, rid):
    return subprocess.check_output(["python3", "tools/" + tool, "--cite", rid], text=True).strip()
rows = [
    {"question": "one", "answer": "Governed by %s; later FR-VIEW-240 again is fine. Also %s, while FR-CHK-010 is bare."
                                   % (cite("srs_view.py", "FR-VIEW-240"), cite("srs_arch.py", "E-020"))},
    {"question": "two", "answer": "%s and B-010 bare, then %s." % (cite("srs_grounds.py", "H-030"), cite("srs_view.py", "ADR-0027"))},
    {"question": "three", "answer": cite("srs_view.py", "FR-VIEW-240").replace("implemented", "deferred") + " has a status that moved."},
    {"question": "four", "answer": "**" + cite("srs_view.py", "FR-VIEW-330").replace(" (specs/", "** (`specs/").replace(", implemented)", "`, implemented, created today)") + " is right in substance and retyped."},
    {"question": "five", "answer": "The whole family, `FR-DOC-010` through `FR-DOC-210` and `B-010`–`B-210`, plus CON-GND-010…030, is a set and not a mention; but %s is singled out." % cite("srs_view.py", "FR-DOC-140")},
    {"question": "six", "answer": "First as a span end, FR-DOC-020 through FR-DOC-060, and later on its own: %s." % cite("srs_view.py", "FR-DOC-020")},
]
for row in rows:
    print(json.dumps(row))
PY
python3 tools/srs_cite_eval.py --score "$CANNED" > /tmp/srs-cite-eval.out
grep -q "^Records named: 10 — cited as printed 6 (60%), retyped 1 (10%), bare 3 (30%)" /tmp/srs-cite-eval.out \
    || { echo "cite-eval: the score is not 6 cited, 1 retyped, 3 bare of 10 — a span end counted as a mention, or a record scored at its span rather than where it stands alone?"; cat /tmp/srs-cite-eval.out; exit 1; }
grep -q "bare: FR-CHK-010" /tmp/srs-cite-eval.out && grep -q "bare: B-010" /tmp/srs-cite-eval.out \
    && grep -q "bare: FR-VIEW-240" /tmp/srs-cite-eval.out && grep -q "retyped: FR-VIEW-330" /tmp/srs-cite-eval.out \
    || { echo "cite-eval: the bare and retyped records are not the ones expected"; cat /tmp/srs-cite-eval.out; exit 1; }
echo "cite-eval: canned answers score exactly as the tools' citations say"

# --- Where no agent client is on the path the command says so and exits 2,
# --- rather than reporting a measurement nobody took.
rc=0
PATH=/usr/bin:/bin python3 tools/srs_cite_eval.py > /tmp/srs-cite-eval-none.out 2>&1 || rc=$?
[ "$rc" = 2 ] || { echo "cite-eval: without claude the command exited $rc, expected 2"; cat /tmp/srs-cite-eval-none.out; exit 1; }
grep -q "no \`claude\` on the path" /tmp/srs-cite-eval-none.out \
    || { echo "cite-eval: the command did not say why it did not run"; cat /tmp/srs-cite-eval-none.out; exit 1; }
echo "cite-eval: with no agent to ask the command refuses and says so"
