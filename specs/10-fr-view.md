# Functional requirements — view

The viewer, `tools/srs_view.py`: the read-only projections of what the
checker validates — terminal queries and one self-contained page.

### FR-VIEW-010 — One requirement with its links resolved

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

When given a requirement identifier, the viewer **shall** print that
requirement with its metadata, its statement, and its links resolved in both
directions, incoming links included.

**Rationale.** Incoming links are the blast radius of a change and are
computed, so they exist nowhere in the source files.

### FR-VIEW-020 — Which requirements describe a file

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

When given a path, the viewer **shall** list the requirements that name it in
their `code` or `tests` fields or that the file's own annotations point at,
accepting a directory as well as a file.

**Rationale.** This is the first question of every task that touches existing
code, and grepping the spec by hand misses annotations.

### FR-VIEW-030 — The derivation tree

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

When given a requirement identifier, the viewer **shall** print what derives
from it, and print the opposite direction — what it derives from — where the
upward flag is given.

**Rationale.** Changing a requirement without seeing what hangs below it is
how a small edit silently invalidates a subtree.

### FR-VIEW-040 — Coverage gaps

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

The viewer **shall** report, on request, realized requirements with no listed
tests, drafts that already carry code, realized requirements resting on a
draft, and source files no requirement references.

**Rationale.** These four lists are what an audit starts from; the checker
reports them as warnings at most — and under a lenient configuration not at
all — so something has to surface them on demand.

### FR-VIEW-050 — Difference against a baseline

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

When given a git revision or the version of a logged baseline, the viewer
**shall** print how the specification changed since it: requirements added,
removed, and the fields that differ.

**Rationale.** A baseline is only useful if the difference from it can be
read; a raw `git diff` of the specification is dominated by reflow. A
version is accepted because a baseline need not have a tag to name it by
(INV-SPEC-040), and asking a reader to find the commit themselves would put
the tag back in the middle of the process.

### FR-VIEW-060 — A page that opens from the filesystem

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

The viewer **shall** render the specification into a single self-contained
HTML file — search, filters, a status dashboard, a graph of the links
between requirements layered by derivation, and links in both directions —
that requests nothing over the network.

**Rationale.** A reviewer who does not grep still has to read the
specification, and a page that needs a CDN is a page that stops working
offline, behind a corporate proxy, and in five years.

### FR-VIEW-070 — Deterministic output

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

Two renderings of an unchanged specification **shall** produce byte-identical
pages.

**Rationale.** A timestamp in the output would make every CI run a diff, and
the page could never be committed or compared.

### FR-VIEW-080 — Reading never writes

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

The viewer **shall not** modify anything under `specs/` or leave bytecode in
the project it was run in.

**Rationale.** The traceability matrix stays the checker's artifact, with one
generator; a viewer that also wrote would create a second source of truth.

### FR-VIEW-090 — The page says what it is showing

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

The rendered page **shall** state the specification's current baseline, the
framework version that generated it, and — where the history those
baselines name was not available to the render — that they could not be
read.

**Rationale.** The page lives at a stable address and outlives a dozen
releases. A reader arriving from a bookmark cannot tell a fresh page from a
six-month-old one, and the two questions — how current is the specification,
what rendered it — have different answers when a project stops upgrading.

### FR-VIEW-100 — Any two baselines can be compared on the page

