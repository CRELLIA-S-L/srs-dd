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
