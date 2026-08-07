# Functional requirements — chk

The checker, `tools/srs_check.py`: what it validates, what it generates, and
how it reports. Everything here is observable from a single run.

### FR-CHK-010 — Well-formed and unique identifiers

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

If a requirement identifier is repeated or does not match
`<TYPE>-<AREA>-<NNN>` with an area declared in the configuration, the checker
**shall** report it as an error naming both occurrences.

**Rationale.** Identifiers are the only stable handle on a requirement; a
duplicate silently splits its history in two.

### FR-CHK-020 — Exactly one bolded modal verb

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-090]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

If the statement of a requirement carries no bolded modal verb from the
project lexicon, or carries more than one, the checker **shall** report it as
an error.

**Rationale.** The verb is where binding force lives, and two verbs in one
statement are two requirements — the error message says so, because splitting
them is the fix.

### FR-CHK-030 — Links resolve

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

If a link field names a requirement that does not exist, or names the
requirement itself, the checker **shall** report it as an error.

**Rationale.** A dangling link is worse than no link: it reads as coverage
that was never there.

### FR-CHK-040 — No cycles in the derivation graph

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-030]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

If `derives_from` or `refines` links form a cycle, the checker **shall**
report it as an error listing the requirements on the cycle.

**Rationale.** The derivation graph answers "why does this exist"; a cycle
means the answer is circular, and it also breaks the tree view.

### FR-CHK-050 — Realized requirements point at real code

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

The checker **shall** report as an error a requirement with status
`implemented` and an empty `code` field, and any `code` or `tests` entry that
names a path absent from the repository.

**Rationale.** The two fields are the only machine-checkable bridge between
the specification and the tree; a stale path turns the traceability matrix
into fiction.

### FR-CHK-060 — Lifecycle consistency

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

The checker **shall** report as an error a `superseded` requirement without
`superseded_by`, and a requirement carrying `superseded_by` under any other
status.

**Rationale.** A cancelled requirement without a successor is a dead end for
whoever follows the reference; the reverse pairing is a copy-paste slip.

### FR-CHK-070 — Implementation ahead of approval is a warning

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

When a requirement has status `draft` and a non-empty `code` field, the
checker **shall** warn that implementation ran ahead of approval, and warn
again when an `implemented` or `partial` requirement derives from, depends on
or refines a `draft`.

**Rationale.** This is the approval queue of a harvested specification: the
warning list is exactly what the maintainer has to rule on, which is why it
is a warning and not an error.

### FR-CHK-080 — Annotations are cross-checked, never required

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-050]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

The checker **shall** cross-check the `implements:` and `verifies:`
annotations found under the configured code and test roots against the
specification — never reporting a file that carries none — treating an
annotation that names an unknown requirement in a declared area as an error
and every other mismatch as a warning.

**Rationale.** Annotations are an optional second opinion; making them
mandatory would turn every source file into specification surface.

### FR-CHK-090 — The lexicon, not a language

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/adopt-smoke.sh]
```

The checker **shall** take the modal verbs, negation words and rationale
markers it recognizes from `specs/srs-config.json`, so that a specification
written in any natural language validates on the same rules.

**Rationale.** The one feature that cannot be retrofitted: hard-coding
English would have made every non-English project translate its
specification to use the tooling.

### FR-CHK-100 — A readable failure for a broken configuration

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-090]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

If `specs/srs-config.json` is unreadable, is not a JSON object, or holds a
key whose value is not a list of non-empty strings, the checker **shall**
exit with status 2 after naming the offending key.

**Rationale.** A configuration mistake would otherwise surface as a regex
compilation traceback, which tells the user nothing about what to fix.

### FR-CHK-110 — Code blocks are opaque

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: []
```

While parsing a fenced code block, the checker **shall** ignore headings,
modal verbs and rationale markers inside it.

**Rationale.** The standard itself, and every specification that documents
its own format, contains example requirements; without this they would be
parsed as real ones.

### FR-CHK-120 — Strict mode

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-070]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/spec-check.sh]
```

Where `--strict` is given, the checker **shall** exit non-zero when warnings
were reported even if no error was.

**Rationale.** Warnings that never fail anything accumulate until nobody
reads them; a project decides once, in its CI configuration, whether it
tolerates them.
