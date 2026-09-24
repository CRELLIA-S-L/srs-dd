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
# With the register and with both pipelines, because this target is what the
# leak check and the annotation check below walk, and they see only what is
# installed. Without the register they never saw tools/srs_grounds.py or
# grounds/README.md, so the whole register payload shipped unexamined — and
# did ship a citation of this framework's own requirements. Without a CI
# config the same hole stood open at ci/: those templates become a target's
# pipeline and hook, and nothing looked at them on the way. Declining either
# is asserted on targets of its own further down.
rc=0; python3 tools/srs_init.py /tmp/srs-clean --defaults --ci both \
      --grounds yes --arch yes >/dev/null || rc=$?
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

# FR-INIT-060 names seven kinds of file that an upgrade replaces only with
# --force and only when they carry our marker. Two of them had fixtures and
# five did not, which is the shape the rule itself is about: a sentence
# quantifying over a list, a suite exercising one entry, and nothing that
# can tell the difference. Dropping `precious=` from the architecture
# standard left the whole gate green.
#
# So the list is walked rather than sampled, and it is written here in the
# order the statement names it.
PT=/tmp/srs-precious
rm -rf "$PT" /tmp/srs-pristine
python3 tools/srs_init.py "$PT" --defaults --name "Acme Widgets" \
    --line-width 100 --ci github --grounds yes --arch yes >/dev/null
cp -R "$PT" /tmp/srs-pristine

# precious <path> [extra upgrade flags…]
# Three phases, because the rule has three outcomes and a fixture for one of
# them proves neither of the others: kept without the flag, replaced with it,
# and left alone either way when the file at that path is not ours.
precious() {
    local rel=$1; shift
    cp "/tmp/srs-pristine/$rel" "$PT/$rel"

    # verifies: FR-INIT-240
    # A skipped file says whether it differs from what this version ships:
    # the copy it installed does not, the same copy edited does. Without the
    # first half every skipped file could be reported as changed and this
    # would stay green.
    python3 tools/srs_init.py "$PT" --defaults "$@" > /tmp/prec-same.log
    grep -qF "$rel (same as this version ships)" /tmp/prec-same.log \
        || { echo "FAIL FR-INIT-240 — $rel: an untouched copy was not reported"
             echo "as the same as what this version ships"; cat /tmp/prec-same.log; exit 1; }

    printf 'theirs, edited\n' >> "$PT/$rel"
    python3 tools/srs_init.py "$PT" --defaults "$@" > /tmp/prec-keep.log
    grep -qF "$rel (differs from what this version ships; use --force to refresh)" /tmp/prec-keep.log \
        || { echo "FAIL FR-INIT-060 — $rel: an upgrade did not report it as"
             echo "kept behind --force, and as differing (FR-INIT-240)"; cat /tmp/prec-keep.log; exit 1; }
    grep -qF 'theirs, edited' "$PT/$rel" \
        || { echo "FAIL FR-INIT-060 — $rel was refreshed without --force"
             exit 1; }

    # Refreshed, not removed: grep on a file that is gone answers "no match"
    # as loudly as grep on one that was rewritten, so what the file holds
    # afterwards is asserted and not only what it lost.
    python3 tools/srs_init.py "$PT" --defaults --force "$@" > /tmp/prec-force.log
    absent 'theirs, edited' "$PT/$rel"
    grep -q "SRS-DD" "$PT/$rel" \
        || { echo "FAIL FR-INIT-060 — $rel lost our marker under --force"
             exit 1; }

    # A file of theirs at the same path is never clobbered, flag or no flag:
    # the marker is how the installer tells its own file from a stranger's,
    # and getting this wrong is how a tool eats somebody's configuration.
    printf '# Ours, and no marker in it\n' > "$PT/$rel"
    python3 tools/srs_init.py "$PT" --defaults --force "$@" > /tmp/prec-mine.log
    grep -qF "$rel (no SRS-DD marker" /tmp/prec-mine.log \
        || { echo "FAIL FR-INIT-060 — $rel: a stranger's file was not reported"
             echo "as skipped"; cat /tmp/prec-mine.log; exit 1; }
    grep -qF 'Ours, and no marker in it' "$PT/$rel" \
        || { echo "FAIL FR-INIT-060 — $rel: --force overwrote a file that is"
             echo "not ours"; exit 1; }
    cp "/tmp/srs-pristine/$rel" "$PT/$rel"
}

