# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions are framework releases, tagged `vX.Y.Z`; the same number is
embedded in `tools/srs_check.py` as `__version__`.

<!-- Format contract, relied upon by tools/srs_init.py when printing
     upgrade notes: a version section starts with `## [X.Y.Z]`; its
     upgrade notes are the lines after a `### Upgrade notes` heading up
     to the next `##`/`###` heading. Keep that shape. -->

## [0.7.2] — 2026-08-08

### Added

- The specification is published: <https://crellia-s-l.github.io/srs-dd/>.
  The page is rendered on the default branch, only after the suites pass —
  a page is worth serving exactly when what it renders is valid — and its
  code links point at the commit it was built from rather than at a moving
  branch. FR-CI-040 is `implemented`.

### Changed

- Every GitHub Action moved to its current major: `checkout` v4 → v7,
  `setup-python` v5 → v7, `upload-artifact` v4 → v7, `configure-pages`
  v5 → v6, `upload-pages-artifact` v3 → v5, `deploy-pages` v4 → v5.
  GitHub already forces the Node 20 actions onto Node 24 and will stop
  doing so. `ci/github-workflow.yml` — the template installed into target
  projects — is bumped with them, including its commented Pages block.

### Upgrade notes

- If your project runs the `.github/workflows/srs.yml` this framework
  installed, its actions are on the retiring Node 20 runtime. That file is
  precious, so an upgrade will not touch it: refresh it with `--force`, or
  edit it by hand to `actions/checkout@v7`, `actions/setup-python@v7`,
  `actions/upload-artifact@v7`, `actions/configure-pages@v6`,
  `actions/upload-pages-artifact@v5`, `actions/deploy-pages@v5`.
  A GitLab project is unaffected.

## [0.7.1] — 2026-08-07

### Changed

- The repository moved to GitHub, and the canonical URLs moved with it:
  the clone command, and the raw entry point an agent is handed, now
  `raw.githubusercontent.com/CRELLIA-S-L/srs-dd/main/.claude/skills/srs-init/SKILL.md`.
  The `repo_url` in `specs/srs-config.json` moved too, so the code links
  on the rendered page point at the new host.
- `.github/workflows/srs.yml` is the framework's own pipeline;
  `.gitlab-ci.yml` is removed. The GitLab template for target projects
  (`ci/gitlab-ci.yml`) stays — a project on GitLab is still installed
  with one.
- `tools/ci_selftest.sh` no longer derives the local gate from a CI
  configuration. It parses the YAML of the pipeline and of the shipped
  templates, then runs `tests/*.sh` directly — the same scripts CI runs,
  so the two cannot drift apart, and the skip list it used to need is
  gone. Two consequences worth knowing: a machine without `ruby` now
  loses the YAML parse alone instead of skipping the whole run with a
  zero exit, and the parse happens first, because a suite fails routinely
  on a regenerated matrix that is not staged yet and that must not hide a
  broken template.
- FR-CI-040 stands at `partial`: the specification is rendered on every
  run and kept as a build artifact, but nothing serves it until GitHub
  Pages is enabled for the repository. The workflow carries the three
  steps for it, commented out — enabling them before the setting exists
  turns the pipeline red.

### Upgrade notes

- Nothing in a target changes: the checker, the viewer, the skills and
  the templates are byte-identical to 0.7.0 apart from the version
  string. Re-running the installer is optional.
- If you saved the old GitLab raw URL of `srs-init/SKILL.md` — in a
  runbook, a prompt, or an agent's memory — replace it with
  `https://raw.githubusercontent.com/CRELLIA-S-L/srs-dd/main/.claude/skills/srs-init/SKILL.md`.
  The old host no longer serves this project.

## [0.7.0] — 2026-08-07

### Added

- The framework now has a specification of its own: 54 requirements in
  `specs/` describing the checker, the viewer, the installer, the agent
  procedures and the gates, across six areas — `SPEC`, `CHK`, `VIEW`,
  `INIT`, `SKILL`, `CI`. Mined from the code with the `srs-harvest`
  procedure and approved in one batch. The repository is now an SRS-DD
  project like any other, which is also the framework's own example.
