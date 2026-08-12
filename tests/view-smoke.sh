#!/usr/bin/env bash
# tools/srs_view.py against a freshly installed target: every query mode,
# and the self-contained page (no CDN, deterministic, no bytecode).
set -eo pipefail
cd "$(dirname "$0")/.."

# Its own directory: the whole suite runs in one session. The root is kept
# because the suite spends most of its length inside the target, where the
# installer does not exist — it never travels.
FRAMEWORK=$(pwd)
rm -rf /tmp/srs-view
python3 tools/srs_init.py /tmp/srs-view --defaults --ci none >/dev/null

# Two linked requirements, one of them the target of a refinement, and one
# dependency across them: enough to exercise the tree, the incoming links,
# and a graph that draws every kind of link (FR-VIEW-160).
cat >> /tmp/srs-view/specs/10-fr-core.md <<'MD'

### FR-CORE-020 — Second requirement & an ampersand

```yaml
status: implemented
verification: T
derives_from: [FR-CORE-010]
depends_on: [FR-CORE-030]
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
depends_on: [FR-CORE-010]
```

The system **shall** refine the second one.
MD

mkdir -p /tmp/srs-view/src
# srs-ignore: the annotation below is a fixture written into the target,
# not a claim about this repository.
printf '# implements: FR-CORE-020\n' > /tmp/srs-view/src/app.py  # srs-ignore

cd /tmp/srs-view
# A baseline is a row in the log; the tag beside it is the optional
# bookmark, and it is here so the tag-resolution path gets exercised too
# (INV-SPEC-040). The tagless path is baseline-smoke's business.
python3 - <<'PY0'
import re
path = 'specs/92-baselines.md'
text = open(path, encoding='utf-8').read()
anchor = re.search(r'^\|---\|---\|---\|---\|$', text, re.M)
row = '| 0.0.1 | 2026-01-01 | `spec/v0.0.1` | The first baseline. |'
open(path, 'w', encoding='utf-8').write(
    text[:anchor.end()] + '\n' + row + text[anchor.end():])
PY0
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
# And the opposite direction under the upward flag (FR-VIEW-030). Only the
# downward walk was asserted, so `--up` could have printed the same tree, or
# nothing, without this suite noticing.
python3 tools/srs_view.py --tree FR-CORE-020 --up > /tmp/v-up.log
grep -q "FR-CORE-010" /tmp/v-up.log
! grep -q "FR-CORE-030" /tmp/v-up.log
python3 tools/srs_view.py --code src/app.py --list > /tmp/v-code.log
grep -q "FR-CORE-020" /tmp/v-code.log
# A directory as well as a file (FR-VIEW-020): the statement offers both and
# only the file was ever passed.
python3 tools/srs_view.py --code src --list > /tmp/v-dir.log
grep -q "FR-CORE-020" /tmp/v-dir.log
python3 tools/srs_view.py --coverage > /tmp/v-cov.log
grep -q "Realized without listed tests" /tmp/v-cov.log
# The fourth gap is a proportion, not a count (FR-VIEW-040): one
# unreferenced file means nothing without how many there are.
grep -qE "Code files no requirement references: [0-9]+ of [0-9]+" /tmp/v-cov.log
python3 tools/srs_view.py --diff spec/v0.0.1 > /tmp/v-diff.log
# The same baseline named by version rather than by tag (FR-VIEW-050): a
# baseline need not have been tagged to be compared against.
python3 tools/srs_view.py --diff 0.0.1 > /tmp/v-diff-version.log
cmp <(tail -n +2 /tmp/v-diff.log) <(tail -n +2 /tmp/v-diff-version.log)
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

# The dashboard counts every status (FR-VIEW-190). The fixture stands at
# two deferred and one implemented, which leaves three statuses carried by
# nobody — and those are the half of the rule that matters, because a
# census of whatever happens to be present passes the other half without
# meaning to.
python3 - <<'PY2'
import re
page = open('.srs-site/index.html', encoding='utf-8').read()
section = page[page.index('<section id="view-dash"'):]
section = section[:section.index('</section>')]
# Expected counts come from the model rather than from constants: the
# fixture leans on whatever status the installer gives its placeholder, and
# a hard-coded number would fail here naming the dashboard when what moved
# was srs_init.py. The two sides are still independent — the page's census
# is rendered by render_dashboard, this reads what load_model parsed.
import json
model = json.load(open('/tmp/model.json'))
expected = {}
for entry in model['requirements']:
    expected[entry['status']] = expected.get(entry['status'], 0) + 1
