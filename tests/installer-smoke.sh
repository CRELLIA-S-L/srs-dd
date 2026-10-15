#!/usr/bin/env bash
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# tools/srs_init.py: fresh install, upgrade, --dry-run honesty, coexistence
# with a project's own pre-commit hook, and isolation of the payload.
#
# verifies: FR-GND-280, FR-GND-290, FR-GND-300, FR-GND-310, FR-GND-320
# verifies: FR-GND-480
# verifies: FR-INIT-170, FR-INIT-180, FR-INIT-190
set -eo pipefail

# srs-end: FR-GND-280, FR-GND-290, FR-GND-300, FR-GND-310, FR-GND-320, FR-GND-480, FR-INIT-170, FR-INIT-180, FR-INIT-190
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

# srs-end: FR-CI-090
# verifies: FR-INIT-070
# --dry-run must list the whole install and create nothing at all.
python3 tools/srs_init.py /tmp/srs-target --defaults --ci both --dry-run | tee /tmp/dry.log
grep -q "srs-dd/tools/srs_view.py" /tmp/dry.log
grep -q "nothing was written" /tmp/dry.log
test ! -e /tmp/srs-target

# srs-end: FR-INIT-070
# verifies: FR-INIT-010, FR-INIT-020, FR-CI-050
# Fresh install into a temp dir must pass its own checker, strictly.
# The mode was chosen by looking at the target, and nothing told it to.
# `--ci both` lays down the templates for either forge, and what lands is
# theirs rather than this repository's own pipeline — the `.gitlab-ci.yml`
# checked further down is one of the two.
python3 tools/srs_init.py /tmp/srs-target --defaults --ci both | tee /tmp/fresh.log
python3 /tmp/srs-target/srs-dd/tools/srs_check.py --strict

# srs-end: FR-INIT-010, FR-INIT-020, FR-CI-050
# verifies: FR-INIT-150
# It also has to leave the maintainer knowing what to do next: where the
# first requirement goes, what reads and checks the specification, and how
# the framework is upgraded later.
# Read in the steps alone: the list of created files above them names every
# one of these paths too, and a grep over the whole log would pass on it.
grep -q "First steps:" /tmp/fresh.log
sed -n '/First steps:/,$p' /tmp/fresh.log > /tmp/fresh-steps.log
for said in "specs/10-fr-core.md" "srs-dd/tools/srs_check.py" "srs-dd/tools/srs_view.py --html" \
            "srs-dd/tools/srs_upgrade.py" "AGENTS.md"; do
    grep -qF "$said" /tmp/fresh-steps.log \
        || { echo "FAIL FR-INIT-150 — the first steps do not name $said"; cat /tmp/fresh-steps.log; exit 1; }
done
# srs-end: FR-INIT-150
# verifies: FR-SKILL-080, FR-SKILL-100, FR-SKILL-110, FR-SKILL-070, FR-SKILL-630
# verifies: FR-SKILL-640, FR-SKILL-650, FR-SKILL-660
# Every skill that ships is named, and none that does not. The last of
# those is named by its absence: srs-release stays here.
# Read from the installer rather than written here: a list in the suite is
# one more copy that falls behind the tuple it copies.
shipped_skills=$(python3 -c "import sys; sys.dont_write_bytecode = True; sys.path.insert(0, 'tools'); sys.path.insert(0, 'srs-dd/tools'); import srs_init; print(' '.join(srs_init.SKILLS))")
for skill in $shipped_skills; do
    grep -qE "^       $skill +" /tmp/fresh.log \
        || { echo "FAIL FR-SKILL-080, FR-SKILL-100, FR-SKILL-110 — the installer ships $skill and its summary does not name it"
             cat /tmp/fresh.log; exit 1; }
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
agents=$(grep -n "AGENTS.md" /tmp/fresh-steps.log | head -1 | cut -d: -f1)
first=$(grep -nE "^  2\\. Replace the placeholder" /tmp/fresh-steps.log | head -1 | cut -d: -f1)
[ -n "$agents" ] && [ -n "$first" ] && [ "$agents" -lt "$first" ] \
    || { echo "FAIL FR-INIT-150 — the agent procedures do not come before the placeholder step"; cat /tmp/fresh-steps.log; exit 1; }

# srs-end: FR-SKILL-080, FR-SKILL-100, FR-SKILL-110, FR-SKILL-070
# verifies: FR-INIT-270
# Re-running on an initialized target = upgrade mode; srs-dd/ and the
# skills refresh without a flag, the project's files are left alone.
# The stub proves upgrades deliver skill content (the fresh install above
# already wrote the real file — a bare grep would prove nothing).
printf 'stub\n' > /tmp/srs-target/.claude/skills/srs/SKILL.md
printf 'stub\n' > /tmp/srs-target/srs-dd/tools/srs_view.py

# An upgrade dry-run reports the same refresh list and still changes
# nothing — checked byte-for-byte, not by eye.
find /tmp/srs-target -type f | sort | xargs cksum > /tmp/before.dry
python3 tools/srs_init.py /tmp/srs-target --defaults --dry-run > /tmp/upgrade-dry.log
grep -q "srs-dd/tools/srs_view.py" /tmp/upgrade-dry.log
find /tmp/srs-target -type f | sort | xargs cksum > /tmp/after.dry
diff /tmp/before.dry /tmp/after.dry

python3 tools/srs_init.py /tmp/srs-target --defaults | tee /tmp/upgrade.log
grep -q "refreshed:" /tmp/upgrade.log
grep -q "srs-dd/tools/srs_check.py" /tmp/upgrade.log
grep -q "Planning multi-requirement work" /tmp/srs-target/.claude/skills/srs/SKILL.md
grep -q "self-contained HTML site" /tmp/srs-target/srs-dd/tools/srs_view.py
test -f /tmp/srs-target/.gitlab-ci.yml   # a starter, never rewritten

# srs-end: FR-INIT-270
# verifies: FR-INIT-080, FR-INIT-290
# A project's own pre-commit hook is never displaced: nothing is written
# over it or beside it, the installer says what calls the gate from it,
# and the advice must not tell the user to point core.hooksPath at
# .githooks, which would disable what they have.
rm -rf /tmp/srs-hook
mkdir -p /tmp/srs-hook/.githooks
printf '#!/bin/sh\necho theirs\n' > /tmp/srs-hook/.githooks/pre-commit
git -C /tmp/srs-hook init -q .
git -C /tmp/srs-hook config core.hooksPath .githooks
python3 tools/srs_init.py /tmp/srs-hook --defaults --ci none > /tmp/hook.log
grep -q "echo theirs" /tmp/srs-hook/.githooks/pre-commit
if [ -e /tmp/srs-hook/.githooks/pre-commit.srs-dd ]; then
    echo "FAIL FR-INIT-080 — a copy of the gate was laid beside the project's hook"; exit 1
fi
grep -qF "python3 srs-dd/tools/srs_gate.py --staged" /tmp/hook.log \
    || { echo "FAIL FR-INIT-080 — the installer did not say what calls the gate from the project's hook"
         cat /tmp/hook.log; exit 1; }
# Not `grep -qv`: that inverts per line, so on GNU grep it passes whenever
# any line differs — a check that can never fail.
if grep -q "git config core.hooksPath" /tmp/hook.log; then
    echo "must not advise switching hooksPath over an existing hook"
    exit 1
fi

# A hook of theirs somewhere else must not be shadowed either: no hook is
# written at all, and the installer says what to call from theirs.
rm -rf /tmp/srs-hook2 && mkdir -p /tmp/srs-hook2
git -C /tmp/srs-hook2 init -q .
printf '#!/bin/sh\necho mine\n' > /tmp/srs-hook2/.git/hooks/pre-commit
chmod +x /tmp/srs-hook2/.git/hooks/pre-commit
python3 tools/srs_init.py /tmp/srs-hook2 --defaults --ci none > /tmp/hook2.log
grep -q "already runs .git/hooks/pre-commit" /tmp/hook2.log
if [ -e /tmp/srs-hook2/.githooks/pre-commit ]; then
    echo "FAIL FR-INIT-080 — a hook was written although the project runs one of its own"; exit 1
