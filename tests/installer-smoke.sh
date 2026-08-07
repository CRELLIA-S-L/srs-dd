#!/usr/bin/env bash
# tools/srs_init.py: fresh install, upgrade, --dry-run honesty, coexistence
# with a project's own pre-commit hook, and isolation of the payload.
set -eo pipefail
cd "$(dirname "$0")/.."

# Clean slate: on shell runners a leftover dir would silently flip the
# fresh-install step into upgrade mode.
rm -rf /tmp/srs-target

# --dry-run must list the whole install and create nothing at all.
python3 tools/srs_init.py /tmp/srs-target --defaults --ci both --dry-run | tee /tmp/dry.log
grep -q "tools/srs_view.py" /tmp/dry.log
grep -q "nothing was written" /tmp/dry.log
test ! -e /tmp/srs-target

# Fresh install into a temp dir must pass its own checker, strictly.
python3 tools/srs_init.py /tmp/srs-target --defaults --ci both
python3 /tmp/srs-target/tools/srs_check.py --strict

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
