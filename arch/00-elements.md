# Elements

The parts this framework is made of.
The format is `README.md` in this directory; the map is generated into `90-map.md`.

### E-010 — The specification checker

```yaml
status: built
carries: [tools/srs_check.py, tools/srs_parse.py, specs/90-traceability.md]
requirements: [CON-SPEC-010, CON-SPEC-030, FR-CHK-010, FR-CHK-020, FR-CHK-030, FR-CHK-040, FR-CHK-050, FR-CHK-055, FR-CHK-060, FR-CHK-070, FR-CHK-075, FR-CHK-080, FR-CHK-090, FR-CHK-100, FR-CHK-110, FR-CHK-120, FR-CHK-130, FR-CHK-140, FR-CHK-150, FR-CHK-160, FR-CHK-170, FR-CHK-180, FR-CHK-190, FR-CHK-200, FR-CHK-210, FR-CHK-220, FR-CHK-230, FR-CHK-240, IF-CI-020, IF-SPEC-010, IF-SPEC-020, INV-SPEC-010, INV-SPEC-020, INV-SPEC-050, NFR-CHK-010, NFR-SPEC-010]
depends_on: []
```

Reads the specification, validates every rule the standard states, and generates the traceability matrix.

**Rationale.** Split from the viewer because the two are used at different moments: this one gates a commit, the other answers a question.
The parser is here rather than beside it because both layers read the same record shape through it (ADR-0019).

### E-020 — The viewer

```yaml
status: built
carries: [tools/srs_view.py]
requirements: [CON-SPEC-030, FR-CHK-160, FR-VIEW-010, FR-VIEW-020, FR-VIEW-030, FR-VIEW-040, FR-VIEW-050, FR-VIEW-060, FR-VIEW-070, FR-VIEW-080, FR-VIEW-090, FR-VIEW-100, FR-VIEW-110, FR-VIEW-120, FR-VIEW-130, FR-VIEW-140, FR-VIEW-150, FR-VIEW-160, FR-VIEW-180, FR-VIEW-190, FR-VIEW-200, FR-VIEW-210, FR-VIEW-220, FR-VIEW-230, FR-VIEW-240, FR-VIEW-250, FR-VIEW-260, FR-VIEW-270, FR-VIEW-280, FR-VIEW-290, FR-VIEW-300, FR-VIEW-310, FR-VIEW-320, FR-VIEW-330, FR-VIEW-340, IF-VIEW-010, INV-SPEC-040, INV-SPEC-050, NFR-SPEC-010, NFR-VIEW-010]
depends_on: [E-010]
```

Projects the same specification for reading: one requirement with its links, what describes a file, what the whole is divided into, the coverage gaps, a citation, and a self-contained page.

**Rationale.** Depends on the checker for the parser and for nothing else.
It never writes to `specs/`, which is what lets a reader run it without asking anyone.

### E-030 — The installer

```yaml
status: built
carries: [tools/srs_init.py, tools/srs_upgrade.py]
requirements: [CON-SPEC-020, CON-SPEC-030, FR-ARCH-120, FR-ARCH-130, FR-ARCH-140, FR-ARCH-150, FR-CHK-210, FR-CI-050, FR-GND-280, FR-GND-290, FR-GND-300, FR-GND-320, FR-GND-480, FR-INIT-010, FR-INIT-020, FR-INIT-030, FR-INIT-040, FR-INIT-050, FR-INIT-060, FR-INIT-070, FR-INIT-080, FR-INIT-090, FR-INIT-100, FR-INIT-110, FR-INIT-120, FR-INIT-130, FR-INIT-140, FR-INIT-150, FR-INIT-160, FR-INIT-170, FR-INIT-180, FR-INIT-190, FR-INIT-200, FR-INIT-210, FR-INIT-220, FR-SKILL-060, FR-SKILL-070, FR-SKILL-080, FR-SKILL-100, FR-SKILL-110, IF-CI-010, NFR-SPEC-010]
depends_on: [E-010]
```

Moves the payload into somebody else's repository and refreshes it later, deciding nothing the maintainer should decide.

**Rationale.** The one part that writes outside its own directory, and the only one that runs in a repository this framework does not own.
Upgrade lives with install because the two share the rules about what is precious and what is ours.

### E-040 — The release and baseline commands

```yaml
status: built
carries: [tools/srs_baseline.py, tools/srs_release.py, tools/srs_dates.py, CHANGELOG.md]
requirements: [CON-SPEC-030, FR-CI-070, FR-INIT-110, FR-SPEC-010, FR-SPEC-020, INV-SPEC-030, INV-SPEC-040, NFR-SPEC-010]
depends_on: [E-010, E-020]
```

Freezes the specification at a milestone, cuts a release of the framework, and dates a specification from its own history.

**Rationale.** Three small commands rather than three parts: each is a step a maintainer takes by hand, each stops before the commit, and none of them is worth a boundary of its own.

### E-050 — The grounds layer

```yaml
status: built
carries: [tools/srs_grounds.py, grounds/README.md, grounds/90-dashboard.md]
requirements: [CON-GND-010, CON-GND-020, CON-GND-030, CON-SPEC-030, FR-GND-010, FR-GND-020, FR-GND-030, FR-GND-040, FR-GND-050, FR-GND-060, FR-GND-070, FR-GND-080, FR-GND-090, FR-GND-100, FR-GND-110, FR-GND-120, FR-GND-130, FR-GND-140, FR-GND-150, FR-GND-160, FR-GND-170, FR-GND-180, FR-GND-190, FR-GND-200, FR-GND-210, FR-GND-220, FR-GND-230, FR-GND-240, FR-GND-250, FR-GND-260, FR-GND-270, FR-GND-310, FR-GND-390, FR-GND-400, FR-GND-410, FR-GND-420, FR-GND-430, FR-GND-450, FR-GND-460, FR-GND-470, FR-GND-490, FR-GND-500, FR-GND-510, FR-GND-520, FR-GND-540, FR-SKILL-020, IF-GND-010, IF-GND-020, IF-GND-030, INV-GND-010, INV-GND-020, INV-GND-030, INV-GND-040, NFR-SPEC-010]
depends_on: [E-010, E-020]
```

