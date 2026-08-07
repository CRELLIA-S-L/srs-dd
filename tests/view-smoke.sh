#!/usr/bin/env bash
# tools/srs_view.py against a freshly installed target: every query mode,
# and the self-contained page (no CDN, deterministic, no bytecode).
set -eo pipefail
cd "$(dirname "$0")/.."

# Its own directory: the whole suite runs in one session.
rm -rf /tmp/srs-view
python3 tools/srs_init.py /tmp/srs-view --defaults --ci none >/dev/null

# Two linked requirements, one of them the target of a refinement: enough
# to exercise the tree, the graph and the incoming links.
cat >> /tmp/srs-view/specs/10-fr-core.md <<'MD'

### FR-CORE-020 — Second requirement & an ampersand

```yaml
status: implemented
verification: T
derives_from: [FR-CORE-010]
code: [src/app.py]
tests: []
```

The system **shall** carry a link.

**Rationale.** Exercises the graph and the incoming links.

### FR-CORE-030 — Third requirement

```yaml
status: draft
verification: T
refines: [FR-CORE-020]
```

The system **shall** refine the second one.
MD

mkdir -p /tmp/srs-view/src
# srs-ignore: the annotation below is a fixture written into the target,
# not a claim about this repository.
printf '# implements: FR-CORE-020\n' > /tmp/srs-view/src/app.py  # srs-ignore

cd /tmp/srs-view
git init -q . && git add -A
git -c user.email=ci@example.com -c user.name=CI commit -qm baseline
git tag spec/v0.0.1

# Change the specification after the baseline so the diff has content.
# Python rather than sed: `sed -i` wants a backup suffix on BSD and
# refuses one on GNU, and this suite also runs locally on macOS.
python3 - <<'PY'
path = 'specs/10-fr-core.md'
text = open(path, encoding='utf-8').read()
open(path, 'w', encoding='utf-8').write(
    text.replace('status: draft', 'status: deferred'))
PY

python3 tools/srs_view.py --list > /tmp/v-list.log
grep -q "FR-CORE-030" /tmp/v-list.log
python3 tools/srs_view.py FR-CORE-020 > /tmp/v-card.log
grep -q "refined by" /tmp/v-card.log
python3 tools/srs_view.py --tree FR-CORE-010 > /tmp/v-tree.log
grep -q "FR-CORE-030" /tmp/v-tree.log
python3 tools/srs_view.py --code src/app.py --list > /tmp/v-code.log
grep -q "FR-CORE-020" /tmp/v-code.log
python3 tools/srs_view.py --coverage > /tmp/v-cov.log
grep -q "Realized without listed tests" /tmp/v-cov.log
python3 tools/srs_view.py --diff spec/v0.0.1 > /tmp/v-diff.log
grep -q "status .*draft -> deferred" /tmp/v-diff.log

python3 tools/srs_view.py --json /tmp/model.json >/dev/null
python3 -c "import json; d=json.load(open('/tmp/model.json')); assert len(d['requirements'])==3, d"

python3 tools/srs_view.py --html
grep -q "FR-CORE-030" .srs-site/index.html
grep -q "<svg" .srs-site/index.html
grep -q "&amp;" .srs-site/index.html          # SVG/HTML escaping
if grep -q "https://cdn" .srs-site/index.html; then
    echo "the page must not reference a CDN"
    exit 1
fi
test -f .srs-site/.gitignore

# Deterministic output: no timestamps, so two runs must be identical.
cp .srs-site/index.html /tmp/first.html
python3 tools/srs_view.py --html >/dev/null
cmp /tmp/first.html .srs-site/index.html

# A viewer run must not litter the target with bytecode.
test -z "$(find . -name __pycache__)"
