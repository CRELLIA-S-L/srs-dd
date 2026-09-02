# SRS-DD — agent guide for the framework repository

You are in the repository of the SRS-DD framework itself, not in a project that uses it.
Nothing here describes an application: the specification in `specs/` describes this framework's own tooling.

## Installing SRS-DD into a project

Follow `.claude/skills/srs-init/SKILL.md` — plain markdown, no skill system required.
It covers fresh initialization, adoption of an existing specification, and upgrades, and it tells you which two decisions are the maintainer's rather than yours.

```
python3 tools/srs_init.py path/to/project --dry-run
python3 tools/srs_init.py path/to/project [flags]
```

Never run the installer against this repository: it would try to install the framework into itself.
It refuses on its own (`is_inside`), but do not rely on that.

## What lives where

| Path | What it is |
|---|---|
| `specs/README.md` | The standard itself — the normative document on the specification format. Shipped to every target from here; there is no second copy |
| `specs/` | This framework's own specification: requirements about the checker, the viewer, the installer, the skills and the CI templates |
| `skeleton/` | The payload: starter specification files and the target-facing `AGENTS.md`/`CLAUDE.md`, copied into projects by the installer |
| `tools/` | `srs_check.py`, `srs_parse.py`, `srs_view.py`, `srs_upgrade.py`, `srs_baseline.py`, `srs_dates.py` (shipped to targets), `srs_grounds.py` (shipped where a project keeps a register), `srs_arch.py` (shipped where a project keeps an architecture layer), `srs_init.py`, `srs_release.py` and `ci_selftest.sh` (framework-only) |
| `tests/` | The suites this repository's pipeline runs; requirements cite them by path |
| `ci/` | CI and pre-commit templates for target projects — not this repository's own pipeline |
| `.claude/skills/` | Agent skills; `srs-init` and `srs-release` are framework-only, the rest ship to targets |
| `.github/workflows/srs.yml` | This repository's own pipeline. Target projects get theirs from `ci/` |

## Two rules that protect other people's repositories

1. **Nothing framework-specific goes into `skeleton/`.**
   Requirements about this framework's tooling would land in every project installed afterwards, pointing at files that do not exist there — a hard checker error on a stranger's first install.
2. **Annotate the shipped tooling like anything else — the installer takes the annotations out on the way into a target.**
   Every tool under `tools/` carries `implements:`/`verifies:` lines and should: they are the second half of the two-way check this repository runs on itself, and it runs here, where the requirements are.
   `tools/srs_init.py` replaces each one as it copies (FR-INIT-180), leaving the line in place so line numbers match, so nothing of ours reaches a stranger's checker.
   The one thing not to do is mark such a line `srs-ignore` to quiet something: the exemption is unconditional and silences the annotation here too, which is the whole of what it was for.
   `srs-ignore` marks an example, never a claim.

## Working on the framework

This repository is itself an SRS-DD project: behavior changes go through `specs/` the same way they do in any target — find or create the requirement, then write the code, then close the loop.

- **Specification rules** — `specs/README.md`.
- **Check** — `python3 tools/srs_check.py` (`--strict` in CI).
- **Line width** — the rule and its reasons are in `CONTRIBUTING.md` under *Ground rules*; read it before reformatting anything.
  Markdown is not wrapped to a width, and where a markdown line may break is INV-SPEC-070.
  `tests/line-width.sh` refuses what it forbids (FR-CI-100).
- **Read** — `python3 tools/srs_view.py <ID>`, `--code <path>`, `--html`.
- **Naming a requirement to a person** — give its title, the file it is written in and its status the first time it appears, and do not type them by hand: `python3 tools/srs_view.py --cite <ID>…` prints the citation ready to paste — `FR-CI-100 — The gate refuses a source line nobody had to write long (specs/10-fr-ci.md, implemented)`.
  The identifier alone is a key, not a name, and costs the reader a lookup per mention.
  Afterwards the number on its own is enough.
  The rule holds in a table, in a list and in the steps of a plan; a number the specification does not carry yet is a proposal and is marked as one instead (FR-SKILL-200).
- **Reading the code behind a change** — take the files from the `code` and `tests` fields of the requirements the change belongs to, not from a search over the repository.
  Go wider where you must, and say where you went (FR-SKILL-220).
- **Local gate** — `tools/ci_selftest.sh` runs the same suites CI does;
  `git config core.hooksPath .githooks` wires it into `pre-commit`.
- **Cut a release** — the `srs-release` procedure; it decides nothing about the version or the notes on its own.
- **Contribution and release rules** — `CONTRIBUTING.md`.
