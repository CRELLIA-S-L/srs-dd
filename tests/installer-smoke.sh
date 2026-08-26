#!/usr/bin/env bash
# tools/srs_init.py: fresh install, upgrade, --dry-run honesty, coexistence
# with a project's own pre-commit hook, and isolation of the payload.
#
# verifies: FR-GND-280, FR-GND-290, FR-GND-300, FR-GND-310, FR-GND-320
# verifies: FR-GND-480
# verifies: FR-INIT-170, FR-INIT-180, FR-INIT-190
set -eo pipefail

# implements: FR-CI-090
# A hook runs with GIT_INDEX_FILE and GIT_DIR pointing at the commit being
# prepared, and everything this suite starts inherits them — so a `git add`
# meant for the throwaway target below would write that target's paths into
# the commit in progress (FR-CI-090). Cleared here, once, before anything.
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."
. tools/test_lib.sh

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

# The standard is precious too, and that is the half of FR-INIT-060 that
# was missing until 0.14.0: it was installed once and never moved again,
# so a project set up at 0.7.0 ran the current tooling against a standard
# 112 lines out of date. It joins the precious files rather than the
# tooling because adopt leaves a project its own on purpose (FR-INIT-040).
printf 'ours, edited\n' >> /tmp/srs-precious/specs/README.md
python3 tools/srs_init.py /tmp/srs-precious --defaults > /tmp/std-keep.log
grep -qF "specs/README.md (use --force to refresh)" /tmp/std-keep.log
grep -q "ours, edited" /tmp/srs-precious/specs/README.md

python3 tools/srs_init.py /tmp/srs-precious --defaults --force \
    > /tmp/std-force.log
if grep -q "ours, edited" /tmp/srs-precious/specs/README.md; then
    echo "--force did not refresh the standard"
    exit 1
fi
grep -qE "SRS-DD-[0-9]+\.[0-9]+\.[0-9]+" /tmp/srs-precious/specs/README.md

# The version is what makes the marker a marker, and the standard is where
# that matters: skeleton/AGENTS.md teaches the sentence "the project follows
# the SRS-DD standard", so a project that adopted the framework and wrote a
# standard of its own is likely to carry the bare name. Matched loosely, its
# document would be read as ours and replaced — undoing exactly what adopt
# preserved.
printf '# Our own notes\n\nWe follow the SRS-DD standard.\n' \
    > /tmp/srs-precious/specs/README.md
python3 tools/srs_init.py /tmp/srs-precious --defaults --force \
    > /tmp/std-mine.log
grep -qF "specs/README.md (no SRS-DD marker" /tmp/std-mine.log
grep -q "Our own notes" /tmp/srs-precious/specs/README.md

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
# The whole installed target, not the skills alone. Skills were the only
# prose the installer shipped when this was written; the register's
# standard is prose too, and the check has to follow what travels rather
# than what travelled once.
target = '/tmp/srs-clean'
mine = {'specs/90-traceability.md'}          # generated from the target's own
# tools/ is in scope. It was excluded while the shipped Python still
# carried its own `implements:` annotations; the installer now takes them
# out on the way into a target (FR-INIT-180), so the one place this check
# was blind to is the one that could have resolved to a stranger's
# requirement.
found = []
for root, dirs, files in os.walk(target):
    dirs[:] = [d for d in dirs if d != '.git']
    for name in sorted(files):
        path = os.path.join(root, name)
        rel = os.path.relpath(path, target)
        if rel in mine:
            continue
        try:
            lines = list(enumerate(open(path, encoding='utf-8'), 1))
        except (OSError, UnicodeDecodeError):
            continue
        for lineno, line in lines:
            for rid in RE.findall(line):
                found.append('%s:%d %s' % (rel, lineno, rid))
assert not found, ('something the installer shipped cites a requirement of '
                   'this framework, which the target does not have — and may '
                   'have its own requirement under that number: %s' % found)
PY