for status in ('draft', 'deferred', 'partial', 'implemented', 'superseded',
               'withdrawn'):
    found = re.search(r'st-%s">%s</span></td><td>(\d+)</td>'
                      % (status, status), section)
    assert found, 'the dashboard gives no count for %s' % status
    assert int(found.group(1)) == expected.get(status, 0), \
        'the dashboard counts %s as %s, the model says %d' \
        % (status, found.group(1), expected.get(status, 0))
# Three of the six are carried by nobody here, which is the half of the
# rule a census of whatever happens to be present would pass by accident.
assert len([s for s in ('draft', 'deferred', 'partial', 'implemented',
                        'superseded', 'withdrawn')
            if not expected.get(s)]) >= 3, \
    'the fixture no longer exercises statuses that nothing carries'
PY2

# The coverage gaps are on the page, not only in the terminal
# (FR-VIEW-200). The --coverage assertion above reads standard output and
# says nothing about what the page carries; the lists are checked by their
# headings and by an entry underneath one of them, or a dashboard emitting
# four empty sections would pass.
python3 - <<'PY2'
page = open('.srs-site/index.html', encoding='utf-8').read()
section = page[page.index('<section id="view-dash"'):]
section = section[:section.index('</section>')]
for heading in ('Realized without listed tests',
                'Draft with code',
                'Realized but resting on a draft',
                'Code files no requirement references'):
    assert heading in section, 'the dashboard dropped: %s' % heading
# FR-CORE-020 is implemented and lists no test, so the first gap has it.
untested = section[section.index('Realized without listed tests'):]
untested = untested[:untested.index('<h2>', 1)]
assert 'FR-CORE-020' in untested, \
    'the gap lists are on the page but empty of what belongs in them'
PY2

# Baselines: a second one, so there is a pair to compare.
python3 - <<'PY2'
path = 'specs/10-fr-core.md'
text = open(path, encoding='utf-8').read()
open(path, 'w', encoding='utf-8').write(
    text.replace('status: deferred', 'status: implemented', 1)
        .replace('code: []', 'code: [src/app.py]', 1))
PY2
python3 - <<'PY3'
import re
path = 'specs/92-baselines.md'
text = open(path, encoding='utf-8').read()
anchor = re.search(r'^\|---\|---\|---\|---\|$', text, re.M)
row = '| 0.0.2 | 2026-01-02 | `spec/v0.0.2` | One requirement realized. |'
open(path, 'w', encoding='utf-8').write(
    text[:anchor.end()] + '\n' + row + text[anchor.end():])
PY3
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
              '#graph-svg.focused', 'id="graph-reset"', 'getScreenCTM',
              'toDrawing('):
    assert token in page, 'the graph lost %s' % token
# The canvas is the panel, not the drawing: sized in CSS, with no width or
# height baked in from the content, or a small specification gets a postage
# stamp to work in.
import re as _re
svg = _re.search(r'<svg id="graph-svg"[^>]*>', page).group(0)
assert ' width=' not in svg and ' height=' not in svg, svg
assert 'viewBox=' in svg and 'preserveAspectRatio=' in svg, svg
assert 'height: 70vh' in page
# The zoom anchor goes through the inverse matrix, not through the scale
# alone: the drawing is centred in the panel, and dividing by the scale
# ignores that margin.
assert 'getBoundingClientRect' not in page.split("addEventListener('wheel'")[1][:400], \
    'the wheel handler is measuring the element instead of inverting the matrix'
# Pointer events, not mouse ones: the CSS turns native scrolling off, so
# handling only mice would leave a touch device unable to move the graph.
assert "addEventListener('mousedown'" not in page, 'mouse-only dragging is back'
assert 'touch-action' in page
PY2

