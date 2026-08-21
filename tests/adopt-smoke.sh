#!/usr/bin/env bash
# Adopt mode: a project that already has an SRS-shaped specification, in a
# language the tooling has never seen. The invariant under test is that a
# failed adoption leaves the target byte-identical.
#
# verifies: FR-INIT-010, FR-INIT-030, FR-INIT-040, FR-INIT-050
# verifies: FR-INIT-070, FR-INIT-090, FR-CHK-090, FR-CHK-210, IF-CI-010
# verifies: FR-GND-480
#
# One scenario answers for all of them, which is what an end-to-end suite
# is: the mode is detected, the lexicon comes from the flags, a wrong one
# rolls back with its own exit code, the dry run matches the real one, and
# the target that arrives with code already written starts with the
# unclaimed-file rule silenced.
set -eo pipefail

# implements: FR-CI-090
# A hook runs with GIT_INDEX_FILE and GIT_DIR pointing at the commit being
# prepared, and everything this suite starts inherits them — so a `git add`
# meant for the throwaway target below would write that target's paths into
# the commit in progress (FR-CI-090). Cleared here, once, before anything.
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

LEXICON=(--modal-verbs "должен,должна,должно,должны,следует,может,могут"
         --negation-words "не"
         --rationale-markers "Обоснование")

rm -rf /tmp/srs-adopt /tmp/srs-docs

# Fabricate a minimal existing Russian SRS. Two requirements, linked: one
# on its own is isolated by definition, and the `unlinked` rule would then
# be reporting the fixture rather than anything about adoption.
mkdir -p /tmp/srs-adopt/specs
printf '### FR-APP-010 — Тестовое требование\n\n```yaml\nstatus: deferred\nverification: T\ndepends_on: [FR-APP-020]\n```\n\nСистема **должна** сохранять файл.\n\n### FR-APP-020 — Второе требование\n\n```yaml\nstatus: deferred\nverification: T\n```\n\nСистема **должна** открывать файл.\n' > /tmp/srs-adopt/specs/10-fr-app.md
find /tmp/srs-adopt -type f | sort | xargs cksum > /tmp/before.sum

# Adopt under --dry-run lists the install and leaves the tree alone.
python3 tools/srs_init.py /tmp/srs-adopt --defaults --dry-run --areas "APP" \
    --grounds yes --period year "${LEXICON[@]}" > /tmp/adopt-dry.log
grep -q "specs/srs-config.json" /tmp/adopt-dry.log
find /tmp/srs-adopt -type f | sort | xargs cksum > /tmp/after.dry.sum
diff /tmp/before.sum /tmp/after.dry.sum
test ! -e /tmp/srs-adopt/specs/srs-config.json

# Wrong lexicon (English defaults vs a Russian spec) must roll back:
# exit 3, tree unchanged. The `|| rc=$?` capture keeps set -e from
# aborting on the expected failure.
rc=0; python3 tools/srs_init.py /tmp/srs-adopt --defaults || rc=$?
test "$rc" -eq 3
find /tmp/srs-adopt -type f | sort | xargs cksum > /tmp/after.sum
diff /tmp/before.sum /tmp/after.sum
test ! -e /tmp/srs-adopt/specs/srs-config.json
test ! -e /tmp/srs-adopt/tools/.srs_check_adopt.py

# Correct lexicon adopts cleanly; skills land, matrix generated.
python3 tools/srs_init.py /tmp/srs-adopt --defaults --areas "APP" \
    --grounds yes --period year "${LEXICON[@]}" | tee /tmp/adopt-real.log

# verifies: FR-GND-480 — the adoption path takes the answer too, and the
# comparison below is what proves the dry run listed the file it writes.
grep -qF '"period": "year"' /tmp/srs-adopt/grounds/grounds-config.json \
    || { echo "FAIL FR-GND-480 — adoption did not carry the chosen period"
         cat /tmp/srs-adopt/grounds/grounds-config.json; exit 1; }

# Adopt is the one mode where --dry-run takes a separate branch, so the
# two lists are compared entry by entry: a file added to the real path and
# forgotten in the dry-run one would be a silent lie.
python3 - <<'PY'
def entries(path):
    out, section = [], None
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        head = line.split(':')[0]
        if line.endswith(':') and head in ('created', 'refreshed', 'skipped'):
            section = head
        elif section and line.startswith('  ') and line.strip():
            out.append(section + ' ' + line.strip())
        elif section and not line.startswith('  '):
            section = None
    return sorted(out)

dry, real = entries('/tmp/adopt-dry.log'), entries('/tmp/adopt-real.log')
assert dry and dry == real, (
    'dry-run list differs from the real run',
    [x for x in dry if x not in real], [x for x in real if x not in dry])
print('adopt --dry-run matches the real run: %d entries' % len(dry))
PY

test -f /tmp/srs-adopt/specs/90-traceability.md
test -f /tmp/srs-adopt/.claude/skills/srs-harvest/SKILL.md
grep -q "Planning multi-requirement work" /tmp/srs-adopt/.claude/skills/srs/SKILL.md
test -f /tmp/srs-adopt/tools/srs_view.py
python3 /tmp/srs-adopt/tools/srs_check.py --strict --no-write

# Adoption starts with the unclaimed-file rule silenced (FR-CHK-210): a
# project arriving with code already written has files under its roots that
# no requirement names yet, and reporting all of them on the first run is a
# wall rather than a queue. A fresh install has nothing to silence and gets
# no such line — checked from both ends, because a default written for
# everybody would be the opposite decision quietly taken.
python3 - <<'PY'
import json
adopted = json.load(open('/tmp/srs-adopt/specs/srs-config.json',
                         encoding='utf-8'))
assert adopted.get('rules', {}).get('annotation-absent') == 'off', \
    'adoption did not silence the unclaimed-file rule: %r' % adopted.get('rules')
PY

# The viewer reads a Russian specification without a UTF-8 locale.
(cd /tmp/srs-adopt && LC_ALL=C python3 tools/srs_view.py --list | cat)

# specs/ with markdown but no requirements must refuse, not go fresh.
mkdir -p /tmp/srs-docs/specs
echo "just docs" > /tmp/srs-docs/specs/notes.md
rc=0; python3 tools/srs_init.py /tmp/srs-docs --defaults || rc=$?
test "$rc" -eq 2
test ! -e /tmp/srs-docs/specs/srs-config.json
