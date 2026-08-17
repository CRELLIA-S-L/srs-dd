#!/usr/bin/env bash
# tools/srs_init.py: fresh install, upgrade, --dry-run honesty, coexistence
# with a project's own pre-commit hook, and isolation of the payload.
set -eo pipefail
cd "$(dirname "$0")/.."

# Clean slate: on shell runners a leftover dir would silently flip the
# fresh-install step into upgrade mode.
rm -rf /tmp/srs-target

# verifies: FR-INIT-070
# --dry-run must list the whole install and create nothing at all.
python3 tools/srs_init.py /tmp/srs-target --defaults --ci both --dry-run | tee /tmp/dry.log
grep -q "tools/srs_view.py" /tmp/dry.log
grep -q "nothing was written" /tmp/dry.log
test ! -e /tmp/srs-target

# verifies: FR-INIT-010, FR-INIT-020, FR-CI-050
# Fresh install into a temp dir must pass its own checker, strictly.
# The mode was chosen by looking at the target, and nothing told it to.
# `--ci both` lays down the templates for either forge, and what lands is
# theirs rather than this repository's own pipeline — the `.gitlab-ci.yml`
# checked further down is one of the two.
python3 tools/srs_init.py /tmp/srs-target --defaults --ci both | tee /tmp/fresh.log
python3 /tmp/srs-target/tools/srs_check.py --strict

# verifies: FR-INIT-150
# It also has to leave the maintainer knowing what to do next: where the
# first requirement goes, what reads and checks the specification, and how
# the framework is upgraded later.
grep -q "First steps:" /tmp/fresh.log
grep -q "specs/10-fr-core.md" /tmp/fresh.log
grep -q "tools/srs_check.py" /tmp/fresh.log
grep -q "tools/srs_view.py --html" /tmp/fresh.log
grep -q "tools/srs_upgrade.py" /tmp/fresh.log
grep -q "AGENTS.md" /tmp/fresh.log
# verifies: FR-SKILL-080, FR-SKILL-100, FR-SKILL-110, FR-SKILL-070
# Every skill that ships is named, and none that does not. The last of
# those is named by its absence: srs-release stays here.
for skill in srs srs-new srs-audit srs-harvest srs-upgrade srs-baseline \
             srs-check srs-page; do
    grep -qE "^       $skill +" /tmp/fresh.log
done
for framework_only in srs-init srs-release; do
    if grep -qE "^       $framework_only +" /tmp/fresh.log; then
        echo "$framework_only is framework-only and must not be offered"
        exit 1
    fi
    if [ -e "/tmp/srs-target/.claude/skills/$framework_only" ]; then
        echo "$framework_only travelled into a target"
        exit 1
    fi
done
# The first thing a maintainer sees must not wrap: everything the
# installer prints stays inside 120 columns, except the target path, which
# is theirs and not ours to shorten. The number is a convention this suite
# carries alone — no requirement states it; see specs/91-open-issues.md.
python3 - <<'PY2'
wide = [l.rstrip('\n') for l in open('/tmp/fresh.log', encoding='utf-8')
        if len(l.rstrip('\n')) > 120 and not l.startswith('Installing into ')]
assert not wide, 'installer output wraps: %r' % wide[:2]
PY2

# The agent procedures come first: the framework exists so that code
# written with agents still has requirements behind it.
agents=$(grep -n "AGENTS.md" /tmp/fresh.log | head -1 | cut -d: -f1)
first=$(grep -nE "^  2\\. Replace the placeholder" /tmp/fresh.log | head -1 | cut -d: -f1)
test "$agents" -lt "$first"

# verifies: FR-INIT-060
# Re-running on an initialized target = upgrade mode; the checker and
# skills must refresh WITHOUT --force, precious files must be skipped.
# The stub proves upgrades deliver skill content (the fresh install above
# already wrote the real file — a bare grep would prove nothing).
printf 'stub\n' > /tmp/srs-target/.claude/skills/srs/SKILL.md
printf 'stub\n' > /tmp/srs-target/tools/srs_view.py

# An upgrade dry-run reports the same refresh list and still changes
# nothing — checked byte-for-byte, not by eye.
find /tmp/srs-target -type f | sort | xargs cksum > /tmp/before.dry
python3 tools/srs_init.py /tmp/srs-target --defaults --dry-run > /tmp/upgrade-dry.log
grep -q "tools/srs_view.py" /tmp/upgrade-dry.log
find /tmp/srs-target -type f | sort | xargs cksum > /tmp/after.dry
diff /tmp/before.dry /tmp/after.dry