# A lane is an area and a row is a number: position is arithmetic, so the
# drawing needs no heuristic kept stable for it (ADR-0012). Checked on the
# rendered page rather than on a fixture, because the arithmetic is not
# where this can go wrong — the grouping is.
python3 - <<'PY2'
import re
page = open('.srs-site/index.html', encoding='utf-8').read()
nodes = re.findall(r'<g class="node[^"]*"[^>]*data-id="([^"]+)"[^>]*'
                   r'data-area="([^"]+)" data-x="(\d+)" data-y="(\d+)" '
                   r'data-x0="(\d+)" data-y0="(\d+)"', page)
assert nodes, 'no nodes carry an area'
lanes = {}
for rid, area, x, y, x0, y0 in nodes:
    assert rid.split('-')[1] == area, (rid, area)
    assert (x, y) == (x0, y0), 'a node is not drawn where it belongs'
    lanes.setdefault(area, set()).add(x)
for area, xs in lanes.items():
    assert len(xs) == 1, 'area %s is spread over %d columns' % (area, len(xs))
assert len(set().union(*lanes.values())) == len(lanes), 'two areas share a column'

# Every lane declared in the configuration and holding a linked requirement
# has a header, and the header is what folds the column away (FR-VIEW-110).
headers = re.findall(r'<g class="lane" data-area="([^"]+)" data-x="\d+" '
                     r'data-y="\d+" data-h="(\d+)"', page)
assert set(a for a, _h in headers) == set(lanes), (headers, sorted(lanes))
assert len(headers) == len(set(headers)), 'a lane is drawn twice'
for token in ("querySelectorAll('g.lane')", "classList.toggle('collapsed'",
              "dataset.x0", 'edgePath(', 'LANE_FOLD_H'):
    assert token in page, 'collapsing an area lost %s' % token
# The header is the control and the backdrop is decoration. Catching the
# click on the backdrop folded an area away when the reader clicked in the
# gap between two boxes; and a drag is a movement past a threshold, because
# counting a one-pixel nudge as one swallowed the click it belonged to and
# left the control working on every second attempt.
assert re.search(r'<rect class="lane-head"', page), 'the lane header is gone'
assert re.search(r'\.lane-band \{[^}]*pointer-events: none', page), \
    'the backdrop takes clicks again'
assert 'DRAG_SLOP' in page and re.search(r'>\s*DRAG_SLOP', page), \
    'any movement counts as a drag again'
# The capture is taken when a drag starts, never on pointerdown. While an
# element holds the pointer capture the browser dispatches the click to it
# instead of to the descendant under the cursor, so capturing up front sent
# every click to the canvas and no node or lane header ever saw one. The
# handlers were all present the whole time, which is exactly why this is
# asserted on where the call sits rather than on whether it exists.
down = page.split("addEventListener('pointerdown'")[1]
down = down[:down.index("addEventListener('pointermove'")]
assert 'setPointerCapture' not in down, \
    'the canvas captures the pointer before a drag, which steals every click'
move = page.split("addEventListener('pointermove'")[1][:700]
assert 'setPointerCapture' in move, 'a drag no longer keeps the pointer'
# The band shrinks with the column, and its full height is on the lane so
# unfolding can put it back — without that a collapsed area leaves an empty
# stripe exactly where the reader asked for the space.
assert "band.setAttribute('height'" in page and 'lane.dataset.h' in page, \
    'a collapsed lane no longer shrinks to a block'
# Returning the view returns the folded columns too (FR-VIEW-110): the
# reset handler has to go through the same function the header uses.
after_reset = page.split("getElementById('graph-reset')")[1][:600]
assert 'setLane(' in after_reset, 'reset view leaves the folded areas folded'

# The status is the node's colour (FR-VIEW-180). The class alone proves
# nothing — it sat on every node for two releases while a stroke named in
# the rule painted over it, so what is asserted is the mechanism: the box
# takes its colour from the node, and the node's class supplies one.
assert 'stroke: currentColor' in page and 'fill: currentColor' in page, \
    'the node box no longer takes its colour from its status class'
