# Functional requirements — spec

The specification's own lifecycle: the acts that freeze it, and the tooling
that performs them. Everything here travels to a project that adopts the
framework, because every project baselines its own specification.

### FR-SPEC-010 — Freezing a baseline is one command

```yaml
status: implemented
verification: T
derives_from: [INV-SPEC-030]
depends_on: [FR-VIEW-120]
refines: []
conflicts_with: []
code: [tools/srs_baseline.py]
tests: [tests/baseline-smoke.sh]
```

When freezing a baseline, the baseline command **shall** write the row into
the baseline log and report what to commit — refusing where the log already
has that row, or where the specification does not pass the checker.

**Rationale.** Reading a diff and reducing it to a row is mechanical work
that invites a wrong count nobody would notice, and it is the step that gets
skipped. The command does that step and stops: committing belongs to
whatever client the project uses (CON-SPEC-030), and a `spec/v*` tag is a
bookmark somebody may add afterwards or never. Where such a tag was made
first, the row describes that revision rather than the working tree, so
writing it late costs nothing. And the command ships, because every project
baselines its own specification and has no release machinery of ours to lean
on.
