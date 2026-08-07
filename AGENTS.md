# SRS-DD — agent guide for the framework repository

You are in the repository of the SRS-DD framework itself, not in a project
that uses it. Nothing here describes an application: the specification in
`specs/` describes this framework's own tooling.

## Installing SRS-DD into a project

Follow `.claude/skills/srs-init/SKILL.md` — plain markdown, no skill system
required. It covers fresh initialization, adoption of an existing
specification, and upgrades, and it tells you which two decisions are the
maintainer's rather than yours.

```
python3 tools/srs_init.py path/to/project --dry-run
python3 tools/srs_init.py path/to/project [flags]
```

Never run the installer against this repository: it would try to install the
framework into itself. It refuses on its own (`is_inside`), but do not rely
on that.

## What lives where

| Path | What it is |
|---|---|
| `specs/README.md` | The standard itself — the normative document on the specification format. Shipped to every target from here; there is no second copy |
| `specs/` | This framework's own specification: requirements about the checker, the viewer, the installer, the skills and the CI templates |
| `skeleton/` | The payload: starter specification files and the target-facing `AGENTS.md`/`CLAUDE.md`, copied into projects by the installer |
| `tools/` | `srs_check.py` and `srs_view.py` (shipped to targets), `srs_init.py` and `ci_selftest.sh` (framework-only) |
| `tests/` | The suites this repository's pipeline runs; requirements cite them by path |
| `ci/` | CI and pre-commit templates for target projects — not this repository's own pipeline |
| `.claude/skills/` | Agent skills; `srs-init` is framework-only, the rest ship to targets |
| `.gitlab-ci.yml` | This repository's own pipeline. Target projects get theirs from `ci/` |

## Two rules that protect other people's repositories

1. **Nothing framework-specific goes into `skeleton/`.** Requirements about
   this framework's tooling would land in every project installed afterwards,
   pointing at files that do not exist there — a hard checker error on a
   stranger's first install.
2. **Never write `implements:`/`verifies:` annotations into
   `tools/srs_check.py` or `tools/srs_view.py`.** Those two files are copied
   into every target, where this framework's requirement areas are unknown;
   the annotation check would warn, and `--strict` turns warnings into a
   failed pipeline. Link them from the requirement side (the `code` field)
   instead. `tools/srs_init.py`, `tests/` and `ci/` never travel and may be
   annotated freely.

## Working on the framework

This repository is itself an SRS-DD project: behavior changes go through
`specs/` the same way they do in any target — find or create the requirement,
then write the code, then close the loop.

- **Specification rules** — `specs/README.md`.
- **Check** — `python3 tools/srs_check.py` (`--strict` in CI).
- **Read** — `python3 tools/srs_view.py <ID>`, `--code <path>`, `--html`.
- **Local gate** — `tools/ci_selftest.sh` runs the pipeline's jobs locally;
  `git config core.hooksPath .githooks` wires it into `pre-commit`.
- **Contribution and release rules** — `CONTRIBUTING.md`.
