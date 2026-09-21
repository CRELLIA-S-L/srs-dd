#!/usr/bin/env bash
# Adopt mode: a project that already has an SRS-shaped specification, in a
# language the tooling has never seen. The invariant under test is that a
# failed adoption leaves the target byte-identical.
#
# verifies: FR-INIT-010, FR-INIT-030, FR-INIT-040, FR-INIT-050
# verifies: FR-INIT-070, FR-INIT-090, FR-CHK-090, FR-CHK-210, IF-CI-010
# verifies: FR-GND-480, FR-INIT-230
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
mkdir -p /tmp/srs-adopt/specs/10-fr-app
printf '### FR-APP-010 — Тестовое требование\n\n```yaml\nstatus: deferred\nverification: T\ndepends_on: [FR-APP-020]\n```\n\nСистема **должна** сохранять файл.\n\n### FR-APP-020 — Второе требование\n\n```yaml\nstatus: deferred\nverification: T\n```\n\nСистема **должна** открывать файл.\n' > /tmp/srs-adopt/specs/10-fr-app/000-999.md
# verifies: INV-SPEC-080, FR-CHK-250
# The area is a directory, and its second file carries a four-digit number in
# the file of its thousand: adoption reads both files as the area, counts the
# wide number as a requirement, and nothing on the way in narrows it to three
# digits or reads the directory's README as requirements.
printf '### FR-APP-1000 — Тысячное\n\n```yaml\nstatus: deferred\nverification: T\ndepends_on: [FR-APP-020]\n```\n\nСистема **должна** продолжать.\n' > /tmp/srs-adopt/specs/10-fr-app/1000-1999.md
printf '# Об этой папке\n\nДля людей.\n' > /tmp/srs-adopt/specs/10-fr-app/README.md
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

# verifies: FR-INIT-230 — a project with no standard of its own has nothing
# to set aside: no archive appears and the summary has no such heading.
test ! -e /tmp/srs-adopt/specs/archive
if grep -q "set aside" /tmp/adopt-real.log; then
    echo "FAIL FR-INIT-230 — adopt set aside a standard the project never had"; exit 1
fi

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

# verifies: FR-INIT-220
# Adopt writes the agent guide too, and builds its substitutions on a path
# of its own — which is how the width marker once travelled into a target
# as itself. No width was passed here, so the line goes rather than filling.
grep -q 'SRS-DD-WIDTH-LINE' /tmp/srs-adopt/AGENTS.md \
    && { echo "FAIL FR-INIT-220 — the width placeholder travelled"; exit 1; }
grep -q 'Line width' /tmp/srs-adopt/AGENTS.md \
    && { echo "FAIL FR-INIT-220 — a width nobody stated was named"; exit 1; }

# verifies: FR-INIT-180, FR-INIT-190
# Adopt writes the checker itself — it has to run it before any tooling is
# installed — so it is the one path into a target that does not go through
# the copier. It shipped 26 of this framework's annotations and an
# unreplaced version token until this assertion existed.
python3 - <<'PY2'
import json
import re
areas = json.load(open('specs/srs-config.json', encoding='utf-8'))['areas']
RE = re.compile(r'(?:implements|verifies):\s*(?:FR|NFR|IF|INV|CON)-(?:%s)-'
                % '|'.join(areas))
text = open('/tmp/srs-adopt/tools/srs_check.py', encoding='utf-8').read()
leaked = [line for line in text.split(chr(10))
          if RE.search(line) and 'srs-ignore' not in line]
assert not leaked, 'adopt shipped our annotations: %s' % leaked[:3]
assert re.search(r'SRS-DD-\d+\.\d+\.\d+', text.split('\"\"\"')[0]), \
    'adopt shipped a checker with no version stamp'
PY2

# The viewer reads a Russian specification without a UTF-8 locale.
(cd /tmp/srs-adopt && LC_ALL=C python3 tools/srs_view.py --list | cat)

# specs/ with markdown but no requirements must refuse, not go fresh.
mkdir -p /tmp/srs-docs/specs
echo "just docs" > /tmp/srs-docs/specs/notes.md
rc=0; python3 tools/srs_init.py /tmp/srs-docs --defaults || rc=$?
test "$rc" -eq 2
test ! -e /tmp/srs-docs/specs/srs-config.json

