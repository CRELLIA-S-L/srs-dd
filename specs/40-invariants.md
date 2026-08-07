# Invariants and constraints

`INV-*` — properties that hold at all times · `CON-*` — constraints imposed
on the project rather than chosen by it.

### INV-SPEC-010 — Identifiers are immutable and never reused

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CHK-010]
refines: []
conflicts_with: []
code: [specs/README.md, tools/srs_check.py]
tests: []
```

A published requirement identifier **shall** keep its meaning forever: a
cancelled requirement is retained with status `superseded` and a pointer to
its successor, and its number is never given to anything else.

**Rationale.** References to requirements outlive the requirements — in
commit messages, review threads, and other projects' documents. A reused
number turns every one of them into a lie that reads as truth.

### INV-SPEC-020 — Links are stored in one direction only

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CHK-030]
refines: []
conflicts_with: []
code: [specs/README.md, tools/srs_check.py]
tests: []
```

The specification **shall** record only forward links, leaving every reverse
relation to be computed.

**Rationale.** A link written at both ends is a link that will one day
disagree with itself, and nothing would say which end was right.

### CON-SPEC-010 — The traceability matrix is generated

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-050, FR-CI-010]
refines: []
conflicts_with: []
code: [tools/srs_check.py, specs/90-traceability.md]
tests: [tests/spec-check.sh]
```

The traceability matrix **shall** be produced by the checker and committed as
generated output, never edited by hand.

**Rationale.** It is committed so reviewers can read it in a diff, which
makes it the one file in the specification with two possible authors — and
the gate exists to keep the human one out.

### CON-SPEC-020 — Nothing of the framework travels into a target

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-020]
refines: []
conflicts_with: []
code: [tools/srs_init.py, skeleton]
tests: [tests/installer-smoke.sh]
```

What the installer copies **shall not** contain requirement identifiers of
this framework, annotations naming them, or paths that exist only in this
repository.

**Rationale.** ART-070 of the constitution in one sentence: a stranger's
first install has to pass their own checker, and a leaked identifier fails it
in a way they cannot diagnose.
