# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions are framework releases, tagged `vX.Y.Z`; the same number is
embedded in `tools/srs_check.py` as `__version__`.

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