- `skeleton/` — the payload the installer copies into a target, separated
  from the framework's own files. Requirements about our tooling can no
  longer travel into somebody's project, which ART-070 of
  `specs/constitution.md` now states as a standing principle and
  `tests/installer-smoke.sh` asserts on every run.
- `tests/` — the four suites the pipeline runs (`spec-check`,
  `installer-smoke`, `adopt-smoke`, `view-smoke`), moved out of the CI
  configuration so requirements can cite them by path; the pipeline's
  jobs are one-line calls to them.
- A `pages` job renders this repository's own specification on the
  default branch.
- A worked example lives in its own repository,
  `srs-dd-example-urlshortener`: an ordinary product with eleven
  requirements, one of them superseded and kept for the record. The
  pipeline checks it as a downstream consumer (FR-CI-060, advisory), and
  its own CI runs against this framework's `main` — so a change that
  stops accepting a valid specification surfaces there rather than in a
  stranger's project.
- `docs/` — install, upgrade, agents, and a demonstration of a
  specification written in another language, moved out of the README.
- `specs/adr/` — five decisions that had been taken but never written
  down: the English-only framework with per-project lexicons, the
  committed traceability matrix, the standard-library-only rule, the
  `skeleton/` split, and the choice of a classic SRS over the agentic
  spec formats.

### Changed

- The root `AGENTS.md` and `CLAUDE.md` now describe the framework
  repository itself. The target-facing templates live in
  `skeleton/AGENTS.md` and `skeleton/CLAUDE.md`; the installer copies
  them from there. An agent handed this repository's URL no longer reads
  a guide meant for somebody else's project.
- `README.md` is a landing page: what the framework is for, what a
  requirement looks like, and how to install it. Reference material moved
  to `docs/`. The canonical clone and raw-skill URLs stay on it, marked
  with `canonical-url` comments.
- `specs/README.md` — the standard itself — remains the single canonical
  copy and still ships from `specs/`; only the starter files moved to
  `skeleton/`.
- The `srs-init` procedure now diffs a target's agent guides against
  `skeleton/`, not against this repository's root copies.
- The `srs-audit` procedure lists all four sections `--coverage` prints.

### Fixed

- `tools/srs_check.py` carried two example annotations in its own header
  comment without `srs-ignore`. In a target that put `tools` in
  `code_roots`, the shipped checker reported an error against itself
  (`annotation references unknown requirement FR-UI-020`). Both example
  lines are now exempt.
- `specs/README.md` pointed at "the repository README" for the viewer's
  modes — a file that does not exist in a target. It now points at
  `srs_view.py --help`.

### Upgrade notes

- Re-run the installer as usual; nothing in a target changes shape. The
  refreshed `tools/srs_check.py` no longer reports an annotation error
  against its own header comment, so a project that put `tools` in
  `code_roots` and worked around that can drop the workaround.
- If you script against a framework **clone**, note that the skeleton
  moved: `skeleton/specs/`, `skeleton/AGENTS.md`, `skeleton/CLAUDE.md`.
  Installed targets are unaffected.
- Two questions are recorded in `specs/91-open-issues.md` rather than
  silently resolved: the checker's individual rules have no rule-level
  tests, and an area holds at most 99 requirements because identifiers
  carry exactly three digits.

## [0.6.0] — 2026-08-06

### Added

- `--dry-run` for `tools/srs_init.py`: writes nothing at all and prints
  the created / refreshed / skipped list the real run would produce, in
  every mode. A maintainer — or an agent proposing an install — sees the
  change before it happens. In adopt mode the existing specification is
  not validated under `--dry-run` (that needs the checker running inside
  the target); the real run validates first and leaves the target
  byte-identical when validation fails.
- "Handing this to an agent" in `README.md`: the entry point for a
  coding agent given nothing but the repository URL. Points at
  `.claude/skills/srs-init/SKILL.md` as the procedure, gives the
  clone-and-run one-liner (`git` and `python3` are the only
  prerequisites), the release-pinning form, the exit codes, and states
  which two decisions — requirement areas and the lexicon — the agent
  must bring back to the maintainer instead of settling itself.

### Changed

