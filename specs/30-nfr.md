# Non-functional requirements

`NFR-*` — what the tooling costs to run and to depend on.

### NFR-SPEC-010 — Nothing to install

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py, tools/srs_view.py, tools/srs_init.py]
tests: []
```

Every tool in this repository **shall** run on Python 3.9 or newer using only
the standard library.

**Rationale.** The framework is adopted by projects written in every
language; a dependency would drag a package manager, a lockfile and a
supply-chain question into repositories that have no Python of their own.

### NFR-SPEC-020 — Plain text all the way down

```yaml
status: implemented
verification: I
derives_from: [NFR-SPEC-010]
depends_on: []
refines: []
conflicts_with: []
code: [specs/README.md]
tests: []
```

The specification **shall** be stored as markdown files that a review tool
diffs line by line, with no database and no build step between the author and
the file.

**Rationale.** Requirements survive the tool that made them only if they are
readable without it — this one included.

### NFR-VIEW-010 — The page stays readable at scale

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: []
```

Where the derivation graph exceeds the node limit the page can lay out, the
viewer **shall** state on the page what was left out rather than truncating
silently.

**Rationale.** A graph that quietly drops nodes is worse than no graph: it
looks complete.

### NFR-CHK-010 — Validation stays under a second at 500 requirements

```yaml
status: implemented
verification: A
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

The checker **shall** validate a specification of 500 requirements in under
one second, interpreter startup included.

**Rationale.** The gate is only respected while it is instant; the moment it
is worth waiting for, it gets skipped. Measured at 45 ms for 500 requirements
(2026-08-06), so the bound leaves an order of magnitude of headroom for
growth and slower machines.
