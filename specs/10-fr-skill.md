# Functional requirements — skill

The agent procedures in `.claude/skills/`. They are plain markdown read by
whatever tool the project uses, so their behavior is what they oblige an
agent to do, not code that runs.

### FR-SKILL-010 — The everyday loop

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [.claude/skills/srs/SKILL.md]
tests: []
```

Before changing behavior, the `srs` procedure **shall** require finding the
requirements that describe it, and require creating one when none exists.

**Rationale.** Everything else in the framework is downstream of this single
habit; the checker can prove a link exists but never that the change was
thought about first.

### FR-SKILL-020 — Rules are stated once

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-010]
refines: []
conflicts_with: []
code: [.claude/skills/srs/SKILL.md, specs/README.md]
tests: []
```

The skills **shall** point at `specs/README.md` for the markup rules instead
of restating them.

**Rationale.** Two copies of the same rule diverge, and the copy an agent
happens to read wins — which is the failure mode this whole framework exists
to prevent.

### FR-SKILL-030 — Harvesting proposes, the maintainer approves

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [.claude/skills/srs-harvest/SKILL.md]
tests: []
```

The `srs-harvest` procedure **shall** write requirements only in batches
shown to the maintainer beforehand, with status `draft` and without inventing
tests that do not exist.

**Rationale.** A mined specification is a reading of the code, not a
decision; the draft status makes the warning list the approval queue.

### FR-SKILL-040 — Setup brings two decisions back to the maintainer

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-INIT-090]
refines: []
conflicts_with: []
code: [.claude/skills/srs-init/SKILL.md]
tests: []
```

The `srs-init` procedure **shall** have the agent show the requirement areas
and the generated lexicon to the maintainer, together with the dry-run
install list, and install only after they approve.

**Rationale.** Areas are the middle segment of every identifier and
identifiers are immutable; the lexicon decides which words bind. Both are
normative for the target project forever, so neither is settled by whoever
happens to be driving the agent.

### FR-SKILL-050 — An audit reports, it does not repair

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [.claude/skills/srs-audit/SKILL.md]
tests: []
```

The `srs-audit` procedure **shall** report drift between the specification
and the code without changing either side on its own.

**Rationale.** When the two disagree it is unknown which one is wrong, and
that is the maintainer's call — a helpful fix here would silently pick a
side.

### FR-SKILL-060 — The upgrade procedure travels with the project

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-120]
refines: []
conflicts_with: []
code: [.claude/skills/srs-upgrade/SKILL.md, tools/srs_init.py]
tests: [tests/upgrade-smoke.sh]
```

The skills installed into a project **shall** include the upgrade procedure,
so that an agent working there can upgrade the framework without being told
where it lives.

**Rationale.** `srs-init` stays framework-only by design — it installs into
somebody else's repository. Upgrading is the one part of it a project needs
to carry itself, and until now nothing in an installed project mentioned
upgrades at all.
