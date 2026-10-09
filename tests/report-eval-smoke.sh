#!/usr/bin/env bash
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# The report measurement, run over canned verdicts: the arithmetic, the shape the
# judge is held to, and the refusal where there is no agent to ask.
#
# file verifies: FR-SKILL-580
#
# What is canned here is the judge's answer, not the report: this suite holds the
# parsing and the totals, which are the parts that can break in silence. Whether
# the judge judges well is the measurement itself and is not a suite.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

CANNED=/tmp/srs-report-eval.jsonl
python3 - > "$CANNED" <<'PY'
import json
rows = [
    {"task": "one", "report": "x", "verdict": "figure: 2\nuseless: 1\nunbacked: 0\nwhere:\n- the second paragraph\n- the closing line"},
    {"task": "two", "report": "y", "verdict": "figure: 0\nuseless: 0\nunbacked: 1\nwhere: the count in the first line"},
    {"task": "three", "report": "z", "verdict": "figure: 0\nuseless: 0\nunbacked: 0\nwhere: none"},
    {"task": "four", "report": "w", "verdict": "The report looks fine to me."},
]
for row in rows:
    print(json.dumps(row))
PY
rc=0
python3 tools/srs_report_eval.py --score "$CANNED" > /tmp/srs-report-eval.out || rc=$?
grep -q "^Reports judged: 3. figure 2, useless 1, unbacked 1. 1 verdict(s) unreadable" /tmp/srs-report-eval.out \
    || { echo "report-eval: the totals are not 2 figure, 1 useless, 1 unbacked over three readable verdicts"
         cat /tmp/srs-report-eval.out; exit 1; }
[ "$rc" = 1 ] || { echo "report-eval: an unreadable verdict exited $rc, expected 1"; exit 1; }
grep -q "the judge did not answer in the shape asked for" /tmp/srs-report-eval.out \
    || { echo "report-eval: the unreadable verdict was not named as such"; cat /tmp/srs-report-eval.out; exit 1; }
grep -q "the second paragraph" /tmp/srs-report-eval.out \
    || { echo "report-eval: the places the judge named are not printed"; cat /tmp/srs-report-eval.out; exit 1; }
echo "report-eval: canned verdicts total as they say, and one that cannot be read is not a zero"

# --- A run of nothing is not a clean run: zero reports is not zero faults.
printf '' > /tmp/srs-report-empty.jsonl
python3 tools/srs_report_eval.py --score /tmp/srs-report-empty.jsonl > /tmp/srs-report-eval-empty.out
grep -q "^Reports judged: 0." /tmp/srs-report-eval-empty.out \
    || { echo "report-eval: an empty run does not say it judged nothing"; cat /tmp/srs-report-eval-empty.out; exit 1; }
echo "report-eval: an empty run says it judged nothing"

# --- Where no agent client is on the path the command says so and exits 2.
rc=0
PATH=/usr/bin:/bin python3 tools/srs_report_eval.py > /tmp/srs-report-none.out 2>&1 || rc=$?
[ "$rc" = 2 ] || { echo "report-eval: without claude the command exited $rc, expected 2"; cat /tmp/srs-report-none.out; exit 1; }
grep -q "no \`claude\` on the path" /tmp/srs-report-none.out \
    || { echo "report-eval: the command did not say why it did not run"; cat /tmp/srs-report-none.out; exit 1; }
echo "report-eval: with no agent to ask the command refuses and says so"
