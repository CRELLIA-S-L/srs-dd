#!/usr/bin/env bash
# Adopt mode: a project that already has an SRS-shaped specification, in a
# language the tooling has never seen. The invariant under test is that a
# failed adoption leaves the target byte-identical.
set -eo pipefail
cd "$(dirname "$0")/.."

LEXICON=(--modal-verbs "должен,должна,должно,должны,следует,может,могут"
         --negation-words "не"
         --rationale-markers "Обоснование")

rm -rf /tmp/srs-adopt /tmp/srs-docs

# Fabricate a minimal existing Russian SRS.
mkdir -p /tmp/srs-adopt/specs
printf '### FR-APP-010 — Тестовое требование\n\n```yaml\nstatus: deferred\nverification: T\n```\n\nСистема **должна** сохранять файл.\n' > /tmp/srs-adopt/specs/10-fr-app.md
find /tmp/srs-adopt -type f | sort | xargs cksum > /tmp/before.sum

# Adopt under --dry-run lists the install and leaves the tree alone.
python3 tools/srs_init.py /tmp/srs-adopt --defaults --dry-run --areas "APP" \
    "${LEXICON[@]}" > /tmp/adopt-dry.log
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
    "${LEXICON[@]}" | tee /tmp/adopt-real.log

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

# The viewer reads a Russian specification without a UTF-8 locale.
(cd /tmp/srs-adopt && LC_ALL=C python3 tools/srs_view.py --list | cat)

# specs/ with markdown but no requirements must refuse, not go fresh.
mkdir -p /tmp/srs-docs/specs
echo "just docs" > /tmp/srs-docs/specs/notes.md
rc=0; python3 tools/srs_init.py /tmp/srs-docs --defaults || rc=$?
test "$rc" -eq 2
test ! -e /tmp/srs-docs/specs/srs-config.json