fi
grep -qF "python3 srs-dd/tools/srs_gate.py --staged" /tmp/hook2.log \
    || { echo "FAIL FR-INIT-080 — the installer did not say what calls the gate from the project's hook"
         cat /tmp/hook2.log; exit 1; }

# srs-end: FR-INIT-080, FR-INIT-290
# verifies: FR-INIT-300, FR-INIT-310
# After every install and upgrade the installer says whether git runs a
# pre-commit hook, whether that hook — or the configuration of the manager
# it is a shim for — calls the gate, and whether any GitHub workflow or the
# GitLab file does, giving what to add where not. Each state is a target.
W=/tmp/srs-wiring
rm -rf "$W"
python3 tools/srs_init.py "$W" --defaults --ci github > /tmp/wiring.log
( cd "$W" && git init -q . )
said() {   # said <log> <literal> <requirement> <what>
    grep -qF -- "$2" "$1" || { echo "FAIL $3 — the report does not say: $4"; cat "$1"; exit 1; }
}
unsaid() {
    if grep -qF -- "$2" "$1"; then echo "FAIL $3 — the report wrongly says: $4"; cat "$1"; exit 1; fi
}
wired() { python3 tools/srs_init.py "$W" --defaults > /tmp/wiring.log; }
# Nothing runs yet: the starter is there and waits for the switch.
wired
said /tmp/wiring.log "git runs no pre-commit hook." FR-INIT-300 "that git runs no hook"
said /tmp/wiring.log "git config core.hooksPath .githooks" FR-INIT-300 "how to activate the starter"
said /tmp/wiring.log ".github/workflows/srs.yml calls srs-dd/tools/srs_gate.py." FR-INIT-310 "that the starter workflow calls the gate"
# Switched on: the starter runs and calls the gate.
( cd "$W" && git config core.hooksPath .githooks )
wired
said /tmp/wiring.log "git already runs .githooks/pre-commit on commit." FR-INIT-300 "that git runs the starter"
said /tmp/wiring.log ".githooks/pre-commit calls srs-dd/tools/srs_gate.py." FR-INIT-300 "that the starter calls the gate"
unsaid /tmp/wiring.log "git config core.hooksPath" FR-INIT-300 "to activate what is already active"
# A manager's configuration lying beside the starter git runs is not what
# is read: the hook is.
printf 'repos: []\n' > "$W/.pre-commit-config.yaml"
wired
said /tmp/wiring.log ".githooks/pre-commit calls srs-dd/tools/srs_gate.py." FR-INIT-300 "that the starter git runs is what is read"
unsaid /tmp/wiring.log "managed by" FR-INIT-300 "that a manager runs the hook when the starter does"
rm -f "$W/.pre-commit-config.yaml"
# Their own hook in .git/hooks, without the call and then with it.
( cd "$W" && git config --unset core.hooksPath )
printf '#!/bin/sh\necho mine\n' > "$W/.git/hooks/pre-commit"; chmod +x "$W/.git/hooks/pre-commit"
wired
said /tmp/wiring.log "git already runs .git/hooks/pre-commit on commit." FR-INIT-300 "that git runs their hook"
said /tmp/wiring.log ".git/hooks/pre-commit does not call srs-dd/tools/srs_gate.py. Add to it:" FR-INIT-300 "that their hook lacks the call"
said /tmp/wiring.log "python3 srs-dd/tools/srs_gate.py --staged" FR-INIT-300 "the line to add"
said /tmp/wiring.log "no hook was written" FR-INIT-080 "that nothing displaced their hook"
printf 'python3 srs-dd/tools/srs_gate.py --staged\n' >> "$W/.git/hooks/pre-commit"
wired
said /tmp/wiring.log ".git/hooks/pre-commit calls srs-dd/tools/srs_gate.py." FR-INIT-300 "that their hook now calls the gate"
rm -f "$W/.git/hooks/pre-commit"
# husky: git runs the shim under .husky/_, and .husky/pre-commit is what is read.
mkdir -p "$W/.husky/_"; printf '#!/bin/sh\n. "$(dirname "$0")/h"\n' > "$W/.husky/_/pre-commit"
printf 'npm test\n' > "$W/.husky/pre-commit"
( cd "$W" && git config core.hooksPath .husky/_ )
wired
said /tmp/wiring.log "managed by husky (.husky/pre-commit)" FR-INIT-300 "that husky manages the hook"
said /tmp/wiring.log ".husky/pre-commit does not call srs-dd/tools/srs_gate.py. Add to it:" FR-INIT-300 "that husky's hook lacks the call"
printf 'python3 srs-dd/tools/srs_gate.py --staged\n' >> "$W/.husky/pre-commit"
wired
said /tmp/wiring.log ".husky/pre-commit calls srs-dd/tools/srs_gate.py." FR-INIT-300 "that husky's hook now calls the gate"
# husky without a pre-commit hook yet: the place to add it is named, not the shim.
rm -f "$W/.husky/pre-commit"
wired
said /tmp/wiring.log ".husky/pre-commit does not call srs-dd/tools/srs_gate.py. Add to it:" FR-INIT-300 "where husky's hook goes when there is none yet"
unsaid /tmp/wiring.log ".husky/_/pre-commit does not call" FR-INIT-300 "to edit husky's generated shim"
rm -rf "$W/.husky"; ( cd "$W" && git config --unset core.hooksPath )
# The pre-commit framework: configured, not installed, and its configuration is read.
printf 'repos: []\n' > "$W/.pre-commit-config.yaml"
wired
said /tmp/wiring.log "the pre-commit framework (.pre-commit-config.yaml) is configured but not installed here — run: pre-commit install" FR-INIT-300 "that the framework is not installed"
said /tmp/wiring.log ".pre-commit-config.yaml does not call srs-dd/tools/srs_gate.py. Add to its repos: list:" FR-INIT-300 "that the configuration lacks the call"
said /tmp/wiring.log "entry: python3 srs-dd/tools/srs_gate.py --staged" FR-INIT-300 "the local hook to add"
printf -- '- repo: local\n  hooks:\n  - id: srs-gate\n    entry: python3 srs-dd/tools/srs_gate.py --staged\n' > "$W/.pre-commit-config.yaml"
printf '#!/bin/sh\nexec pre-commit run\n' > "$W/.git/hooks/pre-commit"; chmod +x "$W/.git/hooks/pre-commit"
wired
said /tmp/wiring.log "git already runs .git/hooks/pre-commit on commit, managed by the pre-commit framework" FR-INIT-300 "that the framework's shim runs"
said /tmp/wiring.log ".pre-commit-config.yaml calls srs-dd/tools/srs_gate.py." FR-INIT-300 "that the configuration calls the gate"
rm -f "$W/.pre-commit-config.yaml" "$W/.git/hooks/pre-commit"
# lefthook, by its configuration file.
printf 'pre-commit:\n  commands: {}\n' > "$W/lefthook.yml"
wired
said /tmp/wiring.log "lefthook (lefthook.yml) is configured but not installed here — run: lefthook install" FR-INIT-300 "that lefthook is not installed"
said /tmp/wiring.log "run: python3 srs-dd/tools/srs_gate.py --staged" FR-INIT-300 "the lefthook command to add"
rm -f "$W/lefthook.yml"
# Pipelines: a second workflow without the call changes nothing; the GitLab
# file without it is named with its job; with no pipeline at all, the report
# says so and leaves a service it does not know to the reader.
printf 'on: push\njobs: {}\n' > "$W/.github/workflows/release.yml"
printf 'stages: [test]\n' > "$W/.gitlab-ci.yml"
wired
said /tmp/wiring.log ".github/workflows/srs.yml calls srs-dd/tools/srs_gate.py." FR-INIT-310 "that one workflow calls the gate"
unsaid /tmp/wiring.log "no workflow under .github/workflows/ calls" FR-INIT-310 "that no workflow calls it while one does"
said /tmp/wiring.log ".gitlab-ci.yml does not call srs-dd/tools/srs_gate.py. Add a job:" FR-INIT-310 "that the GitLab file lacks the call"
said /tmp/wiring.log "- python3 srs-dd/tools/srs_gate.py" FR-INIT-310 "the job's script line"
printf 'srs-gate:\n  script:\n    - python3 srs-dd/tools/srs_gate.py\n' > "$W/.gitlab-ci.yml"
rm -f "$W/.github/workflows/srs.yml"
wired
said /tmp/wiring.log ".gitlab-ci.yml calls srs-dd/tools/srs_gate.py." FR-INIT-310 "that the GitLab file now calls the gate"
said /tmp/wiring.log "no workflow under .github/workflows/ calls srs-dd/tools/srs_gate.py. Add a step" FR-INIT-310 "that no workflow calls it once the starter is gone"
said /tmp/wiring.log "- run: python3 srs-dd/tools/srs_gate.py" FR-INIT-310 "the step to add"
rm -rf "$W/.github" "$W/.gitlab-ci.yml"
wired
said /tmp/wiring.log "no pipeline for GitHub or GitLab was found" FR-INIT-310 "that no pipeline was found"
rm -rf "$W"
echo "installer-smoke: the report says whether the hook and a pipeline run the gate, for every way of running them"

