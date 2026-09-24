# SRS-DD — agent guide for the framework repository

You are in the repository of the SRS-DD framework itself, not in a project that uses it.
Nothing here describes an application: the specification in `specs/` describes this framework's own tooling.

## Installing SRS-DD into a project

Follow `.claude/skills/srs-init/SKILL.md` — plain markdown, no skill system required; it covers fresh initialization, adoption of an existing specification, and upgrades, and says which two decisions are the maintainer's.

```
python3 tools/srs_init.py path/to/project --dry-run
python3 tools/srs_init.py path/to/project [flags]
```

Never run the installer against this repository: it would install the framework into itself. It refuses on its own (`is_inside`); do not rely on that.

## What lives where

| Path | What it is |
|---|---|
| `specs/README.md` | The standard itself — the normative document on the specification format. Shipped to every target from here; there is no second copy |
| `specs/` | This framework's own specification: requirements about the checker, the viewer, the installer, the skills and the CI templates |
| `skeleton/` | The payload: starter specification files and the target-facing `AGENTS.md`/`CLAUDE.md`, copied into projects by the installer. This file and the root `CLAUDE.md` are this project's instances of those two, and carry every rule they state (INV-SKILL-010) |
| `tools/` | `srs_check.py`, `srs_parse.py`, `srs_view.py`, `srs_upgrade.py`, `srs_baseline.py`, `srs_dates.py` (shipped to targets), `srs_grounds.py` (shipped where a project keeps a register), `srs_arch.py` (shipped where a project keeps an architecture layer), `srs_init.py`, `srs_release.py`, `srs_cite_eval.py`, `srs_proc_eval.py` and `ci_selftest.sh` (framework-only) |
| `tests/` | The suites this repository's pipeline runs; requirements cite them by path |
| `ci/` | CI and pre-commit templates for target projects — not this repository's own pipeline |
| `.claude/skills/` | Agent skills; `srs-init` and `srs-release` are framework-only, the rest ship to targets |
| `.github/workflows/srs.yml` | This repository's own pipeline. Target projects get theirs from `ci/` |

## Two rules that protect other people's repositories

1. **Nothing framework-specific goes into `skeleton/`.** Requirements about this framework's tooling would land in every project installed afterwards, pointing at files that do not exist there — a hard checker error on a stranger's first install.
2. **Annotate the shipped tooling like anything else — the installer takes the annotations out on the way into a target.** Every tool under `tools/` carries `implements:`/`verifies:` lines: they are the second half of the two-way check this repository runs on itself. `tools/srs_init.py` replaces each one as it copies (FR-INIT-180), leaving the line in place so line numbers match. Never mark such a line `srs-ignore` to quiet something — the exemption is unconditional and silences the annotation here too; `srs-ignore` marks an example, never a claim.

## Working on the framework

This repository is itself an SRS-DD project: behavior changes go through `specs/` the same way they do in any target — find or create the requirement, plan by requirement identifiers, write the code, then close the loop: status, `code` and `tests` in the same set of edits, and the checker run.