assert not re.search(r'\.graph \.node rect \{[^}]*stroke: var\(--line\)', page), \
    'a neutral stroke is painting over the status colour again'
for status in ('draft', 'deferred', 'partial', 'implemented', 'superseded',
               'withdrawn'):
    assert re.search(r'\.st-%s \{ color: var\(--%s\)' % (status, status), page), \
        'no colour for status %s' % status
    assert re.search(r'<span class="key st-%s">.{0,40}%s</span>'
                     % (status, status), page), \
        'the legend does not name %s' % status
# Both legends are lists and read down the rail; neither floats over the
# drawing, where they covered the first column and the reader panned the
# graph out from under them.
assert 'id="graph-rail"' in page, 'the legends are back on top of the graph'
assert not re.search(r'#graph-(legend|controls) \{[^}]*position: absolute', page)
assert re.search(r'#graph-legend \{[^}]*flex-direction: column', page), \
    'the status legend runs across instead of down'
assert re.search(r'#graph-controls \{[^}]*flex-direction: column', page), \
    'the controls run across instead of down'
for field in ('derives_from', 'refines', 'depends_on', 'conflicts_with'):
    assert '<line class="edge %s"' % field in page, \
        'the legend has no swatch for %s' % field
    # And the reader can leave that kind out (FR-VIEW-160). The suite runs
    # no browser, so what is asserted is the mechanism end to end: a swatch
    # that is a control, a rule that hides the kind when the drawing carries
    # its class, and a handler that puts the class there. The drawing half
    # of this requirement was built and marked implemented while this half
    # was never written — a control belonging to FR-VIEW-150 stood in for it.
    assert re.search(r'class="key kind"[^>]*aria-pressed="true"[^>]*'
                     r'data-kind="%s"' % field, page), \
        'the swatch for %s is not a control' % field
    assert '#graph-svg.hide-%s .edge.%s { display: none; }' % (field, field) \
        in page, 'nothing hides %s when the drawing is told to' % field
assert "classList.toggle('hide-' + kind" in page, \
    'the swatches are controls that control nothing'
# Reset restores the kinds too. The button already argued the principle for
# folded columns — a reader who cannot find the way back is worse off than
# before — and a dimmed swatch is easier to overlook than a missing column.
after_reset_kinds = page.split("getElementById('graph-reset')")[1][:900]
assert "remove('hide-' + key.dataset.kind)" in after_reset_kinds, \
    'reset view leaves the hidden link kinds hidden'
# Colour is not the only channel: the tooltip says the status in words.
assert re.search(r'<title>[^<]+\((draft|deferred|partial|implemented|'
                 r'superseded)\)</title>', page), \
    'a node no longer carries its status as a word'
PY2

# The views that name a requirement in the rendered file name it in a way
# the page can follow (FR-VIEW-130). Baselines are not among them: that
# list is built in the page from the embedded snapshots, so there is
# nothing static to assert. The following of a link is browser behaviour
# and is inspected, not tested.
python3 - <<'PY2'
import re
page = open('.srs-site/index.html', encoding='utf-8').read()
for name in ('view-dash', 'view-graph'):
    section = page[page.index('<section id="%s"' % name):]
    section = section[:section.index('</section>')]
    assert re.search(r'(href="#|data-id=")FR-CORE-0', section), \
        '%s names no requirement to reach' % name
PY2

# Every kind of link is drawn, and told apart by its own class
# (FR-VIEW-160). The class is the only thing on an edge: nothing marks a
# direction any more, because with a lane for an area and a row for a
# number no direction claims to be the forward one (ADR-0012).
grep -q 'class="edge derives_from"' .srs-site/index.html
grep -q 'class="edge depends_on"' .srs-site/index.html
python3 - <<'PY3'
import re
page = open('.srs-site/index.html', encoding='utf-8').read()
assert 'class="edge back"' not in page, 'an edge lost its kind to `back`'
# An edge inside one lane bows out; a straight line would run underneath
# every box between its ends. The rule is written twice — here and in the
# script that redraws an edge when an area is collapsed — so both copies
# have to be present, or an edge changes shape as the reader watches.
bowed = re.findall(r'<path class="edge [^"]*"[^>]*d="M [^"]*Q', page)
assert bowed, 'no intra-lane edge bows past what is between its ends'
assert 'Math.min(BOW_MAX' in page, 'the script lost its copy of the bow'
PY3
# And the reader can narrow the drawing to one requirement's surroundings
# (FR-VIEW-150): the controls and the walk that hides the rest are there.
grep -q 'id="graph-root"' .srs-site/index.html
grep -q 'id="graph-depth"' .srs-site/index.html
grep -q 'function narrow(' .srs-site/index.html

