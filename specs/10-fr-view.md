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
depends_on: []
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

When given a git revision, the viewer **shall** print how the specification
changed since it: requirements added, removed, and the fields that differ.

**Rationale.** A baseline is only useful if the difference from it can be
read; a raw `git diff` of the specification is dominated by reflow.

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
HTML file — search, filters, a status dashboard, a layered graph of the
derivation links, and links in both directions — that requests nothing over
the network.

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
depends_on: []
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

The rendered page **shall** state the specification's current baseline and
the framework version that generated it.

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

The derivation graph on the page **shall** let a reader move and scale it,
pull a node aside, and see what a node links to and what links to it.

**Rationale.** A specification of any size draws a graph larger than the
viewport, and a picture that can only be scrolled is a picture nobody
studies. Done in the page's own script rather than with a graph library: the
layout is a layered one this project computes itself — the right shape for a
derivation DAG, and not what a force layout would give — so a library would
be paid for in every reader's download and every installed project, in
exchange for panning and dragging.
