# Interfaces

`IF-*` — the surfaces other people's tooling binds to. What is written here
cannot change without breaking somebody's pipeline or somebody's agent.

### IF-CI-010 — Exit codes of the installer

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-010]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/adopt-smoke.sh]
```

The installer **shall** exit 0 on success, 1 on checker errors in the target
or completion past adopt's point of no return, 2 when it refused before
changing anything, and 3 when adoption rolled back and the target is
unchanged.

**Rationale.** An agent installing unattended has only the exit code to
decide whether to report success, retry with different answers, or stop and
ask; collapsing "refused" and "rolled back" would lose that distinction.

### IF-CI-020 — Exit codes of the checker

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-120]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/spec-check.sh]
```

The checker **shall** exit 0 when it found nothing to report, 1 on errors —
or on warnings under `--strict` — and 2 when it could not run at all: an
unusable configuration, an unknown flag, or no `specs/` directory.

**Rationale.** CI distinguishes "your specification is wrong" from "the
checker never got as far as reading it": the second is not something a
contributor's change to the specification can cause.

### IF-SKILL-010 — The published entry point for an agent

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-040]
refines: []
conflicts_with: []
code: [.claude/skills/srs-init/SKILL.md, README.md]
tests: []
```

The installation procedure for an agent **shall** remain reachable at the raw
URL of `.claude/skills/srs-init/SKILL.md`, which the repository landing page
carries together with the clone command.

**Rationale.** Handing an agent nothing but the repository URL is the
framework's own distribution channel; the file is cited in released
documentation, so renaming or moving it breaks installs already in the wild.

### IF-SPEC-010 — The requirement block is a stable format

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [specs/README.md, tools/srs_check.py]
tests: []
```

A requirement **shall** be written as a level-three heading, a fenced `yaml`
metadata block of flat keys with scalar or bracketed-list values, a
statement, and an optional rationale — a shape a standard-library parser and
a future external tool can both read.

**Rationale.** The format is deliberately poorer than YAML allows: nesting
and multi-line values would make the files unreadable by the very
line-oriented tools — grep, diff, review — that make a specification in git
worth having.