# verifies: FR-INIT-210, FR-INIT-220
# The width is taken as given and written where an agent will read it. A
# project that states none gets no key and no bullet — a default invented
# here would be this framework formatting somebody else's code.
rm -rf /tmp/srs-width /tmp/srs-width-bad
python3 tools/srs_init.py /tmp/srs-width --defaults --line-width 100 \
    > /tmp/width.log 2>&1
python3 - <<'PY3'
import json
cfg = json.load(open('/tmp/srs-width/specs/srs-config.json', encoding='utf-8'))
assert cfg.get('line_width') == 100, 'line_width not recorded: %r' % cfg.get('line_width')
guide = open('/tmp/srs-width/AGENTS.md', encoding='utf-8').read()
assert '100 columns' in guide, 'the agent guide does not name the width'
assert 'SRS-DD-WIDTH-LINE' not in guide, 'the placeholder travelled'
PY3

rm -rf /tmp/srs-width-none
python3 tools/srs_init.py /tmp/srs-width-none --defaults > /tmp/width-none.log 2>&1
python3 - <<'PY3'
import json
cfg = json.load(open('/tmp/srs-width-none/specs/srs-config.json',
                     encoding='utf-8'))
assert 'line_width' not in cfg, 'a width was invented: %r' % cfg.get('line_width')
guide = open('/tmp/srs-width-none/AGENTS.md', encoding='utf-8').read()
assert 'Line width' not in guide, 'the guide names a width nobody stated'
assert 'SRS-DD-WIDTH-LINE' not in guide, 'the placeholder travelled'
PY3

# A width that is not a positive number is refused rather than written.
rc=0; python3 tools/srs_init.py /tmp/srs-width-bad --defaults --line-width nope \
    > /tmp/width-bad.log 2>&1 || rc=$?
test "$rc" -eq 2
grep -q "positive number of columns" /tmp/width-bad.log
test ! -e /tmp/srs-width-bad/specs/srs-config.json

# verifies: FR-INIT-180, FR-INIT-190
# An annotation is removed, not deleted: the line stays a line, so a
# traceback from a target names what it names here. Asserted per file
# rather than in total, because one tool losing its length is how this
# breaks and a sum would hide it.
python3 - <<'PY3'
import os
for name in sorted(os.listdir('/tmp/srs-clean/tools')):
    if not name.endswith('.py'):
        continue
    mine = open(os.path.join('tools', name), encoding='utf-8').read()
    theirs = open(os.path.join('/tmp/srs-clean/tools', name),
                  encoding='utf-8').read()
    assert mine.count(chr(10)) == theirs.count(chr(10)), (
        '%s: %d lines here, %d in the target — a removed annotation took '
        'its line with it' % (name, mine.count(chr(10)),
                              theirs.count(chr(10))))
    header = theirs.split('"""')[0]
    assert 'SRS-DD-' in header, '%s: no version stamp in the header' % name
PY3

# The example annotations are what a target reads the format from, so they
# survive — and `srs-ignore` is what says they are examples rather than
# claims.
grep -q 'implements: FR-CORE-010' /tmp/srs-clean/tools/srs_check.py  # srs-ignore

# --- verifies: FR-GND-280, FR-GND-290, FR-GND-300, FR-GND-310, FR-GND-320
# --- The grounds register: offered, never imposed, and complete or absent.
GT=/tmp/srs-grounds-target
rm -rf "$GT"
python3 tools/srs_init.py "$GT" --defaults --areas APP --ci github \
    --grounds yes > /tmp/grounds-fresh.log 2>&1

# All of it or none of it: the standard, the starter files, the checker and
# the procedure only make sense together.
for f in grounds/README.md grounds/grounds-config.json grounds/00-ideology.md \
         grounds/01-frames.md grounds/02-unclaimed.md grounds/03-bets.md \
         tools/srs_grounds.py .claude/skills/srs-bet/SKILL.md; do
    [ -f "$GT/$f" ] || { echo "FAIL FR-GND-280/320 — $f did not travel"; exit 1; }
done