# srs-end: FR-INIT-300, FR-INIT-310
# Whatever a maintainer generates under skeleton/specs/ in their clone
# must not travel into targets as skeleton content.
printf 'stray\n' > skeleton/specs/stray.html
rm -rf /tmp/srs-clean
# With the register and with both pipelines, because this target is what the
# leak check and the annotation check below walk, and they see only what is
# installed. Without the register they never saw srs-dd/tools/srs_grounds.py or
# srs-dd/grounds.md, so the whole register payload shipped unexamined — and
# did ship a citation of this framework's own requirements. Without a CI
# config the same hole stood open at ci/: those templates become a target's
# pipeline and hook, and nothing looked at them on the way. Declining either
# is asserted on targets of its own further down.
rc=0; python3 tools/srs_init.py /tmp/srs-clean --defaults --ci both \
      --grounds yes --arch yes >/dev/null || rc=$?
rm -f skeleton/specs/stray.html
test "$rc" -eq 0
test ! -e /tmp/srs-clean/specs/stray.html

# verifies: FR-INIT-280
# What stays the framework's says whose it is: every tool, skill and standard
# installed carries the notice, and what becomes the project's — the hook,
# the pipelines, the guides, the specification, the decision template —
# carries none, because a line of ours there would claim their file.
NOTICE="Copyright (c) 2026 CRELLIA S.L."
carrying=0
for f in /tmp/srs-clean/srs-dd/tools/*.py /tmp/srs-clean/.claude/skills/*/SKILL.md \
         /tmp/srs-clean/srs-dd/standard.md /tmp/srs-clean/srs-dd/grounds.md /tmp/srs-clean/srs-dd/arch.md \
         /tmp/srs-clean/srs-dd/method.md /tmp/srs-clean/srs-dd/README.md /tmp/srs-clean/srs-dd/LICENSE; do
    grep -qF "$NOTICE" "$f" && grep -q "MIT License" "$f" \
        || { echo "FAIL FR-INIT-280 — $f carries no notice of the copyright holder and the licence"; exit 1; }
    carrying=$((carrying + 1))
done
[ "$carrying" -ge 25 ] || { echo "FAIL FR-INIT-280 — only $carrying shipped files were looked at; the tuples shrank"; exit 1; }
# verifies: FR-INIT-390
# A project's principles are a file the project creates: the installer writes
# none, so no article of ours takes a number in the project's space.
if [ -e /tmp/srs-clean/specs/constitution.md ]; then
    echo "FAIL FR-INIT-390 — the installer wrote specs/constitution.md; a project writes its own"; exit 1
fi
# srs-end: FR-INIT-390

# The guide's source stays the framework's and carries none, deliberately:
# its text is written into the region of the project's own AGENTS.md, where
# a line of ours would claim their document.
if grep -qF "$NOTICE" /tmp/srs-clean/srs-dd/guide.md; then
    echo "FAIL FR-INIT-280 — srs-dd/guide.md carries a notice; its text goes into the project's AGENTS.md"; exit 1
fi
for f in .githooks/pre-commit .github/workflows/srs.yml .gitlab-ci.yml AGENTS.md CLAUDE.md .gitattributes \
         specs/adr/template.md specs/00-glossary.md specs/10-fr-core.md; do
    if grep -qF "$NOTICE" "/tmp/srs-clean/$f"; then
        echo "FAIL FR-INIT-280 — $f becomes the project's own and must carry no notice of ours"; exit 1
    fi
done
echo "installer-smoke: the tools, skills and standards installed say whose they are; the project's own files do not"
# srs-end: FR-INIT-280

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
    python3 srs-dd/tools/srs_check.py --no-write 2>&1 | grep -q "no row for baseline tag spec/v0.1.0"
    rc=0; python3 srs-dd/tools/srs_check.py --no-write --strict >/dev/null 2>&1 || rc=$?
    test "$rc" -eq 1
    python3 - <<'PY2'
path = 'specs/92-baselines.md'
text = open(path, encoding='utf-8').read()
open(path, 'w', encoding='utf-8').write(text.replace(
    '*No baselines yet.*',
    '| 0.1.0 | 2026-01-01 | `spec/v0.1.0` | First freeze. |'))
PY2
    python3 srs-dd/tools/srs_check.py --no-write --strict >/dev/null
)

# srs-end: FR-CHK-130
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

# srs-end: FR-CHK-210
# verifies: FR-INIT-320
# Everything the framework owns is under srs-dd/, nothing of it elsewhere:
# the tools, the standards of the specification and of both layers, the
# method's articles, the framework's guide, the licence and the README that
# carries the marker — and no tools/, no README under specs/, grounds/ or
# arch/.
PT=/tmp/srs-precious
rm -rf "$PT" /tmp/srs-pristine
python3 tools/srs_init.py "$PT" --defaults --name "Acme Widgets" \
    --line-width 100 --ci github --grounds yes --arch yes >/dev/null
cp -R "$PT" /tmp/srs-pristine
for f in tools/srs_check.py tools/srs_parse.py tools/srs_view.py tools/srs_view_model.py \
         tools/srs_view_page.py tools/srs_upgrade.py tools/srs_baseline.py \
         tools/srs_dates.py tools/srs_gate.py tools/srs_grounds.py tools/srs_arch.py \
         standard.md grounds.md arch.md method.md guide.md LICENSE README.md; do
    test -f "$PT/srs-dd/$f" || { echo "FAIL FR-INIT-320 — srs-dd/$f was not installed"; exit 1; }
done
grep -q "SRS-DD-" "$PT/srs-dd/README.md" || { echo "FAIL FR-INIT-320 — srs-dd/README.md carries no marker"; exit 1; }
for f in tools specs/README.md grounds/README.md arch/README.md; do
    if [ -e "$PT/$f" ]; then echo "FAIL FR-INIT-320 — $f was written outside srs-dd/"; exit 1; fi
done
# Without the layers, their standards and tools stay home with them.
rm -rf /tmp/srs-bare
python3 tools/srs_init.py /tmp/srs-bare --defaults --ci none >/dev/null
for f in grounds.md arch.md tools/srs_grounds.py tools/srs_arch.py; do
    if [ -e "/tmp/srs-bare/srs-dd/$f" ]; then echo "FAIL FR-INIT-320 — srs-dd/$f was installed without its layer"; exit 1; fi
done
test -f /tmp/srs-bare/srs-dd/method.md && test -f /tmp/srs-bare/srs-dd/guide.md \
    || { echo "FAIL FR-INIT-320 — the method and the guide did not reach a project without layers"; exit 1; }
echo "installer-smoke: everything of the framework's is under srs-dd/, and nothing else is"

# srs-end: FR-INIT-320
# verifies: FR-INIT-330
rm -rf /tmp/srs-foreign && mkdir -p /tmp/srs-foreign/srs-dd
printf 'theirs\n' > /tmp/srs-foreign/srs-dd/README.md
rc=0; python3 tools/srs_init.py /tmp/srs-foreign --defaults --areas APP --ci none > /tmp/foreign.log 2>&1 || rc=$?
[ "$rc" = 2 ] || { echo "FAIL FR-INIT-330 — a srs-dd/ that is not ours was not refused (exit $rc)"; cat /tmp/foreign.log; exit 1; }
[ "$(ls /tmp/srs-foreign)" = "srs-dd" ] && grep -q "^theirs$" /tmp/srs-foreign/srs-dd/README.md \
    || { echo "FAIL FR-INIT-330 — the refusal wrote something"; ls -R /tmp/srs-foreign; exit 1; }