- **Specification rules** — `specs/README.md`, by section, and it wins on any conflict; `python3 tools/srs_view.py --vocabulary` prints the words a block may use.
- **Engineering principles** — `specs/constitution.md` (`ART-*`); they apply to every task. Builds, tests and every other action ART-030 reserves run only with the user's explicit confirmation, each time.
- **Generated files** — `specs/90-traceability.md`, `arch/90-map.md` and `grounds/90-dashboard.md` are written by the checkers; never edit them by hand.
- **Check** — `python3 tools/srs_check.py` (`--strict` in CI).
- **Line width** — the rule and its reasons are in `CONTRIBUTING.md` under *Ground rules*; read it before reformatting anything. Markdown is not wrapped to a width, and where a markdown line may break is INV-SPEC-070; `tests/line-width.sh` refuses what it forbids (FR-CI-100).
- **Read** — `python3 tools/srs_view.py <ID>`, `--code <path>` (`--statements` adds what each obliges), `<ID> --where` for the lines that carry it (`--source` prints them), `--areas`, `--html`, `--open` for a page (the `srs-page` procedure).
- **A question about how this works, rather than a change to it** — start with `specs/00-glossary.md`, `specs/01-introduction.md` and `specs/02-overview.md`, then `--areas`, then one area, then the requirement. A lookup by number needs a number nobody has handed you, and a search over requirement text finds the word you guessed rather than the one this project uses (FR-SKILL-240).
- **Naming a record to a person** — a requirement, an element, a grounds record or a decision: at its first mention in what the person reads as a whole (a message, a plan, a report), give its title, the file it is written in and its status, pasted from the tool, never typed. `python3 tools/srs_view.py --cite <ID>…` prints the citation for a requirement or a decision, `python3 tools/srs_arch.py --cite <ID>…` for an element and `python3 tools/srs_grounds.py --cite <ID>…` for a record of the register, all in one form — `FR-CI-100 — The gate refuses a source line nobody had to write long (specs/10-fr-ci.md, implemented)`. Afterwards the number alone is enough; inside `specs/`, `arch/` and `grounds/` the identifier is the name. A line a checker printed is run through `--cite` before it is relayed. The rule holds in a table, a list, the steps of a plan and the report of any procedure — a template with no place for the citation is one you add it to. It is checked at sending: what was pasted is what the tool printed — no bold around it, no backticks around the file, nothing added inside the brackets. A mention in passing is a mention. A span or a family named as a set — `FR-DOC-010` through `FR-DOC-210`, the `GND` area — is one name, not a mention of each member. A commit message and the changelog are the exception and name identifiers bare, in a trailing parenthesis (ART-060 asks a commit for what it implements, and nobody re-dates a commit). A number the specification does not carry yet is a proposal and is marked as one (FR-SKILL-200).
- **Reading the code behind a change** — take the files from the `code` and `tests` fields of the requirements the change belongs to, not from a search over the repository. Go wider where you must, and say where you went (FR-SKILL-220).
- **Reporting to a person** — write in sentences that follow one another, and keep a list or a table for what the reader has to count or compare. A label with a fragment after it is a note to yourself (FR-SKILL-270).
- **Saying what the project's files say** — read the source in the same message and match the sentence to it before sending, not to what you remember. A count is derived over the current files, a claim that something is nowhere written names what was searched, and a paraphrase is checked against the passage it paraphrases (FR-SKILL-280).
- **Putting something to a person for a decision** — a sentence for a document, a requirement's text, a step of a plan: the message that asks carries the text as it would be written, quoted in a block where it is long; "as shown above" is a key handed over instead of the thing, the same failure as a bare identifier (FR-SKILL-320).
- **What a change chose** — where a requirement could have been met another way, the way taken goes to `specs/adr/` (*Workflow*, `specs/README.md`), or the report says there was none (FR-SKILL-350).
- **A rule settled in conversation** — where it binds beyond this task and nothing states it, offer to author it, naming what it obliges and its area (FR-SKILL-330).
- **Whether the guides hold for a fresh agent** — `python3 tools/srs_cite_eval.py` asks a fresh Claude Code instance the questions in `tests/eval/citation-questions.txt` and scores how the answers name records (FR-SKILL-290); `python3 tools/srs_proc_eval.py` runs the scenarios in `tests/eval/scenarios/` and reports what each run added to its context, burned, and whether it met its checks (FR-SKILL-310). Measurements for whoever changes the guides or a procedure, run by hand before and after — never a gate: a model's answers vary and the client needs an account.
- **What a procedure may cost** — `tests/skill-budget.sh` holds every procedure and both guides to a budget of words (NFR-SKILL-020); `tests/skill-instructions.sh` holds each procedure to the commands, articles, files and procedures its list in `tests/skill-instructions/` says it must name (FR-SKILL-300). A shortened procedure lowers the budget; a cut that loses an instruction is red.
- **Check a finished change** — the `srs-check` procedure reads the `verification` method and the `tests` field of every requirement the change touched, and offers exactly those; it runs nothing unasked.
- **Procedures** — `.claude/skills/*/SKILL.md` are plain markdown; an agent without a skill system reads them directly.
- **Freeze a baseline** — `python3 tools/srs_baseline.py X.Y.Z` writes the row into `specs/92-baselines.md`, through the `srs-baseline` procedure; nothing commits or tags for you.
- **Local gate** — `tools/ci_selftest.sh` runs the same suites CI does; `git config core.hooksPath .githooks` wires it into `pre-commit`.
- **Cut a release** — the `srs-release` procedure; it decides nothing about the version or the notes on its own.
- **Contribution and release rules** — `CONTRIBUTING.md`.