# What was installed passes the target's own checker strictly, so a project's
# first red run means something the project did.
( cd "$GT" && python3 tools/srs_grounds.py --no-write --strict ) \
    > /tmp/grounds-strict.log 2>&1 \
    || { echo "FAIL FR-GND-300 — a fresh register does not pass strictly"
         cat /tmp/grounds-strict.log; exit 1; }

# And a dashboard is there to compare against: the gate the templates carry
# would otherwise fail before anybody wrote a record.
[ -f "$GT/grounds/90-dashboard.md" ] \
    || { echo "FAIL FR-GND-300 — no dashboard was generated"; exit 1; }

# Declined, the register leaves nothing: a target that said no is
# byte-for-byte a target that was never asked.
rm -rf /tmp/srs-nogrounds
python3 tools/srs_init.py /tmp/srs-nogrounds --defaults --areas APP \
    --ci none --grounds no > /dev/null 2>&1
for f in grounds tools/srs_grounds.py .claude/skills/srs-bet; do
    [ -e "/tmp/srs-nogrounds/$f" ] \
        && { echo "FAIL FR-GND-280 — $f arrived at a target that declined"
             exit 1; }
done

# An upgrade adds nothing unasked — the projects it would surprise are the
# ones that never heard of the layer — and says how to ask.
python3 tools/srs_init.py /tmp/srs-nogrounds --defaults \
    > /tmp/grounds-upgrade.log 2>&1
[ -e /tmp/srs-nogrounds/grounds ] \
    && { echo "FAIL FR-GND-290 — an upgrade installed the register unasked"
         exit 1; }
grep -qF -- "--grounds yes" /tmp/grounds-upgrade.log \
    || { echo "FAIL FR-GND-290 — an upgrade says nothing about the register"
         cat /tmp/grounds-upgrade.log; exit 1; }

# Asked, it adds it.
python3 tools/srs_init.py /tmp/srs-nogrounds --defaults --grounds yes \
    > /dev/null 2>&1
[ -f /tmp/srs-nogrounds/grounds/grounds-config.json ] \
    || { echo "FAIL FR-GND-290 — an upgrade asked for the register and did"
         echo "not install it"; exit 1; }

# The hook reports what the commit touches and never fails it. A refuted
# hypothesis is not the committer's fault and may be what they are repairing.
cat > "$GT/grounds/10-h-product.md" <<'MD'
### H-010 — Studios lose time to manual roll-up

```yaml
status: refuted
class: III
population: studios of five to fifty people
refuted_if: proportion < 0.15 at n >= 250
expires: 2027-03-01
owner: @kira
impact: about half the 2027 plan
```

Studios spend more than an hour a week assembling reports by hand.
MD
cat > "$GT/grounds/03-bets.md" <<'MD'
### B-010 — The placeholder requirement stands on it

```yaml
status: active
requirement: FR-APP-010
all_of: [H-010]
```

The requirement exists because that was believed.
MD
( cd "$GT" && git init -q . && git add -A && python3 tools/srs_grounds.py \
  && sh .githooks/pre-commit ) > /tmp/grounds-hook.log 2>&1
rc=$?
[ "$rc" = 0 ] || { echo "FAIL FR-GND-310 — the hook failed the commit over a"
                   echo "refuted hypothesis"; cat /tmp/grounds-hook.log; exit 1; }
grep -qF "FR-APP-010 — B-010 rests on H-010 (refuted)" /tmp/grounds-hook.log \
    || { echo "FAIL FR-GND-310 — the hook said nothing about the bet"
         cat /tmp/grounds-hook.log; exit 1; }

# A register that warns is the ordinary case — an expired hypothesis is
# what this layer exists to surface — and an install that reported failure
# over one would be an install nobody believes. The exit code is for errors.
cat > "$GT/grounds/10-h-product.md" <<'MD'
### H-010 — Term ran out a while ago

```yaml
status: assumed
class: III
population: studios of five to fifty people
refuted_if: proportion < 0.15 at n >= 250
expires: 2020-01-01
owner: @kira
impact: about half the 2027 plan
```

