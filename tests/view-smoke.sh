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

# Baselines: a second one, so there is a pair to compare.
python3 - <<'PY2'
path = 'specs/10-fr-core.md'
text = open(path, encoding='utf-8').read()
open(path, 'w', encoding='utf-8').write(
    text.replace('status: deferred', 'status: implemented', 1)
        .replace('code: []', 'code: [src/app.py]', 1))
PY2
git add -A
git -c user.email=ci@example.com -c user.name=CI commit -qm second
git tag spec/v0.0.2
python3 tools/srs_view.py --html

# The page says what it is showing (FR-VIEW-090).
grep -q "baseline 0.0.2" .srs-site/index.html
grep -q "srs_check " .srs-site/index.html

# And carries a snapshot per baseline, with a picker over them
# (FR-VIEW-100). The comparison itself runs in the browser; what the
# suite can check is that the data it runs on is there and correct —
# byte for byte the same verdict git gives for the same pair.
grep -q 'id="base-from"' .srs-site/index.html
grep -q 'id="base-to"' .srs-site/index.html
python3 - <<'PY2'
import json, re, sys, importlib.util
# Before the import, not after: the loader writes __pycache__ as it
# resolves the module, and the assertion below forbids leaving any in
# the target — the same rule CONTRIBUTING states for the tools.
sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
spec = importlib.util.spec_from_file_location('v', 'tools/srs_view.py')
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)

page = open('.srs-site/index.html', encoding='utf-8').read()
data = json.loads(re.search(
    r'<script id="baselines-data" type="application/json">(.*?)</script>',
    page, re.S).group(1))
assert [d['version'] for d in data] == ['0.0.1', '0.0.2'], data
assert 'full' in data[0] and 'put' in data[1], 'later baselines are deltas'

def fold(index):
    # The page's snapshotAt, transliterated: the JS itself is not run
    # here — no engine is a dependency of this project — but the data it
    # folds, and the verdict that folding yields, are checked against git.
    state = {}
    for step in data[:index + 1]:
        if 'full' in step:
            state = dict(step['full'])
            continue
        for rid in step.get('drop', []):
            state.pop(rid, None)
        state.update(step.get('put', {}))
    return state

FLAT = ['title', 'status', 'verification', 'statement']
LIST = ['code', 'tests', 'derives_from', 'depends_on', 'refines']
a, b = fold(0), fold(1)
from_page = (sorted(i for i in b if i not in a),
             sorted(i for i in a if i not in b),
             sorted(i for i in set(a) & set(b)
                    if [f for f in FLAT + LIST if a[i][f] != b[i][f]]))
ref = v.compute_diff(v.load_revision('spec/v0.0.1'),
                     v.load_revision('spec/v0.0.2'))
from_git = (sorted(e['id'] for e in ref['added']),
            sorted(e['id'] for e in ref['removed']),
            sorted(c['entry']['id'] for c in ref['changed']))
assert from_page == from_git, (from_page, from_git)
assert from_page[2], 'the fixture changed a requirement; the pair must show it'
PY2

# The graph can be explored: the page carries the stage to pan, the box
# size edges are recomputed from, and the handlers. The gestures
# themselves are not exercised — no browser is a dependency of this
# project — so what is checked is that nothing silently dropped out.
python3 - <<'PY2'
page = open('.srs-site/index.html', encoding='utf-8').read()
for token in ('id="graph-stage"', 'data-nw=', "getElementById('graph-svg')",
              "addEventListener('wheel'", "addEventListener('pointerdown'",
              '#graph-svg.focused'):
    assert token in page, 'the graph lost %s' % token
# Pointer events, not mouse ones: the CSS turns native scrolling off, so
# handling only mice would leave a touch device unable to move the graph.
assert "addEventListener('mousedown'" not in page, 'mouse-only dragging is back'
assert 'touch-action' in page
PY2

# Layer ordering pulls edges straight. Checked on a shape built for it:
# alphabetical order crosses, the barycentre order does not.
python3 - <<'PY2'
import sys, importlib.util
sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
spec = importlib.util.spec_from_file_location('v', 'tools/srs_view.py')
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)

# Two layers, wired so that reading the lower one alphabetically crosses:
# A→Z, B→Y, C→X.
layers = {0: ['X', 'Y', 'Z'], 1: ['A', 'B', 'C']}
parents = {'A': ['Z'], 'B': ['Y'], 'C': ['X']}
edges = [('A', 'Z'), ('B', 'Y'), ('C', 'X')]

def crossings(order):
    up = dict((n, i) for i, n in enumerate(order[0]))
    down = dict((n, i) for i, n in enumerate(order[1]))
    pairs = sorted((down[c], up[p]) for c, p in edges)
    return sum(1 for i in range(len(pairs)) for j in range(i + 1, len(pairs))
               if pairs[i][1] > pairs[j][1])

alpha = dict((level, sorted(nodes)) for level, nodes in layers.items())
ordered = v.order_layers(layers, parents)
assert crossings(alpha) == 3, crossings(alpha)
assert crossings(ordered) == 0, (ordered, crossings(ordered))
# And it is the same order every run: the page must stay byte-identical.
assert v.order_layers(layers, parents) == ordered
PY2

# A viewer run must not litter the target with bytecode.
test -z "$(find . -name __pycache__)"