# The CI template carries its own flag because an upgrade visits it only
# when --ci is passed; everything else below is visited on every run.
precious .github/workflows/srs.yml --ci github
precious .gitattributes
precious .githooks/pre-commit
# The standard was the half missing until 0.14.0: installed once and never
# moved again, so a project set up at 0.7.0 ran current tooling against a
# standard 112 lines out of date. It is precious rather than tooling because
# adopt leaves a project its own on purpose (FR-INIT-040), and each optional
# layer's standard travels on exactly those terms.
precious specs/README.md
precious grounds/README.md
precious arch/README.md
precious AGENTS.md
precious CLAUDE.md

# --- verifies: FR-INIT-200 — the guides are the one payload file that is
# --- filled in rather than copied, so refreshing one needs the answers the
# --- install took. Until the name was recorded there was nothing to fill
# --- the template with, and the installer refreshed them under no flag at
# --- all — while FR-INIT-060 listed them among the files --force replaces
# --- and the guide's own header said --force would overwrite it.
grep -q '"project_name": "Acme Widgets"' "$PT/specs/srs-config.json" \
    || { echo "FAIL FR-INIT-200 — the install did not record the project name"
         exit 1; }

# The generic phases above prove the guide was rewritten; they cannot tell a
# rewrite that filled the blanks from one that shipped the template as it
# stands. That is what this asserts, and it is the whole difficulty.
printf 'theirs, edited\n' >> "$PT/AGENTS.md"
python3 tools/srs_init.py "$PT" --defaults --force > /tmp/prec-guides.log
absent 'theirs, edited' "$PT/AGENTS.md"
absent '<Your Project Name>' "$PT/AGENTS.md"
absent '<SRS-DD-WIDTH-LINE>' "$PT/AGENTS.md"
grep -qF 'Acme Widgets' "$PT/AGENTS.md" \
    || { echo "FAIL FR-INIT-200 — the refreshed guide lost the project name"
         exit 1; }
grep -qF '100 columns' "$PT/AGENTS.md" \
    || { echo "FAIL FR-INIT-200 — the refreshed guide lost the line width"
         exit 1; }

# An answer the configuration carries but nothing can use: both values are
# interpolated into text, so a name that is not a string dies in
# `str.replace` and a width that is not a whole number dies in `%d`. The
# tool runs inside somebody else's repository, and the file it reads them
# from is one a maintainer edits by hand.
# badvalue <key> <json literal> — the configuration says something the
# installer cannot use, and the run says so instead of dying.
badvalue() {
    KEY="$1" VAL="$2" python3 - "$PT/specs/srs-config.json" <<'PY2'
import json
import os
import sys
path = sys.argv[1]
with open(path, encoding='utf-8') as handle:
    data = json.load(handle)
data[os.environ['KEY']] = json.loads(os.environ['VAL'])
with open(path, 'w', encoding='utf-8') as handle:
    json.dump(data, handle, indent=2)
PY2
    local rc=0
    python3 tools/srs_init.py "$PT" --defaults --force > /tmp/prec-bad.log 2>&1 \
        || rc=$?
    [ "$rc" = 0 ] || { echo "FAIL FR-INIT-200 — $1 of the wrong type stopped the"
                       echo "upgrade"; tail -5 /tmp/prec-bad.log; exit 1; }
    grep -qF "in specs/srs-config.json is not" /tmp/prec-bad.log \
        || { echo "FAIL FR-INIT-200 — $1 of the wrong type was used, or dropped"
             echo "in silence"; cat /tmp/prec-bad.log; exit 1; }
    absent '<Your Project Name>' "$PT/AGENTS.md"
    absent '<SRS-DD-WIDTH-LINE>' "$PT/AGENTS.md"
    cp /tmp/srs-pristine/specs/srs-config.json "$PT/specs/srs-config.json"
}

badvalue project_name 123
badvalue line_width '"100"'
badvalue line_width true

# A project installed before the name was recorded still gets its guides
# back: the directory stands in, because a guide under a slightly wrong
# title beats one that stopped being refreshed at all.
python3 - "$PT/specs/srs-config.json" <<'PY2'
import json
import sys
path = sys.argv[1]
with open(path, encoding='utf-8') as handle:
    data = json.load(handle)
data.pop('project_name', None)
with open(path, 'w', encoding='utf-8') as handle:
    json.dump(data, handle, indent=2)
PY2
printf 'theirs, edited\n' >> "$PT/AGENTS.md"
python3 tools/srs_init.py "$PT" --defaults --force > /tmp/prec-noname.log
absent 'theirs, edited' "$PT/AGENTS.md"
absent '<Your Project Name>' "$PT/AGENTS.md"
grep -qF 'srs-precious' "$PT/AGENTS.md" \
    || { echo "FAIL FR-INIT-200 — with no recorded name the directory did not"
         echo "stand in"; exit 1; }