Studios spend more than an hour a week assembling reports by hand.
MD
# Any warning serves: what the next assertion needs is a register that
# warns at all, not one that warns by a particular rule. Naming the rule
# here couples this fixture to which of them happens to speak.
( cd "$GT" && python3 tools/srs_grounds.py --no-write 2>&1 | grep -q "^warning:" ) \
    || { echo "FAIL — the fixture register does not warn, so the next"
         echo "assertion would hold for any register at all"; exit 1; }
python3 tools/srs_init.py "$GT" --defaults > /tmp/grounds-warn.log 2>&1 \
    || { echo "FAIL FR-GND-290 — an upgrade failed over a warning in the"
         echo "register"; tail -5 /tmp/grounds-warn.log; exit 1; }

# And nothing under --force overwrites what the project authored. The
# standard is refreshed; the records are the project's.
printf '\n### F-010 — Ours\n\n```yaml\nstatus: active\n```\n\nWe do not sell attention.\n' \
    >> "$GT/grounds/01-frames.md"
before=$(cksum < "$GT/grounds/01-frames.md")
python3 tools/srs_init.py "$GT" --defaults --force > /dev/null 2>&1
[ "$(cksum < "$GT/grounds/01-frames.md")" = "$before" ] \
    || { echo "FAIL — --force overwrote a record the project wrote"; exit 1; }

# A flag that reads as an instruction and does nothing has to say so: the
# installer tells a target about its other inert flags already.
python3 tools/srs_init.py "$GT" --defaults --grounds no > /tmp/grounds-no.log 2>&1
grep -qF "does not remove a register that is already there" /tmp/grounds-no.log \
    || { echo "FAIL — --grounds no was silently ignored on a target that"
         echo "carries a register"; exit 1; }
[ -f "$GT/grounds/grounds-config.json" ] \
    || { echo "FAIL — --grounds no removed the register"; exit 1; }

# The register's one install-time choice: what "lately" means for this
# project. Written rather than copied, so it carries the answer.
python3 - "$GT/grounds/grounds-config.json" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1], encoding="utf-8"))
assert cfg.get("period") == "quarter", \
    "the register's configuration does not carry the period chosen at install"
PY
rm -rf /tmp/srs-period; python3 tools/srs_init.py /tmp/srs-period --defaults \
    --areas APP --ci none --grounds yes --period year > /dev/null 2>&1
grep -qF '"period": "year"' /tmp/srs-period/grounds/grounds-config.json \
    || { echo "FAIL FR-GND-480 — --period was not written into the register's"
         echo "configuration"; cat /tmp/srs-period/grounds/grounds-config.json
         exit 1; }
grep -qF "Counted by year" /tmp/srs-period/grounds/90-dashboard.md \
    || { echo "FAIL FR-GND-480 — the dashboard does not count by the unit"
         echo "the install chose"; exit 1; }

# A setting that has nothing to set says so rather than evaporating.
rm -rf /tmp/srs-noperiod
python3 tools/srs_init.py /tmp/srs-noperiod --defaults --areas APP --ci none \
    --grounds no --period month > /tmp/srs-noperiod.log 2>&1
grep -qF "it has nothing to set" /tmp/srs-noperiod.log \
    || { echo "FAIL FR-GND-480 — --period without a register was dropped in"
         echo "silence"; cat /tmp/srs-noperiod.log; exit 1; }
[ -e /tmp/srs-noperiod/grounds ] \
    && { echo "FAIL FR-GND-480 — --period pulled in a register that was"
         echo "declined"; exit 1; }
absent "grounds" /tmp/srs-noperiod/specs/srs-config.json

# --- verifies: FR-INIT-170 — an undated specification is told it can be
# --- dated, and nothing is written on its behalf. Nobody looks for a tool
# --- they have not heard of, and an install is when the framework has a
# --- project's attention.
grep -qF "carry no \`created\` date" /tmp/grounds-fresh.log \
    || { echo "FAIL FR-INIT-170 — an undated specification was not offered"
         echo "the dating command"; tail -8 /tmp/grounds-fresh.log; exit 1; }
absent "created:" "$GT/specs/10-fr-app.md"

echo "installer-smoke: the grounds register is offered, complete and quiet"