# --open renders and opens in one act (FR-VIEW-140). What a suite can hold
# is that the flag is wired and the page is written; that a browser really
# appeared is not something a machine without one can assert, so BROWSER
# points at a no-op and the assertion is about the page.
rm -f /tmp/v-open.html
BROWSER=/usr/bin/true python3 tools/srs_view.py --html /tmp/v-open.html \
    --open > /tmp/v-open.log
grep -q 'Page written' /tmp/v-open.log
test -s /tmp/v-open.html
# Without a path it renders the default one, so the whole act is one word.
rm -rf .srs-site
BROWSER=/usr/bin/true python3 tools/srs_view.py --open > /tmp/v-open2.log
test -s .srs-site/index.html

# A checkout without history — what CI gives by default — must not invent
# baselines out of the one commit it has. The log still names them, so the
# page says they could not be read rather than showing six identical
# snapshots that agree nothing ever changed.
rm -rf /tmp/srs-view-shallow
git clone --quiet --depth 1 --no-tags "file:///tmp/srs-view" /tmp/srs-view-shallow
(
  cd /tmp/srs-view-shallow
  python3 tools/srs_view.py --html shallow/index.html >/dev/null
  grep -q 'baselines are recorded' shallow/index.html
  grep -q 'fetch-depth: 0' shallow/index.html
  # No picker, and no snapshot data to compare with.
  ! grep -q 'id="base-from"' shallow/index.html
  grep -q '<script id="baselines-data" type="application/json">\[\]' \
      shallow/index.html
  # The current baseline is read from the log, which needs no history.
  grep -q 'baseline 0.0.2' shallow/index.html
  python3 - <<'PY0'
import sys; sys.dont_write_bytecode = True; sys.path.insert(0, 'tools')
import srs_view
assert srs_view.logged_baselines() == ['0.0.1', '0.0.2'], 'the log still reads'
assert all(srs_view.baseline_revision(v) is None
           for v in srs_view.logged_baselines()), \
    'a shallow checkout cannot locate a baseline, and must not claim to'
PY0
)

# The third coverage gap is counted by requirement, not by link
# (FR-VIEW-040 names requirements). Its own target: the fixture above has
# turned every draft into a deferred by the time --coverage runs, so there
# is nothing left there to rest on.
rm -rf /tmp/srs-view-resting
python3 "$FRAMEWORK/tools/srs_init.py" /tmp/srs-view-resting \
    --defaults --ci none >/dev/null
cat >> /tmp/srs-view-resting/specs/10-fr-core.md <<'MD'

### FR-CORE-040 — Rests on two drafts at once

```yaml
status: implemented
verification: I
derives_from: [FR-CORE-050]
depends_on: [FR-CORE-060]
code: [src/app.py]
```

The system **shall** rest on two drafts at once.

### FR-CORE-050 — A draft it derives from

```yaml
status: draft
verification: I
```

The system **shall** stand in for an unapproved parent.

### FR-CORE-060 — A draft it depends on

```yaml
status: draft
verification: I
code: [src/ahead.py]
```