# Put the target back as it was installed, the way the two helpers above do:
# the fixtures below share it, and one left deliberately degraded is a trap
# for whoever writes the next one.
cp /tmp/srs-pristine/specs/srs-config.json "$PT/specs/srs-config.json"
python3 tools/srs_init.py "$PT" --defaults --force > /dev/null

echo "installer-smoke: all seven precious kinds behave as FR-INIT-060 says"

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
# Two reaches, because two things leak differently. Anywhere in the target:
# identifiers in this framework's own areas. In the files that instruct —
# the guides and the skills — any area at all, because what makes a number
# harmful is that the reader can look it up, and `FR-CORE-020` under the
# area a fresh install offers first is the likeliest of all to resolve in
# their specification, to something else. The distinction that survives is
# not whose area it is but what the line does: a field in a template is a
# shape to fill in, a sentence in a procedure is a citation.
areas = json.load(open('specs/srs-config.json', encoding='utf-8'))['areas']
RE = re.compile(r'\b(?:FR|NFR|IF|INV|CON)-(?:%s)-\d{3,}\b' % '|'.join(areas))
ANY = re.compile(r'\b(?:FR|NFR|IF|INV|CON)-[A-Z]+-\d{3,}\b')

def instructs(rel):
    # The standards that travel are not procedures: their identifiers sit
    # inside the record examples that show the format, and specs/README.md
    # is the same document in every project (CON-SPEC-020's rationale).
    return (rel in ('AGENTS.md', 'CLAUDE.md')
            or (rel.startswith('.claude/skills/') and rel.endswith('SKILL.md')))
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
        pattern = ANY if instructs(rel) else RE
        for lineno, line in lines:
            for rid in pattern.findall(line):
                found.append('%s:%d %s' % (rel, lineno, rid))
assert not found, ('something the installer shipped names a requirement the '
                   'target does not have — and may have its own requirement '
                   'under that number: %s' % found)
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

# --- And the commit this report exists for: one that changes code and no
# --- specification. The fixture above stages everything, so it cannot tell
# --- the two readings apart — it passes whether the hook matches the file a
# --- requirement is written in or the files it names. Until this shipped,
# --- the second was unimplemented and the commit below got no report at all.
( cd "$GT" && git -c user.email=ci@example.com -c user.name=CI \
              commit -qm "the state before" )
mkdir -p "$GT/src"
printf 'x = 1\n' > "$GT/src/thing.py"
python3 - "$GT/specs/10-fr-app.md" <<'PY2'
import sys
path = sys.argv[1]
text = open(path, encoding='utf-8').read()
assert text.count('code: []') == 1, text
open(path, 'w', encoding='utf-8').write(
    text.replace('code: []', 'code: [src/thing.py]', 1))
PY2
# The matrix moves with the specification, and the hook fails on a stale one
# before it ever reaches the register — so it is regenerated and staged here.
# The requirement's own file is deliberately left unstaged: it is what makes
# this fixture able to fail.
( cd "$GT" && python3 tools/srs_check.py >/dev/null \
  && git add src/thing.py specs/90-traceability.md )
( cd "$GT" && git diff --cached --name-only ) > /tmp/grounds-staged.log
absent 'specs/10-fr-app.md' /tmp/grounds-staged.log
grep -qF 'src/thing.py' /tmp/grounds-staged.log \
    || { echo "FAIL FR-GND-310 — the code file was not staged, so the next"
         echo "assertion would prove nothing"; exit 1; }

rc=0
( cd "$GT" && sh .githooks/pre-commit ) > /tmp/grounds-code-hook.log 2>&1 || rc=$?
[ "$rc" = 0 ] || { echo "FAIL FR-GND-310 — the hook failed a commit that only"
                   echo "touched code"; cat /tmp/grounds-code-hook.log; exit 1; }
grep -qF "FR-APP-010 — B-010 rests on H-010 (refuted)" /tmp/grounds-code-hook.log \
    || { echo "FAIL FR-GND-310 — a commit changing only code got no report,"
         echo "which is the moment the report exists for"
         cat /tmp/grounds-code-hook.log; exit 1; }
( cd "$GT" && git checkout -- specs/10-fr-app.md specs/90-traceability.md \
  && git rm -q --cached src/thing.py >/dev/null && rm -f src/thing.py )

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

# --- verifies: FR-ARCH-120, FR-ARCH-140, FR-ARCH-150 — the architecture
# --- layer is offered, arrives whole, and what arrives passes its own gate.
AT=/tmp/srs-arch-target
rm -rf "$AT"
python3 tools/srs_init.py "$AT" --defaults --name "Arch target" \
    --areas APP --ci github --arch yes > /tmp/arch-fresh.log 2>&1