grep -q "carries no marker" /tmp/foreign.log || { echo "FAIL FR-INIT-330 — the refusal does not say why"; cat /tmp/foreign.log; exit 1; }
# Ours — marked — is upgraded, not refused.
rc=0; python3 tools/srs_init.py "$PT" --defaults > /dev/null 2>&1 || rc=$?
[ "$rc" = 0 ] || { echo "FAIL FR-INIT-330 — our own srs-dd/ was refused"; exit 1; }
# What a crashed adopt leaves — the directory with nothing but its temporary
# checker — is ours too: the next adopt removes the file and carries on.
rm -rf /tmp/srs-leftover && mkdir -p /tmp/srs-leftover/srs-dd/tools /tmp/srs-leftover/specs
printf 'crashed\n' > /tmp/srs-leftover/srs-dd/tools/.srs_check_adopt.py
printf '### FR-APP-010 — Starts\n\n```yaml\nstatus: deferred\nverification: I\nderives_from: []\ndepends_on: []\n' \
    > /tmp/srs-leftover/specs/10-fr-app.md
printf 'refines: []\nconflicts_with: []\ncode: []\ntests: []\ncreated: 2026-01-01\n```\n\nThe app **shall** start.\n' \
    >> /tmp/srs-leftover/specs/10-fr-app.md
rc=0; python3 tools/srs_init.py /tmp/srs-leftover --defaults --areas APP --ci none > /tmp/leftover.log 2>&1 || rc=$?
[ "$rc" = 0 ] || { echo "FAIL FR-INIT-330 — a crashed adopt's leftover was refused as a foreign directory (exit $rc)"
                   cat /tmp/leftover.log; exit 1; }
test -f /tmp/srs-leftover/srs-dd/README.md || { echo "FAIL FR-INIT-330 — adopt over the leftover installed no directory"; exit 1; }
if [ -e /tmp/srs-leftover/srs-dd/tools/.srs_check_adopt.py ]; then
    echo "FAIL FR-INIT-330 — the crashed adopt's checker was left in place"; exit 1
fi

# srs-end: FR-INIT-330
# verifies: FR-INIT-380
# A path somebody else put under the framework's directory is named in the
# run and left where it is: the directory is declared ours, so a file of
# theirs in it stays for ever unless somebody is told about it, and
# deleting it is what SRS-DD-ART-030 reserves for the user's word.
rm -rf /tmp/srs-foreign
python3 tools/srs_init.py /tmp/srs-foreign --defaults --area CORE --grounds no --arch no --ci none \
    > /tmp/foreign-install.log
printf 'mine\n' > /tmp/srs-foreign/srs-dd/notes-of-mine.md
printf 'print(1)\n' > /tmp/srs-foreign/srs-dd/tools/mytool.py
python3 tools/srs_init.py /tmp/srs-foreign --defaults > /tmp/foreign.log
for rel in srs-dd/notes-of-mine.md srs-dd/tools/mytool.py; do
    grep -qF "$rel" /tmp/foreign.log \
        || { echo "FAIL FR-INIT-380 — $rel was not named in the run"; cat /tmp/foreign.log; exit 1; }
    test -f "/tmp/srs-foreign/$rel" \
        || { echo "FAIL FR-INIT-380 — $rel was deleted; the run reports and never deletes"; exit 1; }
done
grep -q "are not the framework's" /tmp/foreign.log \
    || { echo "FAIL FR-INIT-380 — the run does not say what the list is"; cat /tmp/foreign.log; exit 1; }
# A directory holding nothing but ours says nothing.
if grep -q "are not the framework's" /tmp/foreign-install.log; then
    echo "FAIL FR-INIT-380 — a fresh install reported a foreign path where there is none"; exit 1
fi
rm -rf /tmp/srs-foreign