The optional register of what the requirements rest on: hypotheses, bets, measurements and the dashboard computed from them.

**Rationale.** A part rather than a feature of the checker: it has its own standard, its own configuration and its own gate, and a project that declines it loses nothing else (ADR-0015).

### E-060 — The architecture layer

```yaml
status: built
carries: [tools/srs_arch.py, arch/README.md]
requirements: [CON-ARCH-010, CON-ARCH-020, CON-SPEC-030, FR-ARCH-010, FR-ARCH-020, FR-ARCH-030, FR-ARCH-040, FR-ARCH-050, FR-ARCH-060, FR-ARCH-070, FR-ARCH-080, FR-ARCH-090, FR-ARCH-100, FR-ARCH-110, FR-ARCH-200, FR-ARCH-210, FR-ARCH-220, FR-ARCH-230, FR-ARCH-240, FR-ARCH-250, FR-ARCH-260, FR-ARCH-270, FR-SKILL-020, IF-ARCH-010, IF-ARCH-020, IF-ARCH-030, IF-ARCH-040, INV-ARCH-010, NFR-SPEC-010]
depends_on: [E-010, E-020]
```

This layer: which parts the system is made of, what each carries, and the disagreements between that description and the specification.

**Rationale.** Built on the same seam as the grounds layer and for the same reason, decided in ADR-0023.

### E-070 — The procedures and the agent guides

```yaml
status: built
carries: [.claude/skills, AGENTS.md, CLAUDE.md]
requirements: [FR-ARCH-150, FR-ARCH-160, FR-ARCH-240, FR-GND-320, FR-GND-330, FR-GND-340, FR-GND-350, FR-GND-360, FR-GND-380, FR-GND-440, FR-GND-500, FR-GND-530, FR-SKILL-010, FR-SKILL-020, FR-SKILL-030, FR-SKILL-040, FR-SKILL-050, FR-SKILL-060, FR-SKILL-070, FR-SKILL-080, FR-SKILL-090, FR-SKILL-100, FR-SKILL-110, FR-SKILL-120, FR-SKILL-130, FR-SKILL-140, FR-SKILL-150, FR-SKILL-160, FR-SKILL-170, FR-SKILL-180, FR-SKILL-190, FR-SKILL-200, FR-SKILL-210, FR-SKILL-220, FR-SKILL-230, FR-SKILL-240, FR-SKILL-250, FR-SKILL-260, FR-SKILL-270, FR-SKILL-280, IF-SKILL-010, INV-SPEC-070, NFR-SKILL-010]
depends_on: []
```

The procedures an agent follows — the everyday loop, authoring, auditing, harvesting, checking, releasing, one per optional layer — and the guides that send it to them.

**Rationale.** Markdown rather than code, which is why they are a part with no module: what they oblige is what they say, and the checker holds them only through the requirements that name them.

### E-100 — The project's own documentation

```yaml
status: built
carries: [README.md, CONTRIBUTING.md, docs]
requirements: [FR-DOC-010, FR-DOC-020, FR-DOC-030, FR-DOC-040, FR-DOC-050, FR-DOC-060, FR-DOC-070, FR-DOC-080, FR-DOC-090, FR-DOC-100, FR-DOC-110, FR-DOC-120, FR-DOC-130, FR-DOC-140, FR-DOC-150, FR-DOC-160, FR-DOC-170, FR-DOC-180, FR-DOC-190, FR-DOC-200, FR-DOC-210, IF-SKILL-010, INV-SPEC-070]
depends_on: []
```

What a person reads before they clone: the landing page, the contribution rules, and the guides under `docs/`.

**Rationale.** Separate from the procedures because the reader is different — a human deciding whether to adopt the framework, not an agent working inside it — and separate from the standard because a change here reaches nobody's specification.

### E-080 — The standard and the payload

```yaml
status: built
carries: [specs/README.md, skeleton]
requirements: [CON-SPEC-020, FR-ARCH-140, FR-GND-300, FR-INIT-220, FR-SKILL-020, FR-SKILL-200, FR-SKILL-220, FR-SKILL-240, IF-SPEC-010, INV-SPEC-010, INV-SPEC-020, INV-SPEC-030, INV-SPEC-040, INV-SPEC-050, INV-SPEC-060, INV-SPEC-070, NFR-SPEC-020]
depends_on: []
```

The normative document on the specification format, and the starter files copied into a project that adopts the framework.

**Rationale.** One part because they answer the same question from two sides — what a specification is, and what a project starts with — and because a change to either is a change a stranger sees.

### E-090 — The gate

```yaml
status: built
carries: [ci, .github/workflows/srs.yml, .githooks, tools/ci_selftest.sh, tools/test_lib.sh, tests]
requirements: [FR-ARCH-170, FR-CI-010, FR-CI-020, FR-CI-030, FR-CI-040, FR-CI-050, FR-CI-060, FR-CI-080, FR-CI-090, FR-CI-100, FR-CI-110, FR-GND-310, FR-GND-370]
depends_on: [E-010, E-050, E-060]
```

What makes the rules binding: the suites, the local pre-commit gate, this repository's pipeline and the templates a target installs.

**Rationale.** Depends on every checker it runs.
The templates live here rather than with the payload because what they contain is this part's business — which suites exist and in what order they run.