python3 tools/srs_init.py /tmp/srs-target --defaults | tee /tmp/upgrade.log
grep -q "refreshed:" /tmp/upgrade.log
grep -q "tools/srs_check.py" /tmp/upgrade.log
grep -q "Planning multi-requirement work" /tmp/srs-target/.claude/skills/srs/SKILL.md
grep -q "self-contained HTML site" /tmp/srs-target/tools/srs_view.py
test -f /tmp/srs-target/.gitlab-ci.yml   # precious file survived untouched

# verifies: FR-INIT-080
# A project's own pre-commit hook is never displaced: the gate lands
# beside it, and the advice must not tell the user to point
# core.hooksPath at .githooks, which would disable what they have.
rm -rf /tmp/srs-hook
mkdir -p /tmp/srs-hook/.githooks
printf '#!/bin/sh\necho theirs\n' > /tmp/srs-hook/.githooks/pre-commit
git -C /tmp/srs-hook init -q .
git -C /tmp/srs-hook config core.hooksPath .githooks
python3 tools/srs_init.py /tmp/srs-hook --defaults --ci none > /tmp/hook.log
grep -q "echo theirs" /tmp/srs-hook/.githooks/pre-commit
test -x /tmp/srs-hook/.githooks/pre-commit.srs-dd
grep -q "pre-commit.srs-dd" /tmp/hook.log
# Not `grep -qv`: that inverts per line, so on GNU grep it passes whenever
# any line differs — a check that can never fail.
if grep -q "git config core.hooksPath" /tmp/hook.log; then
    echo "must not advise switching hooksPath over an existing hook"
    exit 1
fi

# A hook of theirs somewhere else must not be shadowed either.
rm -rf /tmp/srs-hook2 && mkdir -p /tmp/srs-hook2
git -C /tmp/srs-hook2 init -q .
printf '#!/bin/sh\necho mine\n' > /tmp/srs-hook2/.git/hooks/pre-commit
chmod +x /tmp/srs-hook2/.git/hooks/pre-commit
python3 tools/srs_init.py /tmp/srs-hook2 --defaults --ci none > /tmp/hook2.log
grep -q "already runs .git/hooks/pre-commit" /tmp/hook2.log

# Whatever a maintainer generates under skeleton/specs/ in their clone
# must not travel into targets as skeleton content.
printf 'stray\n' > skeleton/specs/stray.html
rm -rf /tmp/srs-clean
rc=0; python3 tools/srs_init.py /tmp/srs-clean --defaults --ci none >/dev/null || rc=$?
rm -f skeleton/specs/stray.html
test "$rc" -eq 0
test ! -e /tmp/srs-clean/specs/stray.html

# verifies: FR-CHK-130
# A baseline tag with no row in the log is reported, and --strict makes
# it a failure: cutting a baseline is a tag and a row in separate
# commits, and the gap between them is where it gets forgotten.
rm -rf /tmp/srs-base
python3 tools/srs_init.py /tmp/srs-base --defaults --ci none >/dev/null
(
    cd /tmp/srs-base
    git init -q .
    git add -A
    git -c user.email=ci@example.com -c user.name=CI commit -qm base
    git tag spec/v0.1.0
    python3 tools/srs_check.py --no-write 2>&1 | grep -q "no row for baseline tag spec/v0.1.0"
    rc=0; python3 tools/srs_check.py --no-write --strict >/dev/null 2>&1 || rc=$?
    test "$rc" -eq 1
    python3 - <<'PY2'
path = 'specs/92-baselines.md'
text = open(path, encoding='utf-8').read()
open(path, 'w', encoding='utf-8').write(text.replace(
    '*No baselines yet.*',
    '| 0.1.0 | 2026-01-01 | `spec/v0.1.0` | First freeze. |'))
PY2
    python3 tools/srs_check.py --no-write --strict >/dev/null
)

# verifies: FR-CHK-210
# The other end of the same decision: a fresh project has no
# code yet, so it has nothing to silence and starts strict. A default
# written for both modes would be that decision quietly reversed.
python3 - <<'PY2'
import json
fresh = json.load(open('/tmp/srs-target/specs/srs-config.json',
                       encoding='utf-8'))
assert 'annotation-absent' not in fresh.get('rules', {}), \
    'a fresh install silenced a rule it has no reason to: %r' % fresh.get('rules')
PY2

# A precious file is refreshed only with --force, and only when it is one of
# ours (FR-INIT-060). Neither half had a fixture: the assertion above holds
# that a CI file still exists, which stays true whether or not the installer
# rewrote it, and --force appeared in no suite at all. .gitattributes rather
# than the CI config, because an upgrade visits the CI templates only when
# --ci is passed and this one it always writes.
rm -rf /tmp/srs-precious
python3 tools/srs_init.py /tmp/srs-precious --defaults --ci none >/dev/null
printf 'theirs\n' >> /tmp/srs-precious/.gitattributes
cksum < /tmp/srs-precious/.gitattributes > /tmp/precious.before