- The pre-commit gate no longer assumes it owns `pre-commit`. The
  installer reads `core.hooksPath`, looks for an existing hook and for
  husky or the pre-commit framework, and when the repository already
  runs something it says so instead of advising the `core.hooksPath`
  switch — which would have silently disabled it. Your hook calls the
  gate (`sh .githooks/pre-commit || exit 1`); when
  `.githooks/pre-commit` is itself yours, the gate is installed beside it as
  `.githooks/pre-commit.srs-dd`. Existing hooks were never overwritten
  before either; what was missing was the advice not to shadow them.
- The README's first section says what the framework is for: codebases
  written with AI coding agents, without depending on one. The argument
  itself stays where it was, at the end.
- The `srs-init` skill runs the installer with `--dry-run` first and
  shows the file list before installing — the same approval shape it
  already required for the lexicon.

### Fixed

- `tools/srs_init.py` no longer writes `__pycache__` into the framework
  clone. A cached module is validated by modification time and size
  alone, so a version string that changes without changing the file
  size could be served stale — the installer then reported, and picked
  upgrade notes for, a version other than the one it was installing.

### Upgrade notes

- Nothing to do. `--dry-run` is a new flag; no existing command changes
  behavior, and the checker is untouched apart from its version string.
- If you were told to run `git config core.hooksPath .githooks` by an
  earlier version and your repository had a hook of its own, check
  `git config --get core.hooksPath` — that setting redirects every hook,
  so the old one has not been running since.

## [0.5.0] — 2026-08-06

### Added

- `tools/srs_view.py` — a viewer for the specification the checker
  validates, on the same dependency budget (standard library, Python
  ≥ 3.9) and sharing its parser. Read-only: it never writes into
  `specs/` and never gates anything.
  - Terminal: one requirement with every link resolved in both
    directions; `--list` with filters; `--code <path>` — which
    requirements describe a file, by the `code`/`tests` fields and by
    the file's own `implements:`/`verifies:` annotations; `--tree`;
    `--coverage`; `--json`.
  - `--html` — one self-contained page (default `.srs-site/index.html`,
    a directory that ignores itself): search, filters, clickable links,
    a status dashboard, and a layered graph of the derivation links.
    No CDN, no fonts, no network; opens from `file://`.
  - `--diff <rev>` — the working tree against a baseline revision,
    per requirement and per field, with a unified diff of the statement.
- `repo_url` in `specs/srs-config.json` (or `--repo-url`): the blob-URL
  prefix that turns `code` and `tests` paths into links to your forge.
  Viewer-only — the checker ignores keys it does not know.
- CI templates render the page: `spec-site` in `ci/gitlab-ci.yml` (one
  rename from GitLab Pages) and an artifact upload in
  `ci/github-workflow.yml` (a commented block switches it to Pages).

### Changed

- `tools/srs_check.py` gained `parse_text()` beside `parse_file()` and
  now records each requirement's rationale. Both are additive: the
  checks, the warnings and the generated matrix are unchanged
  byte-for-byte.

### Fixed

- A specification file that is not readable UTF-8 (an editor saving
  cp1251, say) is now reported as an error naming the file, in the
  checker, instead of ending the run with a decoding traceback. The
  viewer reports it as a problem and shows the remaining requirements.
- The installer ships only `.md`, `.json` and `.gitkeep` from `specs/`
  as skeleton content — anything a maintainer generates under `specs/`
  in their clone no longer travels into fresh targets.

### Upgrade notes

- Re-run the installer: `tools/srs_view.py` arrives beside the refreshed
  checker. The two must stay in step — the viewer uses the checker's
  parser and says so if it finds an older one.
- The new CI job and the `AGENTS.md` line about the viewer are in
  precious files: they reach an initialized project only with `--force`
  (CI) or a manual merge (`AGENTS.md`, or the guided `srs-init` upgrade).
  The skills carry the same advice and refresh on their own.
- `.srs-site/` writes a `.gitignore` that ignores the directory itself,
  so nothing needs adding to yours.

## [0.4.0] — 2026-08-05

### Added

- Planning in the `srs` skill: a "Planning multi-requirement work"
  section — dependency-ordered plans whose steps cite requirement IDs
  and constitution articles, `draft` requirements flagged as approval
  blockers (ART-020), plans kept in the conversation and never written
  into `specs/`.