The system **shall** stand in for an unapproved dependency.
MD
(
  cd /tmp/srs-view-resting
  mkdir -p src && printf 'x\n' > src/app.py && printf 'y\n' > src/ahead.py
  python3 tools/srs_view.py --coverage > /tmp/v-resting.log
  # One requirement, both of its links. Counting the lines said two.
  grep -q "^Realized but resting on a draft: 1$" /tmp/v-resting.log
  grep -q "FR-CORE-040 *derives_from FR-CORE-050" /tmp/v-resting.log
  grep -q "FR-CORE-040 *depends_on FR-CORE-060" /tmp/v-resting.log
  # This target is also the only one where the second and third gaps have
  # anything in them: the main fixture turns every draft into a deferred
  # before the page is rendered, so there the two are checked by their
  # headings alone and could be emitted empty without failing (FR-VIEW-200).
  python3 tools/srs_view.py --html >/dev/null
  python3 - <<'PY3'
page = open('.srs-site/index.html', encoding='utf-8').read()
sec = page[page.index('<section id="view-dash"'):]
sec = sec[:sec.index('</section>')]
def gap(heading):
    part = sec[sec.index(heading):]
    return part[:part.index('<h2>', 1)]
ahead = gap('Draft with code')
assert 'FR-CORE-060' in ahead, 'the draft carrying code is not listed'
resting = gap('Realized but resting on a draft')
assert 'FR-CORE-040' in resting, 'the requirement resting on a draft is not listed'
assert 'FR-CORE-050' not in resting and 'FR-CORE-060' not in resting, \
    'the page lists the drafts rested on instead of the requirement resting'
PY3
)

# The baseline row is printed ready to paste, and names the previous
# baseline it was computed against.
python3 tools/srs_view.py --baseline 0.0.3 --date 2026-01-02 > /tmp/v-row.log
grep -q '^| 0.0.3 | 2026-01-02 | `spec/v0.0.3` |' /tmp/v-row.log
# It names the baseline it was computed against — whether anything
# changed since it or not.
grep -q '0.0.2' /tmp/v-row.log
grep -q 'requirements' /tmp/v-row.log

# No two functions in the page's script share a name. One declared inside
# a block is also assigned to the enclosing function's binding of the same
# name, so a duplicate silently replaces the other: the graph's transform
# and the filters were both called `apply`, and every filter click moved
# the graph instead. Nothing in a browser reports this, and no suite that
# only reads markup can see it — but the script is text, and text can be
# counted.
python3 - <<'PY2'
import re
page = open('.srs-site/index.html', encoding='utf-8').read()
js = re.search(r'<script>\n(.*?)</script>', page, re.S).group(1)
names = re.findall(r'\bfunction\s+(\w+)\s*\(', js)
dupes = sorted({n for n in names if names.count(n) > 1})
assert not dupes, 'two functions share a name: %s' % dupes
PY2

# The page is text. A NUL byte makes grep, diff and every editor treat it
# as binary — and it got there because an escape written for JavaScript was
# eaten by the Python string carrying the script.
python3 - <<'PY2'
data = open('.srs-site/index.html', 'rb').read()
assert b'\x00' not in data, 'the page carries NUL bytes'
PY2

# A viewer run must not litter the target with bytecode.
test -z "$(find . -name __pycache__)"

# Nor may it write into specs/ (FR-VIEW-080). That half of the prohibition
# went unasserted while the bytecode half above stood in for it: the viewer
# could have started regenerating the matrix, as the checker does, and every
# suite here would have stayed green. Every mode, because only some of them
# have any reason to touch a file at all.
find specs -type f | sort | xargs cksum > /tmp/v-specs-before
for mode in "--list" "FR-CORE-010" "--tree FR-CORE-010" "--up FR-CORE-020" \
            "--code src/app.py" "--coverage" "--diff spec/v0.0.1" \
            "--baseline 9.9.9 --date 2026-01-01" "--json /tmp/v-nowrite.json" \
            "--html /tmp/v-nowrite.html"; do
    # Word splitting is the point — each entry is a whole invocation. Errors
    # are not swallowed: a mode that fails writes nothing, so tolerating it
    # would leave this comparison passing for exactly the mode that broke.
    # shellcheck disable=SC2086
    python3 tools/srs_view.py $mode >/dev/null 2>&1
done
find specs -type f | sort | xargs cksum > /tmp/v-specs-after
diff /tmp/v-specs-before /tmp/v-specs-after \
    || { echo "the viewer modified specs/"; exit 1; }