# srs-end: FR-INIT-380
# verifies: FR-INIT-340
# A project installed before the directory: the tools under tools/ and the
# standards beside what they govern, each with the marker. The upgrade moves
# them, deletes the copies, and the dry run only lists the move.
OLD=/tmp/srs-oldlayout
rm -rf "$OLD"; cp -R /tmp/srs-pristine "$OLD"
( cd "$OLD" && mkdir -p tools && mv srs-dd/tools/*.py tools/ && mv srs-dd/standard.md specs/README.md \
  && mv srs-dd/grounds.md grounds/README.md && mv srs-dd/arch.md arch/README.md && rm -rf srs-dd )
printf '# mine\n' > "$OLD/tools/mine.py"     # a tool of the project's, no marker
python3 tools/srs_init.py "$OLD" --defaults --dry-run > /tmp/old-dry.log
grep -q "tools/srs_check.py -> srs-dd/tools/srs_check.py" /tmp/old-dry.log \
    || { echo "FAIL FR-INIT-340 — the dry run does not list the move"; cat /tmp/old-dry.log; exit 1; }
test -f "$OLD/tools/srs_check.py" && test -f "$OLD/specs/README.md" \
    || { echo "FAIL FR-INIT-340 — the dry run moved files"; exit 1; }
python3 tools/srs_init.py "$OLD" --defaults > /tmp/old-up.log
for f in tools/srs_check.py tools/srs_grounds.py specs/README.md grounds/README.md arch/README.md; do
    if [ -e "$OLD/$f" ]; then echo "FAIL FR-INIT-340 — $f was left behind after the move"; exit 1; fi
done
for f in tools/srs_check.py tools/srs_grounds.py standard.md grounds.md arch.md; do
    test -f "$OLD/srs-dd/$f" || { echo "FAIL FR-INIT-340 — srs-dd/$f is missing after the move"; exit 1; }
done
test -f "$OLD/tools/mine.py" || { echo "FAIL FR-INIT-340 — the project's own tool was removed"; exit 1; }
grep -q "the framework's files now live under srs-dd/" /tmp/old-up.log \
    || { echo "FAIL FR-INIT-340 — the report does not say where the files went"; cat /tmp/old-up.log; exit 1; }
# A README of the project's own under specs/ carries no marker and stays.
rm -rf "$OLD"; cp -R /tmp/srs-pristine "$OLD"; printf '# ours\n' > "$OLD/specs/README.md"
python3 tools/srs_init.py "$OLD" --defaults > /dev/null
grep -q "^# ours$" "$OLD/specs/README.md" || { echo "FAIL FR-INIT-340 — a README of the project's was taken for the standard"; exit 1; }
rm -rf "$OLD"

# srs-end: FR-INIT-340
# verifies: FR-INIT-350
for area in ADR ARCHIVE; do
    rm -rf /tmp/srs-badarea
    rc=0; python3 tools/srs_init.py /tmp/srs-badarea --defaults --areas "$area" --ci none > /tmp/badarea.log 2>&1 || rc=$?
    [ "$rc" = 2 ] && grep -q "is one the checker skips" /tmp/badarea.log \
        || { echo "FAIL FR-INIT-350 — area $area was not refused (exit $rc)"; cat /tmp/badarea.log; exit 1; }
    test ! -e /tmp/srs-badarea || { echo "FAIL FR-INIT-350 — the refusal wrote the target"; exit 1; }
done

# srs-end: FR-INIT-350
# verifies: FR-INIT-360, FR-INIT-370, FR-INIT-200, FR-SKILL-440
# The guides and .gitattributes are the project's: an edit outside the
# region survives every upgrade, the region alone is rewritten, and a guide
# without the region is reported with what to add.
for rel in AGENTS.md CLAUDE.md .gitattributes; do
    printf 'theirs, edited\n' >> "$PT/$rel"
done
python3 tools/srs_init.py "$PT" --defaults > /tmp/starter-guides.log
for rel in AGENTS.md CLAUDE.md .gitattributes; do
    grep -qF 'theirs, edited' "$PT/$rel" || { echo "FAIL FR-INIT-360 — $rel was rewritten by an upgrade"; exit 1; }
    grep -qF "$rel (the project's file — never rewritten)" /tmp/starter-guides.log \
        || { echo "FAIL FR-INIT-360 — $rel was not reported as the project's"; cat /tmp/starter-guides.log; exit 1; }
done
# The region: altered inside, it is put back from srs-dd/guide.md; the text around it stays.
python3 - "$PT/AGENTS.md" <<'PY2'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
b, e = s.index('<!-- srs-dd -->'), s.index('<!-- /srs-dd -->')
open(p, 'w', encoding='utf-8').write(s[:b] + '<!-- srs-dd -->\nstale rules\n' + s[e:])
PY2
python3 tools/srs_init.py "$PT" --defaults --dry-run > /tmp/region-dry.log
grep -qF "AGENTS.md (the region" /tmp/region-dry.log || { echo "FAIL FR-INIT-370 — the dry run does not list the region"; cat /tmp/region-dry.log; exit 1; }
grep -q "^stale rules$" "$PT/AGENTS.md" || { echo "FAIL FR-INIT-370 — the dry run rewrote the region"; exit 1; }
python3 tools/srs_init.py "$PT" --defaults > /tmp/region.log
if grep -q "^stale rules$" "$PT/AGENTS.md"; then echo "FAIL FR-INIT-370 — the region was not refreshed"; exit 1; fi
grep -qF 'theirs, edited' "$PT/AGENTS.md" && grep -q "Acme Widgets" "$PT/AGENTS.md" \
    || { echo "FAIL FR-INIT-370 — text outside the region was lost"; exit 1; }
python3 - "$PT/AGENTS.md" srs-dd/guide.md <<'PY2'
import sys
s = open(sys.argv[1], encoding='utf-8').read(); g = open(sys.argv[2], encoding='utf-8').read()
body = g.strip('\n')
b, e = s.index('<!-- srs-dd -->') + len('<!-- srs-dd -->'), s.index('<!-- /srs-dd -->')
assert s[b:e].strip('\n') == body, 'FAIL FR-INIT-370 — the refreshed region is not srs-dd/guide.md'
PY2
# No region at all: reported, and nothing in the file touched.
python3 - "$PT/AGENTS.md" <<'PY2'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
open(p, 'w', encoding='utf-8').write(s.replace('<!-- srs-dd -->', '').replace('<!-- /srs-dd -->', ''))
PY2
before=$(cksum < "$PT/AGENTS.md")
python3 tools/srs_init.py "$PT" --defaults > /tmp/noregion.log
grep -q "AGENTS.md carries no region" /tmp/noregion.log || { echo "FAIL FR-INIT-370 — a guide without the region was not reported"; cat /tmp/noregion.log; exit 1; }
[ "$(cksum < "$PT/AGENTS.md")" = "$before" ] || { echo "FAIL FR-INIT-370 — a guide without the region was rewritten"; exit 1; }
# A guide written by an upgrade — the file was absent — is filled with the
# recorded name and width (FR-INIT-200), and the directory stands in for a
# name that was never recorded.
rm -f "$PT/AGENTS.md"
python3 tools/srs_init.py "$PT" --defaults > /tmp/guide-back.log
grep -qF 'Acme Widgets' "$PT/AGENTS.md" && grep -qF '100 columns' "$PT/AGENTS.md" \
    || { echo "FAIL FR-INIT-200 — the guide an upgrade wrote is not filled from the configuration"; exit 1; }
absent '<Your Project Name>' "$PT/AGENTS.md"
absent '<SRS-DD-WIDTH-LINE>' "$PT/AGENTS.md"
python3 - "$PT/specs/srs-config.json" <<'PY2'
import json, sys
path = sys.argv[1]
with open(path, encoding='utf-8') as handle:
    data = json.load(handle)
data.pop('project_name', None)
with open(path, 'w', encoding='utf-8') as handle:
    json.dump(data, handle, indent=2)
PY2
rm -f "$PT/AGENTS.md"
python3 tools/srs_init.py "$PT" --defaults > /tmp/guide-noname.log
grep -qF 'srs-precious' "$PT/AGENTS.md" || { echo "FAIL FR-INIT-200 — with no recorded name the directory did not stand in"; exit 1; }
# A marker written into a sentence is not a border: the note this run
# prints asks for two lines, and a guide that pasted that sentence in must
# still have its own region found, not the prose.
python3 - "$PT/AGENTS.md" <<'PY2'
import io, sys
io.open(sys.argv[1], "w", encoding="utf-8").write(
    "# Theirs\n\nAdd `<!-- srs-dd -->` and `<!-- /srs-dd -->` where the rules go.\n\n"
    "<!-- srs-dd -->\nstale\n<!-- /srs-dd -->\n\nbelow\n")
PY2
python3 tools/srs_init.py "$PT" --defaults > /tmp/region-prose.log
python3 - "$PT/AGENTS.md" srs-dd/guide.md <<'PY2'
import io, sys
text = io.open(sys.argv[1], encoding="utf-8").read()
guide = io.open(sys.argv[2], encoding="utf-8").read().strip("\n")
assert "Add `<!-- srs-dd -->` and `<!-- /srs-dd -->` where the rules go." in text, \
    "FAIL FR-INIT-370 — the sentence naming the markers was taken for the region"
assert text.count(guide) == 1, \
    "FAIL FR-INIT-370 — the guide did not land in the region exactly once"
assert text.endswith("below\n"), "FAIL FR-INIT-370 — text below the region was lost"
PY2
# A guide whose endings are CRLF: the region is filled and every line
# outside it keeps the ending it had. Read through the universal newline
# translation the whole file comes back as LF, which is a rewrite of every
# line the statement says to leave alone.
python3 - "$PT/AGENTS.md" <<'PY2'
import io, sys
body = ("# Theirs\n\nabove\n\n<!-- srs-dd -->\nstale\n<!-- /srs-dd -->\n\nbelow\n")
io.open(sys.argv[1], "w", encoding="utf-8", newline="").write(body.replace("\n", "\r\n"))
PY2
python3 tools/srs_init.py "$PT" --defaults > /tmp/region-crlf.log
python3 - "$PT/AGENTS.md" srs-dd/guide.md <<'PY2'
import io, sys
raw = io.open(sys.argv[1], "rb").read()
guide = io.open(sys.argv[2], encoding="utf-8").read().strip("\n")
bare = raw.count(b"\n") - raw.count(b"\r\n")
assert bare == 0, "FAIL FR-INIT-370 — a CRLF guide came back with %d LF-only lines" % bare
text = raw.decode("utf-8").replace("\r\n", "\n")
begin = text.index("<!-- srs-dd -->") + len("<!-- srs-dd -->")
end = text.index("<!-- /srs-dd -->")
assert text[begin:end].strip("\n") == guide, \
    "FAIL FR-INIT-370 — the region of a CRLF guide is not srs-dd/guide.md"
assert "above" in text and "below" in text, \
    "FAIL FR-INIT-370 — text outside the region of a CRLF guide was lost"
PY2
cp /tmp/srs-pristine/specs/srs-config.json "$PT/specs/srs-config.json"
cp /tmp/srs-pristine/AGENTS.md "$PT/AGENTS.md"; cp /tmp/srs-pristine/CLAUDE.md "$PT/CLAUDE.md"; cp /tmp/srs-pristine/.gitattributes "$PT/.gitattributes"
echo "installer-smoke: the guides and .gitattributes are the project's, and the region is the framework's"

# srs-end: FR-INIT-360, FR-INIT-370, FR-INIT-200, FR-SKILL-440
# verifies: FR-INIT-290
# The hook and the pipelines are the project's files: a starter is written
# where the file is absent and never again — edited, marked, or
# not — and a --dry-run lists it under skipped, not refreshed.
for rel in .github/workflows/srs.yml .githooks/pre-commit; do
    printf 'theirs, edited\n' >> "$PT/$rel"
    python3 tools/srs_init.py "$PT" --defaults --ci github > /tmp/starter-force.log
    grep -qF 'theirs, edited' "$PT/$rel" \
        || { echo "FAIL FR-INIT-290 — $rel was rewritten under"; exit 1; }
    grep -qF "$rel (the project's file — never rewritten)" /tmp/starter-force.log \
        || { echo "FAIL FR-INIT-290 — $rel was not reported as never rewritten"; cat /tmp/starter-force.log; exit 1; }
    python3 tools/srs_init.py "$PT" --defaults --ci github --dry-run > /tmp/starter-dry.log
    if grep -qE "^  $rel\$" /tmp/starter-dry.log; then
        echo "FAIL FR-INIT-290 — a dry run listed $rel as refreshed"; exit 1
    fi
    cp "/tmp/srs-pristine/$rel" "$PT/$rel"
done
# Absent, a starter is written — the hook on every upgrade, a pipeline only
# where this run asked for that service.
rm -f "$PT/.githooks/pre-commit"
python3 tools/srs_init.py "$PT" --defaults --ci gitlab > /tmp/starter-absent.log
for rel in .githooks/pre-commit .gitlab-ci.yml; do
    test -f "$PT/$rel" || { echo "FAIL FR-INIT-290 — an upgrade did not write the absent starter $rel"; cat /tmp/starter-absent.log; exit 1; }
    grep -q "SRS-DD" "$PT/$rel" || { echo "FAIL FR-INIT-290 — the starter $rel written is not ours"; exit 1; }
done
printf 'theirs, edited\n' >> "$PT/.gitlab-ci.yml"
python3 tools/srs_init.py "$PT" --defaults --ci gitlab > /dev/null
grep -qF 'theirs, edited' "$PT/.gitlab-ci.yml" \
    || { echo "FAIL FR-INIT-290 — .gitlab-ci.yml was rewritten under"; exit 1; }
rm -f "$PT/.gitlab-ci.yml"
# srs-end: FR-INIT-290
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

# A target nothing can be written into is a refusal before anything changed,
# which is exit 2. Until the guard it was a PermissionError traceback out of
# the first directory of the payload and exit 1 — the code reserved for a
# checker error in the target — found by running the installer at a path on a
# read-only filesystem. Root can write into a directory with no write bit, so
# there the case cannot be staged and says so.
if [ "$(id -u)" -eq 0 ]; then
    echo "installer-smoke: running as root, the unwritable-target case cannot be staged"
else
    ro=/tmp/srs-unwritable
    rm -rf "$ro"; mkdir -p "$ro"; chmod 500 "$ro"
    rc=0; python3 tools/srs_init.py "$ro" --defaults </dev/null \
        > /tmp/srs-unwritable.log 2>&1 || rc=$?
    chmod 700 "$ro"; rm -rf "$ro"
    test "$rc" -eq 2 \
        || { echo "FAIL IF-CI-010 — an unwritable target gave exit $rc, not 2"; cat /tmp/srs-unwritable.log; exit 1; }
    grep -q "the target must be a writable directory" /tmp/srs-unwritable.log \
        || { echo "FAIL IF-CI-010 — an unwritable target was not refused in words"; cat /tmp/srs-unwritable.log; exit 1; }
    if grep -q "Traceback" /tmp/srs-unwritable.log; then
        echo "FAIL IF-CI-010 — an unwritable target produced a traceback instead of a refusal"
        cat /tmp/srs-unwritable.log; exit 1
    fi
fi

# srs-end: IF-CI-010
# verifies: CON-SPEC-020, FR-INIT-260
# specs/ here is the framework's own specification, not payload (ART-070).
# A fresh target must hold exactly one requirement — the generated
# placeholder — and nothing of ours. Asked through the parser rather than
# grep: the standard itself carries example identifiers in prose.
python3 /tmp/srs-clean/srs-dd/tools/srs_view.py --json /tmp/target.json >/dev/null
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
    # inside the record examples that show the format, and srs-dd/standard.md
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
# A decision's number leaks the same way: `ADR-0009` in a shipped comment
# is the project's own ninth decision, or nothing. The installer takes them
# out of the tooling (FR-INIT-260); anywhere else they must not be written.
DECISION = re.compile(r'\bADR-\d{4}\b')
cited = []
for root, dirs, files in os.walk(target):
    dirs[:] = [d for d in dirs if d != '.git']
    for name in sorted(files):
        path = os.path.join(root, name)
        try:
            text = open(path, encoding='utf-8').read()
        except (OSError, UnicodeDecodeError):
            continue
        cited += ['%s %s' % (os.path.relpath(path, target), n) for n in DECISION.findall(text)]
assert not cited, 'something the installer shipped cites a decision of this framework: %s' % cited
PY

# srs-end: CON-SPEC-020, FR-INIT-260
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

# srs-end: FR-INIT-210, FR-INIT-220
# verifies: FR-INIT-180, FR-INIT-190
# An annotation is removed, not deleted: the line stays a line, so a
# traceback from a target names what it names here. Asserted per file
# rather than in total, because one tool losing its length is how this
# breaks and a sum would hide it.
python3 - <<'PY3'
import os
import re
for name in sorted(os.listdir('/tmp/srs-clean/srs-dd/tools')):
    if not name.endswith('.py'):
        continue
    mine = open(os.path.join('srs-dd', 'tools', name), encoding='utf-8').read()
    theirs = open(os.path.join('/tmp/srs-clean/srs-dd/tools', name),
                  encoding='utf-8').read()
    assert mine.count(chr(10)) == theirs.count(chr(10)), (
        '%s: %d lines here, %d in the target — a removed annotation took '
        'its line with it' % (name, mine.count(chr(10)),
                              theirs.count(chr(10))))
    header = theirs.split('"""')[0]
    # The source reads SRS-DD-VERSION; only a stamped number proves the
    # installer stamped it.
    assert re.search(r'SRS-DD-\d+\.\d+\.\d+', header), '%s: no version stamp in the header' % name
PY3

# The example annotations are what a target reads the format from, so they
# survive — and `srs-ignore` is what says they are examples rather than
# claims.
grep -q 'implements: FR-CORE-010' /tmp/srs-clean/srs-dd/tools/srs_check.py  # srs-ignore
# End markers name this framework's requirements as annotations do, and go
# the same way: none reaches a target's tooling.
if grep -n -E 'srs-end: *[A-Z]+-[A-Z0-9]+-[0-9]' /tmp/srs-clean/srs-dd/tools/*.py | grep -v 'srs-ignore'; then
    echo "FAIL FR-INIT-180 — an end marker naming a requirement of ours reached the target"; exit 1
fi

# srs-end: FR-INIT-180, FR-INIT-190
# --- verifies: FR-GND-280, FR-GND-290, FR-GND-300, FR-GND-310, FR-GND-320
# --- The grounds register: offered, never imposed, and complete or absent.
GT=/tmp/srs-grounds-target
rm -rf "$GT"
python3 tools/srs_init.py "$GT" --defaults --areas APP --ci github \
    --grounds yes > /tmp/grounds-fresh.log 2>&1

# All of it or none of it: the standard, the starter files, the checker and
# the procedure only make sense together.
for f in srs-dd/grounds.md grounds/grounds-config.json grounds/00-ideology.md \
         grounds/01-frames.md grounds/02-unclaimed.md grounds/03-bets.md \
         srs-dd/tools/srs_grounds.py .claude/skills/srs-bet/SKILL.md; do
    [ -f "$GT/$f" ] || { echo "FAIL FR-GND-280/320 — $f did not travel"; exit 1; }
done

# What was installed passes the target's own checker strictly, so a project's
# first red run means something the project did.
( cd "$GT" && python3 srs-dd/tools/srs_grounds.py --no-write --strict ) \
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
for f in grounds srs-dd/tools/srs_grounds.py .claude/skills/srs-bet; do
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
# rc is captured with ||, not read after the command: under set -e a bare
# failing command ends the suite before rc=$? runs, and the message below —
# which says what went wrong — would never print.
rc=0
# The dashboard is regenerated before anything is staged: the hook refuses
# a commit whose dashboard is not the checker's (FR-GND-570), and this
# fixture asks about the report, not that.
( cd "$GT" && git init -q . && python3 srs-dd/tools/srs_grounds.py > /dev/null && git add -A \
  && sh .githooks/pre-commit ) > /tmp/grounds-hook.log 2>&1 || rc=$?
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
( cd "$GT" && python3 srs-dd/tools/srs_check.py >/dev/null \
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
( cd "$GT" && python3 srs-dd/tools/srs_grounds.py --no-write 2>&1 | grep -q "^warning:" ) \
    || { echo "FAIL — the fixture register does not warn, so the next"
         echo "assertion would hold for any register at all"; exit 1; }
python3 tools/srs_init.py "$GT" --defaults > /tmp/grounds-warn.log 2>&1 \
    || { echo "FAIL FR-GND-290 — an upgrade failed over a warning in the"
         echo "register"; tail -5 /tmp/grounds-warn.log; exit 1; }

# And nothing an upgrade does overwrites what the project authored. The
# standard is refreshed; the records are the project's.
printf '\n### F-010 — Ours\n\n```yaml\nstatus: active\n```\n\nWe do not sell attention.\n' \
    >> "$GT/grounds/01-frames.md"
before=$(cksum < "$GT/grounds/01-frames.md")
python3 tools/srs_init.py "$GT" --defaults > /dev/null 2>&1
[ "$(cksum < "$GT/grounds/01-frames.md")" = "$before" ] \
    || { echo "FAIL — an upgrade overwrote a record the project wrote"; exit 1; }

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

# srs-end: FR-GND-280, FR-GND-290, FR-GND-300, FR-GND-310, FR-GND-320
# --- verifies: FR-INIT-170 — an undated specification is told it can be
# --- dated, and nothing is written on its behalf. Nobody looks for a tool
# --- they have not heard of, and an install is when the framework has a
# --- project's attention.
grep -qF "carry no \`created\` date" /tmp/grounds-fresh.log \
    || { echo "FAIL FR-INIT-170 — an undated specification was not offered"
         echo "the dating command"; tail -8 /tmp/grounds-fresh.log; exit 1; }
absent "created:" "$GT/specs/10-fr-app.md"

echo "installer-smoke: the grounds register is offered, complete and quiet"

# srs-end: FR-INIT-170
# --- verifies: FR-ARCH-120, FR-ARCH-140, FR-ARCH-150 — the architecture
# --- layer is offered, arrives whole, and what arrives passes its own gate.
AT=/tmp/srs-arch-target
rm -rf "$AT"
python3 tools/srs_init.py "$AT" --defaults --name "Arch target" \
    --areas APP --ci github --arch yes > /tmp/arch-fresh.log 2>&1
for f in srs-dd/arch.md arch/arch-config.json arch/00-elements.md \
         srs-dd/tools/srs_arch.py .claude/skills/srs-arch/SKILL.md; do
    [ -f "$AT/$f" ] || { echo "FAIL FR-ARCH-120 — the layer arrived without $f"
                         exit 1; }
done
( cd "$AT" && python3 srs-dd/tools/srs_arch.py --no-write --strict ) \
    > /tmp/arch-strict.log 2>&1 \
    || { echo "FAIL FR-ARCH-140 — a fresh layer does not pass its own checker"
         cat /tmp/arch-strict.log; exit 1; }
[ -f "$AT/arch/90-map.md" ] \
    || { echo "FAIL FR-ARCH-140 — the install left no map, and a gate compares"
         echo "the committed one against a fresh run"; exit 1; }

# srs-end: FR-ARCH-120, FR-ARCH-140, FR-ARCH-150
# --- verifies: FR-ARCH-170, FR-CI-010, FR-GND-370, FR-CI-180 — the gate a
# --- target installs compares the matrix, the dashboard and the map, and the
# --- pipeline and the hook both run it through the one tool. Run here rather
# --- than read: the installed pipeline's command is executed in a project
# --- keeping both layers, and each generated file made stale in turn fails it
# --- by name. The same command passes, and says nothing of a map, where the
# --- project keeps no layer.
GT2=/tmp/srs-gate-target
rm -rf "$GT2"
python3 tools/srs_init.py "$GT2" --defaults --areas APP --ci both --grounds yes --period year --arch yes \
    > /dev/null 2>&1
for f in .github/workflows/srs.yml .gitlab-ci.yml .githooks/pre-commit; do
    grep -qF "python3 srs-dd/tools/srs_gate.py" "$GT2/$f" \
        || { echo "FAIL FR-CI-180 — the installed $f does not run the gate through srs-dd/tools/srs_gate.py"; exit 1; }
    # A checker run as its own step is what the gate replaced; the same tool
    # asked for a page is a renderer and not a step of the gate, so a line
    # carrying --html does not count.
    if grep -E "python3 srs-dd/tools/srs_(check|grounds|arch)\.py" "$GT2/$f" \
            | grep -qv -- "--html"; then
        echo "FAIL FR-CI-180 — the installed $f still runs a step of the gate itself"; exit 1
    fi
done
( cd "$GT2" && git init -q . && git add -A \
  && git -c user.email=t@t -c user.name=t commit -qm base )
rc=0; ( cd "$GT2" && python3 srs-dd/tools/srs_gate.py ) > /tmp/gate-fresh.log 2>&1 || rc=$?
[ "$rc" = 0 ] || { echo "FAIL FR-CI-180 — the gate refused a project just installed"; cat /tmp/gate-fresh.log; exit 1; }
for generated in specs/90-traceability.md grounds/90-dashboard.md arch/90-map.md; do
    printf '\nedited by hand\n' >> "$GT2/$generated"
    ( cd "$GT2" && git add -A && git -c user.email=t@t -c user.name=t commit -qm "stale $generated" )
    rc=0; ( cd "$GT2" && python3 srs-dd/tools/srs_gate.py ) > /tmp/gate-stale.log 2>&1 || rc=$?
    [ "$rc" = 1 ] && grep -qF "srs_gate.py: $generated was regenerated and differs from what git holds" /tmp/gate-stale.log \
        || { echo "FAIL — the installed pipeline's gate passed a committed $generated that is stale (exit $rc)"
             cat /tmp/gate-stale.log; exit 1; }
    ( cd "$GT2" && git checkout -q -- "$generated" && git reset -q --hard HEAD~1 )
done
rm -rf "$GT2"
NT2=/tmp/srs-gate-nolayers
rm -rf "$NT2"
python3 tools/srs_init.py "$NT2" --defaults --areas APP --ci github > /dev/null 2>&1
( cd "$NT2" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm base )
rc=0; ( cd "$NT2" && python3 srs-dd/tools/srs_gate.py ) > /tmp/gate-nolayers.log 2>&1 || rc=$?
[ "$rc" = 0 ] || { echo "FAIL FR-ARCH-170 — the gate refused a project that keeps no layer"; cat /tmp/gate-nolayers.log; exit 1; }
absent "arch/90-map.md" /tmp/gate-nolayers.log
absent "grounds/90-dashboard.md" /tmp/gate-nolayers.log
rm -rf "$NT2"
echo "installer-smoke: the installed gate compares every generated file the project keeps, through one tool"

# --- Declined, it leaves no trace at all.
rm -rf /tmp/srs-noarch
python3 tools/srs_init.py /tmp/srs-noarch --defaults --areas APP \
    --ci none --arch no > /dev/null 2>&1
for f in arch srs-dd/tools/srs_arch.py .claude/skills/srs-arch; do
    [ -e "/tmp/srs-noarch/$f" ] \
        && { echo "FAIL FR-ARCH-120 — --arch no still installed $f"; exit 1; }
done

# srs-end: FR-ARCH-170, FR-CI-010, FR-GND-370, FR-CI-180
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
# srs-end: FR-ARCH-130

# --- verifies: FR-GND-570, FR-ARCH-300, FR-CI-020 — the hook gates the dashboard and
# --- the map as it gates the matrix: regenerated, and the commit refused
# --- while the copy being committed is not the checker's. Only where the
# --- project keeps the layer, decided at every commit by its configuration.
HT=/tmp/srs-hook-layers
rm -rf "$HT"
python3 tools/srs_init.py "$HT" --defaults --areas APP --grounds yes --arch yes > /dev/null 2>&1
# An element carrying the placeholder requirement, so that the map has
# something of the specification to count.
python3 - "$HT/arch/00-elements.md" <<'PY3'
import sys
path = sys.argv[1]
text = open(path, encoding='utf-8').read().replace('*None at the moment.*', '')
open(path, 'w', encoding='utf-8').write(
    text + '\n### E-010 — The app\n\n```yaml\nstatus: proposed\ncarries: [src]\n'
    'requirements: [FR-APP-010]\n```\n\nEverything.\n')
PY3
hook_in() {
    rc=0
    ( cd "$1" && sh .githooks/pre-commit ) > /tmp/hook-layers.log 2>&1 || rc=$?
}
refused() {
    [ "$rc" = 1 ] && grep -qF "srs_gate.py: $1 was regenerated and differs from what git holds — stage it and commit again." /tmp/hook-layers.log \
        || { echo "FAIL $2 — the hook did not refuse over $1 ($3)"; cat /tmp/hook-layers.log; exit 1; }
}
passed() {
    [ "$rc" = 0 ] || { echo "FAIL $1 — the hook refused a commit it should pass ($2)"
                       cat /tmp/hook-layers.log; exit 1; }
}
( cd "$HT" && git init -q . && python3 srs-dd/tools/srs_check.py > /dev/null \
  && python3 srs-dd/tools/srs_grounds.py > /dev/null && python3 srs-dd/tools/srs_arch.py > /dev/null && git add -A )
hook_in "$HT"; passed "FR-GND-570/FR-ARCH-300" "every generated file current and staged"

# A copy edited by hand is not the checker's.
printf '\nedited by hand\n' >> "$HT/grounds/90-dashboard.md"
( cd "$HT" && git add grounds/90-dashboard.md )
hook_in "$HT"; refused grounds/90-dashboard.md FR-GND-570 "a dashboard edited by hand"
( cd "$HT" && git add grounds/90-dashboard.md )
hook_in "$HT"; passed FR-GND-570 "the regenerated dashboard staged"
printf '\nedited by hand\n' >> "$HT/arch/90-map.md"
( cd "$HT" && git add arch/90-map.md )
hook_in "$HT"; refused arch/90-map.md FR-ARCH-300 "a map edited by hand"
( cd "$HT" && git add arch/90-map.md )
hook_in "$HT"; passed FR-ARCH-300 "the regenerated map staged"

# A file never staged is refused: the pipeline would find it missing.
( cd "$HT" && git rm -q --cached grounds/90-dashboard.md )
hook_in "$HT"; refused grounds/90-dashboard.md FR-GND-570 "a dashboard never staged"
( cd "$HT" && git add grounds/90-dashboard.md )

# The case the gate exists for: a commit that touches only the
# specification. A requirement added moves the matrix, the dashboard and
# the map, and one refusal names all three: a hook that stopped at the first
# would leave the next stale, and the commit after staging what it named
# would be refused again.
printf '\n### FR-APP-020 — Another\n\n```yaml\nstatus: deferred\nverification: T\n```\n\nThe app **shall** do another thing.\n' \
    >> "$HT/specs/10-fr-app.md"
( cd "$HT" && git add specs/10-fr-app.md )
hook_in "$HT"; refused specs/90-traceability.md FR-CI-020 "a requirement added"
refused grounds/90-dashboard.md FR-GND-570 "a requirement added — named in the same refusal"
refused arch/90-map.md FR-ARCH-300 "a requirement added — named in the same refusal"
( cd "$HT" && git add specs/90-traceability.md grounds/90-dashboard.md arch/90-map.md )
hook_in "$HT"; passed "FR-GND-570/FR-ARCH-300" "everything the one refusal named staged, retried once"

# Without the layers the hook runs neither checker. A register added later
# is gated from the first commit after its configuration appears, with the
# hook as it was installed.
NT=/tmp/srs-hook-nolayers
rm -rf "$NT"
python3 tools/srs_init.py "$NT" --defaults --areas APP > /dev/null 2>&1
( cd "$NT" && git init -q . && python3 srs-dd/tools/srs_check.py > /dev/null && git add -A )
hook_in "$NT"; passed "FR-GND-570/FR-ARCH-300" "a project keeping neither layer"
absent "Dashboard rewritten" /tmp/hook-layers.log
absent "Map rewritten" /tmp/hook-layers.log
[ ! -e "$NT/grounds" ] && [ ! -e "$NT/arch" ] \
    || { echo "FAIL FR-GND-570/FR-ARCH-300 — the hook created a layer the project does not keep"; exit 1; }
before=$(cksum < "$NT/.githooks/pre-commit")
python3 tools/srs_init.py "$NT" --defaults --grounds yes > /dev/null 2>&1
[ "$(cksum < "$NT/.githooks/pre-commit")" = "$before" ] \
    || { echo "FAIL FR-GND-570 — adding the register rewrote the hook, so the fixture proves nothing"; exit 1; }
( cd "$NT" && git add specs )
hook_in "$NT"; refused grounds/90-dashboard.md FR-GND-570 "a register added after the hook was installed"
rm -rf "$HT" "$NT"

echo "installer-smoke: the hook refuses a stale dashboard or map where the project keeps the layer, and nowhere else"
# srs-end: FR-GND-570, FR-ARCH-300, FR-CI-020
# --- verifies: IF-SPEC-040 — an area whose name joins two words with an
# --- underscore is accepted where the installer asks for areas and found where
# --- it adopts a specification that already uses one, in a folder grouping
# --- areas; a name the grammar refuses stops the install before it writes.
UT=/tmp/srs-underscore
rm -rf "$UT"
python3 tools/srs_init.py "$UT" --defaults --areas MAP_ILAND,APP --ci none > /tmp/und-fresh.log 2>&1 \
    || { echo "FAIL IF-SPEC-040 — a fresh install refused an area of two words"; cat /tmp/und-fresh.log; exit 1; }
grep -q "^### FR-MAP_ILAND-010 " "$UT/specs/10-fr-map_iland.md" \
    || { echo "FAIL IF-SPEC-040 — the placeholder of an area of two words was not written"; exit 1; }
( cd "$UT" && python3 srs-dd/tools/srs_check.py --no-write ) > /tmp/und-check.log 2>&1 \
    || { echo "FAIL IF-SPEC-040 — the installed project's checker refuses its own area"; cat /tmp/und-check.log; exit 1; }
rm -rf "$UT"
for bad in MAP_ MAP__ILAND map_iland; do
    rc=0; python3 tools/srs_init.py "$UT" --defaults --areas "$bad" --ci none > /tmp/und-bad.log 2>&1 || rc=$?
    [ "$rc" = 2 ] && grep -q "its words joined by single underscores" /tmp/und-bad.log \
        || { echo "FAIL IF-SPEC-040 — the area $bad was not refused with exit 2 (exit $rc)"; cat /tmp/und-bad.log; exit 1; }
    [ ! -e "$UT/specs" ] || { echo "FAIL IF-SPEC-040 — a refused area left files behind"; exit 1; }
done
mkdir -p "$UT/specs/MAPS"
printf '### FR-MAP_ILAND-010 — An island\n\n```yaml\nstatus: deferred\nverification: T\ndepends_on: [FR-MAP_ILAND-020]\n```\n\nThe map **shall** hold an island.\n\n### FR-MAP_ILAND-020 — A shore\n\n```yaml\nstatus: deferred\nverification: T\n```\n\nThe map **shall** draw a shore.\n' \
    > "$UT/specs/MAPS/10-fr-map_iland.md"
python3 tools/srs_init.py "$UT" --defaults --ci none > /tmp/und-adopt.log 2>&1 \
    || { echo "FAIL IF-SPEC-040 — adopting a specification with an area of two words failed"; cat /tmp/und-adopt.log; exit 1; }
grep -q '"MAP_ILAND"' "$UT/specs/srs-config.json" \
    || { echo "FAIL IF-SPEC-040 — adoption did not find the area of two words"; cat "$UT/specs/srs-config.json"; exit 1; }
rm -rf "$UT"
echo "installer-smoke: an area of two words is installed, adopted, and a malformed one refused"
# srs-end: IF-SPEC-040
