# SRS-DD — spec-driven development on a real SRS

**The specification is the source of truth for what the system does — not the
issue tracker, not the chat log.** Every change that alters behavior names
the numbered requirement it closes, and a script fails the build when it
does not.

`Python ≥ 3.9` · standard library only · plain Markdown · specification in
any language · MIT

This repository is its own example: [`specs/`](specs/) describes the checker,
the viewer and the installer as numbered requirements, and the pipeline
publishes them as a page. For what an ordinary product looks like after
adopting the standard — a small service, a superseded requirement kept for
the record, tests named from both directions — see
[srs-dd-example-urlshortener](https://github.com/CRELLIA-S-L/srs-dd-example-urlshortener).

## The problem

Working with AI coding agents sharpens an old one. An agent will happily
change behavior nobody asked for, and a week later nobody can say whether
the code or the intent is right. A specification with identifiers gives
humans and agents a shared, greppable ground truth: plans cite
`FR-CORE-020`, diffs carry the requirement they close, and drift between
spec and code becomes a checkable error instead of an archaeology project.

## What it looks like

A requirement is a heading, a small YAML block, one statement, and the
reason it exists:

````markdown
### FR-CORE-020 — Autosave on loss of focus

```yaml
status: implemented
verification: T
derives_from: [FR-CORE-010]
code: [src/editor.py]
tests: [tests/test_editor.py]
```

When the editor window loses focus, the system **shall** persist the open
document.

**Rationale.** Users close laptops mid-sentence; an explicit save step is
the most common source of lost work reports.
````

`python3 tools/srs_check.py` then regenerates `specs/90-traceability.md` —
requirement → code → verification, in both directions — and fails on a
dangling link, a status of `implemented` without code paths, a path that
does not exist, or an annotation naming a requirement that was never
written. Softer drift — an annotated file missing from the requirement's
own field — is a warning, and `--strict` turns warnings into failures too.

`python3 tools/srs_view.py --html` writes one self-contained page: search,
filters, a status dashboard, and a graph of the derivation links. No CDN, no
network, opens straight from `file://`.

## Why this and not another spec-driven tool

The form is deliberately boring and standards-based — **ISO/IEC/IEEE 29148**
for the structure, requirement attributes and traceability, **EARS** for the
statement patterns, **MADR** for the decision log — and that is the point:

- **Traceability is enforced, not agreed on.** The matrix is a committed
  artifact; CI regenerates it and compares byte-for-byte.
- **Requirements have immutable identifiers and a lifecycle.** Superseded
  ones are archived, not deleted.
- **The specification can be written in any language.** The tooling reads
  the modal verbs it enforces from a per-project lexicon —
  [docs/multilingual.md](docs/multilingual.md).
- **Nothing to install.** Two dependency-free Python scripts in your
  repository; no server, no database, no toolchain.
- **Agent-agnostic, and optional.** `AGENTS.md` is read natively by Cursor,
  Codex, Gemini CLI and Copilot; the skills are plain markdown; a team
  working entirely by hand loses nothing.

## Install

<!-- canonical-url: keep in sync with the block below -->

```
git clone https://github.com/CRELLIA-S-L/srs-dd.git
python3 srs-dd/tools/srs_init.py path/to/your-project
```

It asks for the project name, requirement areas, code and test roots, source
extensions, a CI template and the lexicon — then lays out `specs/`, writes
the config, generates a placeholder requirement and runs the checker in your
repository. `--defaults` answers everything; `--dry-run` writes nothing and
prints the exact created / refreshed / skipped list first.

**Already have an SRS?** The installer detects it and switches to adopt
mode: your spec is validated against the proposed configuration *before*
anything is touched, and on failure the target is left byte-identical. Your
specification files are never modified.

**Already run a pre-commit hook?** It is never displaced — the installer
says so instead of advising the `core.hooksPath` switch that would silently
disable it.

Details, modes, exit codes and the manual path: [docs/install.md](docs/install.md).
Upgrades: [docs/upgrade.md](docs/upgrade.md).

## Handing this to an agent

Point a coding agent at this repository and it can install the framework
itself. The procedure is `.claude/skills/srs-init/SKILL.md` — plain
markdown, no skill system required:

<!-- canonical-url: the published entry point; see CONTRIBUTING.md -->

```
https://raw.githubusercontent.com/CRELLIA-S-L/srs-dd/main/.claude/skills/srs-init/SKILL.md
```

Clone rather than fetch that one file: the installer copies the skeleton,
the skills and the CI templates out of the clone. Nothing beyond `git` and
`python3` is needed.

```
rm -rf /tmp/srs-dd    # so a second attempt does not trip over the clone
git clone --depth 1 https://github.com/CRELLIA-S-L/srs-dd.git /tmp/srs-dd
python3 /tmp/srs-dd/tools/srs_init.py path/to/project --dry-run
python3 /tmp/srs-dd/tools/srs_init.py path/to/project [flags]
```

Add `--branch vX.Y.Z` to the clone to pin a release. `--dry-run` lets the
maintainer see the change before it happens; the installer detects the mode
itself — fresh, adopt or upgrade — and adopt is transactional.

```
0  installed
1  checker errors, or partial completion past adopt's point of no return
2  refused before changing anything
3  adopt rolled back, target untouched
```

Two decisions are not the agent's to make alone, and the skill says so: the
**requirement areas** — the middle segment of every identifier, and
identifiers are immutable — and the **lexicon**, which words carry which
binding force. The agent proposes; the maintainer confirms. More:
[docs/agents.md](docs/agents.md).

## The loop

Every task that changes behavior goes through the same five steps:

1. **Requirement before code.** If a task changes behavior it has a
   requirement — otherwise there is no way to tell when it is finished.
2. **Plans reference numbers.** `FR-DATA-050`, not “fix the storage layer”.
3. **Code.**
4. **Close the loop.** Status to `implemented`, `code` and `tests` filled
   with real paths, in the same set of edits as the code.
5. **Check.** `python3 tools/srs_check.py`, locally and in CI.

What a linter cannot check — behavior over implementation, verifiability,
unambiguity — is still binding; those rules live in `specs/README.md`, and
the `srs-audit` skill covers the semantic side.

## Reading the specification

```
python3 tools/srs_view.py FR-CORE-020        one requirement, links resolved
python3 tools/srs_view.py --code src/app.py  which requirements describe a file
python3 tools/srs_view.py --tree FR-CORE-010 what derives from it
python3 tools/srs_view.py --coverage         no tests, code outside the spec, …
python3 tools/srs_view.py --diff spec/v0.1.0 working tree against a baseline
python3 tools/srs_view.py --html             a page for people who do not grep
```

The viewer never writes to `specs/` and never gates anything.

## Where things are

| Path | What it is |
|---|---|
| `specs/README.md` | The standard: markup rules, identifier scheme, lifecycle, annotations, baselines, configuration |
| `specs/` | This framework's own specification — it uses itself |
| `skeleton/` | What the installer copies into your project |
| `tools/` | `srs_check.py`, `srs_view.py` (yours after install), `srs_init.py` (stays here) |
| `.claude/skills/` | `srs`, `srs-new`, `srs-audit`, `srs-harvest`, and `srs-init` (framework-only) |
| `tests/` | The suites this repository runs on itself; its requirements cite them by path |
| `ci/` | CI templates and a pre-commit hook for target projects |
| `docs/` | [install](docs/install.md) · [upgrade](docs/upgrade.md) · [agents](docs/agents.md) · [any language](docs/multilingual.md) |
| `CONTRIBUTING.md`, `CHANGELOG.md` | Framework governance and versioning |