# No flag: kept as it stands, and the summary says what would refresh it.
python3 tools/srs_init.py /tmp/srs-precious --defaults > /tmp/precious-keep.log
grep -qF ".gitattributes (use --force to refresh)" /tmp/precious-keep.log
cksum < /tmp/srs-precious/.gitattributes > /tmp/precious.after
diff /tmp/precious.before /tmp/precious.after

# With the flag: refreshed, because the file still carries our marker.
python3 tools/srs_init.py /tmp/srs-precious --defaults --force \
    > /tmp/precious-force.log
# Refreshed, not removed: grep on a file that is gone answers "no match"
# just as loudly as grep on a file that was rewritten, so what the file
# holds afterwards is asserted rather than only what it lost.
grep -q "SRS-DD" /tmp/srs-precious/.gitattributes
if grep -q "theirs" /tmp/srs-precious/.gitattributes; then
    echo "--force did not refresh a precious file of ours"
    exit 1
fi

# A file of theirs sitting at the same path is never clobbered, flag or no
# flag: the marker is how the installer tells its own file from a stranger's,
# and getting this wrong is how a tool eats somebody's configuration.
printf 'not ours at all\n' > /tmp/srs-precious/.gitattributes
python3 tools/srs_init.py /tmp/srs-precious --defaults --force \
    > /tmp/precious-mine.log
grep -qF "no SRS-DD marker" /tmp/precious-mine.log
grep -q "not ours at all" /tmp/srs-precious/.gitattributes

# verifies: IF-CI-010
# The installer's exit codes are a contract. The adopt suite
# covers 0, 2 and 3; 1 — the checker found errors in the target — was
# covered by nothing. An upgrade ends by running the target's own checker
# and hands back its verdict, so a target whose specification is broken is
# the honest way to reach it.
python3 - <<'PY2'
path = '/tmp/srs-precious/specs/10-fr-core.md'
text = open(path, encoding='utf-8').read()
open(path, 'w', encoding='utf-8').write(
    text.replace('status: deferred', 'status: implemented', 1))
PY2
rc=0; python3 tools/srs_init.py /tmp/srs-precious --defaults \
    > /tmp/precious-broken.log 2>&1 || rc=$?
test "$rc" -eq 1
grep -q "status implemented but the code field is empty" /tmp/precious-broken.log

# verifies: CON-SPEC-020
# specs/ here is the framework's own specification, not payload (ART-070).
# A fresh target must hold exactly one requirement — the generated
# placeholder — and nothing of ours. Asked through the parser rather than
# grep: the standard itself carries example identifiers in prose.
python3 /tmp/srs-clean/tools/srs_view.py --json /tmp/target.json >/dev/null
python3 - <<'PY'
import json
ids = [r['id'] for r in json.load(open('/tmp/target.json'))['requirements']]
assert ids == ['FR-CORE-010'], 'framework requirements leaked: %s' % ids
PY

# The other way an identifier leaks: named in the prose of a shipped skill.
# That one is worse than a dangling reference. Areas are the project's to
# declare, so a target may well have an `FR-SKILL-090` of its own — and an
# agent following the citation lands on a real requirement of theirs saying
# something else entirely. Checked against the shipped tree rather than
# ours, because what matters is what a stranger receives.
python3 - <<'PY'
import json, os, re
# Identifiers in *this framework's* areas, which is what CON-SPEC-020
# forbids. An example in a template — `FR-CORE-050` under the default area
# this project does not declare — is a shape to fill in, not a citation:
# nobody is being asked to look it up.
areas = json.load(open('specs/srs-config.json', encoding='utf-8'))['areas']
RE = re.compile(r'\b(?:FR|NFR|IF|INV|CON)-(?:%s)-\d{3}\b' % '|'.join(areas))
skills = '/tmp/srs-clean/.claude/skills'
found = []
for root, _dirs, files in os.walk(skills):
    for name in files:
        path = os.path.join(root, name)
        for lineno, line in enumerate(open(path, encoding='utf-8'), 1):
            for rid in RE.findall(line):
                found.append('%s:%d %s' % (os.path.relpath(path, skills),
                                           lineno, rid))
assert not found, ('a shipped skill cites a requirement of this framework, '
                   'which the target does not have — and may have its own '
                   'requirement under that number: %s' % found)
PY
