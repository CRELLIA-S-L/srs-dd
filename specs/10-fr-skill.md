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

The `srs` procedure **shall** require naming the requirements a change
belongs to before the code is written, creating one where none exists, and
re-reading their statements as the loop is closed, so that anything built
and not described is written down or taken out.

**Rationale.** Everything else in the framework is downstream of this single
habit; the checker can prove a link exists but never that the change was
thought about first. Both ends are needed, and the second was learned the
hard way: a change that begins as a fix to an existing requirement is exempt
from writing a new one, and that exemption quietly covers whatever else gets
added along the way — a control appeared on the rendered page that no
statement mentioned, because the work was framed as repair and nobody
re-read the requirement it repaired. Re-reading one statement costs a
paragraph; a change that names no requirement at all is itself the signal
that either nothing behavioural happened or the requirement is missing.

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

### FR-SKILL-080 — The baseline procedure travels with the project

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-SPEC-010]
refines: []
conflicts_with: []
code: [.claude/skills/srs-baseline/SKILL.md, tools/srs_init.py]
tests: [tests/installer-smoke.sh]
```

The skills installed into a project **shall** include the baseline
procedure, which shows what changed since the previous baseline and proposes
the version for the maintainer to confirm before the row is written.

**Rationale.** The command is one line, and neither of the two things around
it is the agent's to settle: the number is a claim about the specification,
and the commit that makes the baseline real happens in whatever git client
the project uses (CON-SPEC-030). A procedure is where that sequence lives —
without one, the command leaves an agent guessing at the number and stopping
in the wrong place. It travels because every project baselines its own
specification, unlike `srs-release`, which stays here.

### FR-SKILL-070 — The release procedure travels with the framework

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CI-070]
refines: []
conflicts_with: []
code: [.claude/skills/srs-release/SKILL.md]
tests: [tests/installer-smoke.sh]
```

Before cutting a release, the `srs-release` procedure **shall** have the
agent propose the version number for the maintainer to confirm and draft the
changelog section by its format contract; it stays in the framework
repository and is never installed into a project.

**Rationale.** The command is one line, but two of its inputs are not the
agent's to settle. The version number follows from what actually changed —
an article amended, a shipped file touched, a requirement reworded — and
that reading belongs to the maintainer, exactly as the areas and the lexicon
do in `srs-init`. The changelog section an agent can draft, provided it
knows the rule this project tripped over four times: the first sentence of
every entry stands alone, because the installer prints that sentence and
cuts the rest. Framework-only, like `srs-init`: a target releases nothing of
ours.
