# Functional requirements — bel

The belief register: an optional subsystem recording what the requirements
rest on. Beliefs about people, the bets that tie them to requirements, and
the checker that reads both. A project without `beliefs/` has none of this
and is unaffected by all of it.

### FR-BEL-010 — The register is read and reported on

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [IF-BEL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a project carries a belief register, the belief checker **shall** read
every record in it.

**Rationale.** This is the entry the rest of the subsystem hangs from: exit
codes describe this run, the dashboard is what this run produces, and the
constraint on where the tool may write is a constraint on this run. Stating
it separately keeps those from each having to restate what they are about.

Scoped to a project that carries the register, because the layer is optional
in the way `--ci` is optional: a target that declined it has no `beliefs/`
directory, and nothing about its checker, its gate or its skills changes.
The presence of the register is the switch — not a flag recorded somewhere
that can disagree with what is on disk.

Reading is separated from judging on purpose. What counts as an error, a
warning or a silence is the business of the rules, each with its own
requirement and its own name; this one says only that the records are read
and that the run says something about them.
