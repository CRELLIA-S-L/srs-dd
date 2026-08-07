#!/usr/bin/env bash
# tools/srs_upgrade.py: the one command an installed project runs to pick up
# a new framework version. Exercised against this working tree through
# --from, so the suite never reaches the network.
set -eo pipefail
cd "$(dirname "$0")/.."
FRAMEWORK=$(pwd)

rm -rf /tmp/srs-upg
python3 tools/srs_init.py /tmp/srs-upg --defaults --ci none >/dev/null

# The upgrader travels with the project, and the project records where it
# came from.
test -f /tmp/srs-upg/tools/srs_upgrade.py
test -f /tmp/srs-upg/.claude/skills/srs-upgrade/SKILL.md
grep -q '"framework_url"' /tmp/srs-upg/specs/srs-config.json
# An SSH remote must not travel: the project upgrading is somebody else's
# machine, without this maintainer's keys.
if grep -q '"framework_url": "git@' /tmp/srs-upg/specs/srs-config.json; then
    echo "framework_url must be an address a stranger can fetch"
    exit 1
fi

# Make the version transition visible: pretend the project is a release behind.
python3 - <<'PY'
import re
p = '/tmp/srs-upg/tools/srs_check.py'
s = open(p, encoding='utf-8').read()
open(p, 'w', encoding='utf-8').write(
    re.sub(r'__version__ = "[^"]+"', '__version__ = "0.0.1"', s, count=1))
PY

# Without a terminal and without --yes it must refuse, and write nothing.
find /tmp/srs-upg -type f | sort | xargs cksum > /tmp/upg-before.sum
rc=0; python3 /tmp/srs-upg/tools/srs_upgrade.py --from "$FRAMEWORK" \
    > /tmp/upg-refuse.log 2>&1 </dev/null || rc=$?
test "$rc" -eq 2
grep -q "Re-run with --yes" /tmp/upg-refuse.log
find /tmp/srs-upg -type f | sort | xargs cksum > /tmp/upg-after.sum
diff /tmp/upg-before.sum /tmp/upg-after.sum

# The refusal still showed the change: transition, what arrived, what to
# do about it, and the file list.
grep -q "checker 0.0.1 ->" /tmp/upg-refuse.log \
    || grep -q "checker 0.0.1 →" /tmp/upg-refuse.log
grep -q "What is new" /tmp/upg-refuse.log
grep -q "^  + " /tmp/upg-refuse.log
grep -q "Full text: CHANGELOG.md" /tmp/upg-refuse.log
grep -q "Upgrade notes" /tmp/upg-refuse.log
grep -q "tools/srs_check.py" /tmp/upg-refuse.log

# One line per entry: no bullet may run past the width the summary cuts to.
python3 - <<'PY2'
longest = max((len(l.rstrip()) for l in open('/tmp/upg-refuse.log')
               if l.startswith('  + ') or l.startswith('  ~ ')), default=0)
assert longest <= 82, 'a what-is-new entry spans %d columns' % longest
PY2

# With --yes it applies, and the tooling is current afterwards.
python3 /tmp/srs-upg/tools/srs_upgrade.py --from "$FRAMEWORK" --yes \
    > /tmp/upg-apply.log 2>&1 </dev/null
grep -q "refreshed:" /tmp/upg-apply.log
current=$(grep -m1 '^__version__' tools/srs_check.py)
grep -q "^$current" /tmp/srs-upg/tools/srs_check.py
python3 /tmp/srs-upg/tools/srs_check.py --strict --no-write >/dev/null

# A path that is not a framework clone is refused before anything happens.
rc=0; python3 /tmp/srs-upg/tools/srs_upgrade.py --from /tmp --yes \
    > /tmp/upg-bad.log 2>&1 </dev/null || rc=$?
test "$rc" -eq 2
grep -q "not a framework clone" /tmp/upg-bad.log

# --ref and --from contradict each other; saying so beats ignoring one.
rc=0; python3 /tmp/srs-upg/tools/srs_upgrade.py --from "$FRAMEWORK" --ref v0.0.0 \
    --yes > /tmp/upg-both.log 2>&1 </dev/null || rc=$?
test "$rc" -eq 2
grep -q "drop one of them" /tmp/upg-both.log

# Run inside the framework repository, it refuses: that one upgrades with git.
rc=0; python3 tools/srs_upgrade.py --yes > /tmp/upg-self.log 2>&1 </dev/null || rc=$?
test "$rc" -eq 2
grep -q "framework repository itself" /tmp/upg-self.log

# The newest changelog section is what the next upgrade will summarize, and
# the summary shows one sentence per entry. An entry whose first sentence
# does not fit reaches the reader cut in half — the format contract in
# CHANGELOG.md asks for self-contained ones, and this is what enforces it.
python3 - <<'PY2'
import sys, importlib.util
sys.path.insert(0, 'tools')
spec = importlib.util.spec_from_file_location('srs_init', 'tools/srs_init.py')
init = importlib.util.module_from_spec(spec)
spec.loader.exec_module(init)
sections = init.changelog_sections(('Added', 'Changed'))
newest = max(sections, key=init.version_tuple)
cut = [init.one_line(b) for h in ('Added', 'Changed')
       for b in init.bullets(sections[newest].get(h, []))
       if init.one_line(b).endswith('…')]
assert not cut, ('%s: first sentence does not fit the upgrade summary: %s'
                 % (newest, cut))
PY2

# The fallback address lives in two files that cannot import each other —
# the shipped upgrader and the framework-only installer. A silent drift
# between them would send every future project to the wrong place.
python3 - <<'PY'
import re
def const(path, name):
    text = open(path, encoding='utf-8').read()
    return re.search(r'^%s = "([^"]+)"' % name, text, re.M).group(1)
a = const('tools/srs_upgrade.py', 'DEFAULT_URL')
b = const('tools/srs_init.py', 'DEFAULT_FRAMEWORK_URL')
assert a == b, 'fallback framework address differs: %s vs %s' % (a, b)
PY
