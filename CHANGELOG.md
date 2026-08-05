# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions are framework releases, tagged `vX.Y.Z`; the same number is
embedded in `tools/srs_check.py` as `__version__`.

<!-- Format contract, relied upon by tools/srs_init.py when printing
     upgrade notes: a version section starts with `## [X.Y.Z]`; its
     upgrade notes are the lines after a `### Upgrade notes` heading up
     to the next `##`/`###` heading. Keep that shape. -->

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
