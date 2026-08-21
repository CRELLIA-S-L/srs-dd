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
code: [tools/srs_check.py, tools/srs_parse.py, tools/srs_grounds.py, tools/srs_dates.py, tools/srs_view.py, tools/srs_init.py, tools/srs_baseline.py, tools/srs_release.py, tools/srs_upgrade.py]
tests: []
created: 2026-08-07
```

Every Python tool in this repository **shall** run on Python 3.9 or newer
using only the standard library.

**Rationale.** The framework is adopted by projects written in every
language; a dependency would drag a package manager, a lockfile and a
supply-chain question into repositories that have no Python of their own.

"Python tool" rather than "tool", because `tools/ci_selftest.sh` is one of
the tools and runs on no Python at all — the sentence bound it to a version
of an interpreter it never starts. The scope is what it always meant, and
saying so settles the question it left open: whether the next tool may be
written in shell. It may, and what binds it then is ART-040, which forbids
a new dependency without an ADR whatever the language. The one dependency
the shell script has is optional and argued where it lives (FR-CI-030): a
missing YAML parser costs that check and nothing else.

Every tool listed, not the three that existed when this was written. The
statement quantifies over all of them and the field named half, so an agent
asking what governs `tools/srs_baseline.py` — the first step of the everyday
loop — was told about baselines and git history and never about this. A
field that answers "where is it realized" with half the answer is worse than
one that answers nothing: the reader stops looking.

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
created: 2026-08-07
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
created: 2026-08-07
```

Where the graph exceeds the node limit the page can lay out, the viewer
**shall** state on the page what was left out rather than truncating
silently.

**Rationale.** A graph that quietly drops nodes is worse than no graph: it
looks complete.

### NFR-CHK-010 — Validation stays under a second at 500 requirements

```yaml
status: implemented
verification: A
derives_from: []
depends_on: [FR-CI-020]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
created: 2026-08-07
```

The checker **shall** validate a specification of 500 requirements in under
one second, interpreter startup included.

**Rationale.** The gate is only respected while it is instant; the moment it
is worth waiting for, it gets skipped. The measurements are logged in
`50-verification.md` — the latest leaves better than an order of magnitude
of headroom for growth and slower machines. The number lives there and not
here, because a figure copied into a rationale is a figure nobody retakes.