for f in arch/README.md arch/arch-config.json arch/00-elements.md \
         tools/srs_arch.py .claude/skills/srs-arch/SKILL.md; do
    [ -f "$AT/$f" ] || { echo "FAIL FR-ARCH-120 — the layer arrived without $f"
                         exit 1; }
done
( cd "$AT" && python3 tools/srs_arch.py --no-write --strict ) \
    > /tmp/arch-strict.log 2>&1 \
    || { echo "FAIL FR-ARCH-140 — a fresh layer does not pass its own checker"
         cat /tmp/arch-strict.log; exit 1; }
[ -f "$AT/arch/90-map.md" ] \
    || { echo "FAIL FR-ARCH-140 — the install left no map, and a gate compares"
         echo "the committed one against a fresh run"; exit 1; }

# --- verifies: FR-ARCH-170 — the gate a target installs compares the map.
# --- Until this shipped, a project's map was generated, committed and never
# --- looked at again: `tests/arch-check.sh` proves the comparison for this
# --- repository and says nothing about the template that travels.
grep -qF "python3 tools/srs_arch.py" "$AT/.github/workflows/srs.yml" \
    || { echo "FAIL FR-ARCH-170 — the installed pipeline does not regenerate"
         echo "the map"; exit 1; }
grep -qF "arch/90-map.md is stale" "$AT/.github/workflows/srs.yml" \
    || { echo "FAIL FR-ARCH-170 — the installed pipeline does not fail on a"
         echo "stale map"; exit 1; }

# --- And the same template reaches a project that keeps no layer, where the
# --- step is inert: it is guarded by the layer's configuration file, so it
# --- costs a project that declined the layer nothing but a passing `if`.
grep -qF "arch/arch-config.json" "$AT/.github/workflows/srs.yml" \
    || { echo "FAIL FR-ARCH-170 — the step is not guarded by the layer's"
         echo "configuration, so it would run where there is no layer"; exit 1; }
grep -qF "arch/90-map.md is stale" /tmp/srs-target/.github/workflows/srs.yml \
    || { echo "FAIL FR-ARCH-170 — a project without the layer got a different"
         echo "template"; exit 1; }

# --- Declined, it leaves no trace at all.
rm -rf /tmp/srs-noarch
python3 tools/srs_init.py /tmp/srs-noarch --defaults --areas APP \
    --ci none --arch no > /dev/null 2>&1
for f in arch tools/srs_arch.py .claude/skills/srs-arch; do
    [ -e "/tmp/srs-noarch/$f" ] \
        && { echo "FAIL FR-ARCH-120 — --arch no still installed $f"; exit 1; }
done

# --- verifies: FR-ARCH-130 — an upgrade adds it only when asked, and says
# --- how to ask.
python3 tools/srs_init.py /tmp/srs-noarch --defaults \
    > /tmp/arch-upgrade.log 2>&1
[ -e /tmp/srs-noarch/arch ] \
    && { echo "FAIL FR-ARCH-130 — an upgrade added the layer unasked"; exit 1; }
grep -qF -- "--arch yes" /tmp/arch-upgrade.log \
    || { echo "FAIL FR-ARCH-130 — the upgrade did not say how to add the layer"
         cat /tmp/arch-upgrade.log; exit 1; }
python3 tools/srs_init.py /tmp/srs-noarch --defaults --arch yes \
    > /dev/null 2>&1
[ -f /tmp/srs-noarch/arch/arch-config.json ] \
    || { echo "FAIL FR-ARCH-130 — --arch yes did not add the layer"; exit 1; }

# --- An element file a project wrote is never overwritten by an upgrade.
printf '\n### E-010 — Theirs\n\n```yaml\nstatus: proposed\ncarries: []\nrequirements: []\n```\n\nTheirs.\n' \
    >> "$AT/arch/00-elements.md"
before=$(cksum < "$AT/arch/00-elements.md")
python3 tools/srs_init.py "$AT" --defaults > /dev/null 2>&1
[ "$(cksum < "$AT/arch/00-elements.md")" = "$before" ] \
    || { echo "FAIL — an upgrade overwrote an element file the project wrote"
         exit 1; }
python3 tools/srs_init.py "$AT" --defaults --arch no > /tmp/arch-no.log 2>&1
grep -qF "does not remove a layer that is already there" /tmp/arch-no.log \
    || { echo "FAIL — --arch no was silently ignored on a target that has one"
         exit 1; }

echo "installer-smoke: the architecture layer is offered, complete and quiet"