- Test adequacy in the `srs-audit` skill: decompose an EARS statement
  into trigger, state, and constraint; derive the implied test cases
  (including property-style ones for quantified constraints); map them
  against the `tests` field and report gaps. `verification: T` only;
  on explicit request the skill may author the missing tests (the one
  exception to its read-only rule).
- Agent-doc merge in the `srs-init` skill: the guided upgrade now offers
  an LLM-performed merge of the target's `CLAUDE.md`/`AGENTS.md` with
  the framework versions — SRS-DD-marked files only, shown before
  applying, local content preserved.
- "Other coding agents" documentation: `AGENTS.md` is the cross-agent
  entry point (read natively by Cursor, Codex, Gemini CLI, Copilot);
  skills are plain markdown readable without a skill system; a two-line
  pointer snippet for tools that want their own rules file.

### Upgrade notes

- Re-run the installer — the enriched `srs` and `srs-audit` skills
  refresh automatically.
- `CLAUDE.md` and `AGENTS.md` are still not auto-refreshed: run the
  guided upgrade (`srs-init` skill, from a framework clone) to have the
  agent merge the doc changes, or merge manually. The framework copies
  gained a skills note (`AGENTS.md`) and updated skill mentions
  (`CLAUDE.md`).

## [0.3.0] — 2026-08-05

### Added

- Client pre-commit gate: the installer ships `ci/pre-commit` into
  targets as `.githooks/pre-commit` (all three modes, precious). It runs
  the checker and fails when the committed traceability matrix is
  stale — the same gate CI enforces, caught before the commit.
  Activation is one command, printed by the installer:
  `git config core.hooksPath .githooks`.

### Upgrade notes

- Re-run the installer to receive `.githooks/pre-commit`, then activate
  it once: `git config core.hooksPath .githooks`.

## [0.2.0] — 2026-08-05

### Added

- **Adopt mode** in `tools/srs_init.py`: installing into a project that
  already has an SRS-shaped specification. The spec is validated against
  the proposed configuration before anything changes; on failure the
  target is left untouched (exit 3). Only tooling and missing service
  files are installed. `--mode fresh|adopt` overrides detection.
- Upgrade mode prints the checker version transition
  (`checker 0.1.0 → 0.2.0`) and the relevant CHANGELOG upgrade notes.
- `srs-harvest` skill — mine a specification from an existing codebase
  as approved batches of `draft` requirements; shipped to targets.
- Lifecycle rule: a `draft` recorded for already-existing behavior is
  approved straight into `implemented`/`partial`.

### Changed

- In **upgrade and adopt** modes the checker and the skills refresh
  without `--force`. Fresh mode stays conservative; precious files
  (CI config, CLAUDE.md/AGENTS.md, .gitattributes) still require
  `--force` plus the SRS-DD marker.

### Upgrade notes

- Re-running the installer on an initialized target now refreshes
  `tools/srs_check.py` and the skills automatically — review the
  `refreshed:` list in its output.
- After upgrading, commit the refreshed tooling together with the
  regenerated `specs/90-traceability.md`, or the CI freshness gate will
  fail on the next push.

## [0.1.0] — 2026-08-05

First release of SRS-DD as a reusable framework.

### Added

- Normative specification rules (`specs/README.md`): ISO/IEC/IEEE 29148
  structure, EARS phrasing, MADR decision log; requirement lifecycle with
  `draft`; annotations (`implements:` / `verifies:`); baselines; project
  configuration with a language-independent lexicon.
- `tools/srs_check.py` — integrity checker and traceability generator:
  config-driven areas, roots, and lexicon; annotation cross-checking;
  `--strict` and `--no-write` flags.
- `tools/srs_init.py` — installer for target repositories with
  interactive and non-interactive modes, collision handling, and an
  upgrade mode for already-initialized targets.
- Agent integration: `AGENTS.md` (canonical), thin `CLAUDE.md`, skills
  `srs`, `srs-new`, `srs-init`, `srs-audit`.
- CI templates in `ci/` (GitHub Actions, GitLab CI) with a
  traceability-freshness gate; `.gitattributes` pinning the matrix to LF.
- `specs/constitution.md` v1.1.0 — standing engineering principles.

### Upgrade notes

- After updating `tools/srs_check.py` in a target project, regenerate
  `specs/90-traceability.md`: the status table gained `draft` and its
  rows now follow lifecycle order.