# verifies: FR-INIT-230
# A project with a standard of its own. Adopt sets it aside in the archive
# byte for byte, installs ours in its place with the marker, names both
# paths, and touches no other README; the dry run lists the move without
# making it; a file already at the archive path stops the run before
# anything is written; and the target's checker never reads the archive.
OWN=/tmp/srs-adopt-own
rm -rf "$OWN"; mkdir -p "$OWN/specs"
cp -r /tmp/srs-adopt/specs/10-fr-app "$OWN/specs/"
printf '# Как мы пишем требования\n\nЭтот файл главный: если что-то ему противоречит, прав он.\nОтменённые требования удаляются.\n' > "$OWN/specs/README.md"
cp "$OWN/specs/README.md" /tmp/own-readme.orig
find "$OWN" -type f | sort | xargs cksum > /tmp/own-before.sum

python3 tools/srs_init.py "$OWN" --defaults --dry-run --areas "APP" "${LEXICON[@]}" > /tmp/own-dry.log
grep -qF "specs/README.md -> specs/archive/README-before-srs-dd.md" /tmp/own-dry.log \
    || { echo "FAIL FR-INIT-230 — the dry run does not list the standard being set aside"; cat /tmp/own-dry.log; exit 1; }
grep -qF "  specs/README.md" /tmp/own-dry.log \
    || { echo "FAIL FR-INIT-230 — the dry run does not list the standard being installed"; cat /tmp/own-dry.log; exit 1; }
if grep -q "never overwritten" /tmp/own-dry.log; then
    echo "FAIL FR-INIT-230 — the dry run classified the vacated path as specification content"; cat /tmp/own-dry.log; exit 1
fi
find "$OWN" -type f | sort | xargs cksum > /tmp/own-after.sum
diff /tmp/own-before.sum /tmp/own-after.sum

mkdir -p "$OWN/specs/archive"
printf 'not ours\n' > "$OWN/specs/archive/README-before-srs-dd.md"
find "$OWN" -type f | sort | xargs cksum > /tmp/own-before.sum
rc=0; python3 tools/srs_init.py "$OWN" --defaults --areas "APP" "${LEXICON[@]}" > /tmp/own-stale.log || rc=$?
test "$rc" -eq 3 || { echo "FAIL FR-INIT-230 — a stale archive did not stop adopt with exit 3 (got $rc)"; cat /tmp/own-stale.log; exit 1; }
grep -q "already exists" /tmp/own-stale.log \
    || { echo "FAIL FR-INIT-230 — the refusal does not say why"; cat /tmp/own-stale.log; exit 1; }
find "$OWN" -type f | sort | xargs cksum > /tmp/own-after.sum
diff /tmp/own-before.sum /tmp/own-after.sum
# The refusal comes before the dry-run branch, or a dry run would list a
# move the real run refuses.
rc=0; python3 tools/srs_init.py "$OWN" --defaults --dry-run --areas "APP" "${LEXICON[@]}" > /tmp/own-stale-dry.log || rc=$?
test "$rc" -eq 3 || { echo "FAIL FR-INIT-230 — a stale archive did not stop a dry run with exit 3 (got $rc)"; cat /tmp/own-stale-dry.log; exit 1; }
if grep -q "set aside" /tmp/own-stale-dry.log; then
    echo "FAIL FR-INIT-230 — a dry run listed a move the real run refuses"; cat /tmp/own-stale-dry.log; exit 1
fi
rm -r "$OWN/specs/archive"

python3 tools/srs_init.py "$OWN" --defaults --areas "APP" "${LEXICON[@]}" > /tmp/own-real.log
cmp /tmp/own-readme.orig "$OWN/specs/archive/README-before-srs-dd.md" \
    || { echo "FAIL FR-INIT-230 — the archived standard is not the project's own, byte for byte"; exit 1; }
grep -q "SRS-DD-[0-9]" "$OWN/specs/README.md" \
    || { echo "FAIL FR-INIT-230 — the installed standard carries no marker"; exit 1; }
grep -q "set aside as specs/archive/README-before-srs-dd.md" /tmp/own-real.log \
    || { echo "FAIL FR-INIT-230 — the output does not name where the standard went"; cat /tmp/own-real.log; exit 1; }
grep -qF "specs/README.md -> specs/archive/README-before-srs-dd.md" /tmp/own-real.log \
    || { echo "FAIL FR-INIT-230 — the summary does not list the move"; cat /tmp/own-real.log; exit 1; }
grep -qF 'Об этой папке' "$OWN/specs/10-fr-app/README.md" \
    || { echo "FAIL FR-INIT-230 — an area directory's README was touched"; exit 1; }
(cd "$OWN" && python3 tools/srs_check.py --no-write) > /tmp/own-check.log 2>&1
grep -q "Files scanned: 2\." /tmp/own-check.log \
    || { echo "FAIL FR-INIT-230 — the target's checker read the archive as requirements"; cat /tmp/own-check.log; exit 1; }