```yaml
status: implemented
verification: T
derives_from: [FR-VIEW-050]
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

The rendered page **shall** let a reader pick any two of the specification's
baselines and see which requirements were added, removed, or had a field or
their statement changed between them.

**Rationale.** The baseline log records what was frozen, not what changed
while freezing it; that answer exists only in `--diff`, which needs a clone.
Comparing an arbitrary pair means the page carries the specification at every
baseline, so it carries it the way a repository does: the oldest baseline in
full and each later one as its change, folded up on demand. Statements travel
as fingerprints — a rewording still shows as a change, without the text of
the whole specification riding along once per baseline.

### FR-VIEW-110 — The graph can be explored

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

The graph on the page **shall** fill the area it is drawn in and
let a reader move and scale it, pull a node aside, return the view to where
it started, and see what a node links to and what links to it.

**Rationale.** A specification of any size draws a graph larger than the
viewport, and a picture that can only be scrolled is a picture nobody
studies. The area is the panel rather than the drawing: sized from the
drawing, a small specification gets a postage stamp to work in and loses a
node past its edge at the first tug — which is also why the view can be
returned, since a node dragged out of sight is otherwise hunted for. Done in
the page's own script rather than with a graph library: the layout is a
layered one this project computes itself — the right shape for a derivation
DAG, and not what a force layout would give — so a library would be paid for
in every reader's download and every installed project, in exchange for
panning and dragging.

### FR-VIEW-120 — The baseline row is written by the tooling

```yaml
status: implemented
verification: T
derives_from: [FR-VIEW-050]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/baseline-smoke.sh]
```

When asked for a baseline row, the viewer **shall** print it ready to paste:
version, date, tag, and what changed since the previous baseline — reading
the working tree, or the tagged revision itself where that tag already
exists.

**Rationale.** Four rows were written by hand into this project's own log,
each time by reading a matrix and reducing a diff — mechanical work that
invites a wrong count nobody would ever notice. Printed rather than written
into the file: the viewer never touches `specs/` (FR-VIEW-080), and a row a
person pastes is a row a person has read. A row asked for after its tag
exists describes that tag rather than whatever the working tree has drifted
to since, so writing it late costs nothing in accuracy.

### FR-VIEW-130 — A requirement is reachable from every view

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

When a requirement is picked from any view of the page — a link in the
dashboard or in a baseline comparison, a node in the graph — the page
**shall** show that requirement, switching to the view that renders it and
clearing whatever filter would hide it.

**Rationale.** Following links in both directions is what this page is for,
and three of its four views could not do it: the dashboard and the baseline
comparison render links whose target lives in a hidden section, so following
one moved the reader nowhere and gave no sign of why. The graph reached it
by its own handler rather than by this rule, which is how it stayed broken
unnoticed when a later change stopped its clicks from firing at all.

### FR-VIEW-140 — The rendered page can be opened where it is made

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

Where opening is asked for, the viewer **shall** open the page it has just
rendered in the reader's browser.

**Rationale.** Rendering and opening are one act for a reader and two
commands with a path between them, and the path differs by platform — which
puts the knowledge in a procedure an agent reads, and leaves whoever works
without one to look it up. The standard library opens a browser in a line,
so the tool can carry it once instead of every reader carrying it forever.

### FR-VIEW-150 — The graph can be narrowed to one requirement's surroundings

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

When a requirement is chosen as the root, the graph **shall** draw only that
requirement and what lies within a chosen number of links of it.

**Rationale.** A drawing of everything is the one view a specification of any
size cannot use, and the tools that solve this converge on the same answer: a
root and a radius, whether it is `root_id` with `root_depth` in
sphinx-needs or impact analysis from a selected item in the commercial
tools. StrictDoc still lists the whole-project view as wanted rather than
done. The page already lights a node's immediate links on hover, which is
this idea stopped one step short — the neighbourhood is computed and then
thrown away instead of becoming the drawing.

### FR-VIEW-160 — Every kind of link is drawn, and the reader chooses which

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

The graph **shall** draw each kind of link between requirements in a form
that tells it from the others, and let the reader leave out the kinds not
wanted.

**Rationale.** Two of the four link fields were drawn and two were not, which
in this specification meant showing twenty-one edges and hiding forty-four:
the reader was studying the minority relation without being told. Drawing
everything and subtracting is what `needflow` does with its `link_types`
option, and it is the safer default — a link that exists and is not drawn is
invisible, while one that is drawn and unwanted is one click away. Layers
stay derived from `derives_from` alone: it is the relation that means
"higher level", and a layer computed from the union would silently change
the vertical axis from abstraction to order of work.
