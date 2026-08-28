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
created: 2026-08-09
```

When freezing a baseline, the baseline command **shall** write the row into
the baseline log and report what to commit — refusing where the log already
has that row, or where the checker reports an error.

**Rationale.** Reading a diff and reducing it to a row is mechanical work
that invites a wrong count nobody would notice, and it is the step that gets
skipped. The command does that step and stops: committing belongs to
whatever client the project uses (CON-SPEC-030), and a `spec/v*` tag is a
bookmark somebody may add afterwards or never. Where such a tag was made
first, the row describes that revision rather than the working tree, so
writing it late costs nothing. And the command ships, because every project
baselines its own specification and has no release machinery of ours to lean
on.

An error and not a warning, which is where this parts company with the
release command (FR-CI-070). A project part-way through describing itself
carries warnings it has not worked off yet, and a baseline is the record of
where it stands — refusing to freeze until the list is empty refuses the
recording, not the mess. What ships is the stricter question, and it is
asked by a different command.

### FR-SPEC-020 — A specification can be dated from its own history

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_dates.py]
tests: [tests/dates-smoke.sh]
created: 2026-08-21
```

Where a requirement carries no `created` date, one command **shall** write
the date its identifier first appeared in the history, leaving every
requirement that already carries one untouched.

**Rationale.** The date a requirement arrived is a fact git already holds
and holds correctly — it cannot be backdated without rewriting history —
but it is only reachable by reading the log, which does not scale and is
not available to a reader working from a snapshot. Written into the block
once, every lifecycle reading afterwards comes off the file in front of it.

Its own command rather than a step in the checker, because this writes
requirement blocks and nothing else here does. `ADR-0009` puts that beyond
the checker deliberately, and the exception is not that this tool is trusted
but that a person runs it on purpose, once, the way a baseline is frozen.

Leaving dated requirements untouched is what makes it safe to run twice. A
second pass over a specification that has already been dated changes
nothing, so nobody has to remember whether it was done.

Read from the history and not from today: a requirement written a year ago
and dated now would carry a date that is simply wrong, and wrong in the
direction that makes the reading useless — every requirement looking new.
