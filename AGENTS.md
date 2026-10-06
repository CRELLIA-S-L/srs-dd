# SRS-DD — agent guide for the framework repository

You are in the repository of the SRS-DD framework itself, not in a project that uses it.
Nothing here describes an application: the specification in `specs/` describes this framework's own tooling.

<!-- srs-dd -->
A summary for coding agents; the project follows the SRS-DD standard.
On any conflict, `srs-dd/standard.md` wins — it is the single normative document on the specification.
System behavior is described in `specs/` as numbered requirements with links between them and references to code.

- **Specification rules** — `srs-dd/standard.md`, by section; `python3 srs-dd/tools/srs_view.py --vocabulary` prints the words a block may use.
- **The method's articles** — `srs-dd/method.md` (`SRS-DD-ART-*`), the framework's and the same in every project; the project's own principles are `specs/constitution.md` (`ART-*`). Both apply to every task.
- **Markdown is not wrapped to a width** — a line breaks where the meaning breaks, never inside a sentence; the renderer does the wrapping.
- **Check** — `python3 srs-dd/tools/srs_check.py`.
- **Gate** — `python3 srs-dd/tools/srs_gate.py` runs what the pipeline and the pre-commit hook run: the checkers, then every generated file compared with what git holds.
- **Read** — `python3 srs-dd/tools/srs_view.py <ID>` for one requirement with its links resolved, `--code <path>` for the requirements describing a file (`--statements` adds what each obliges), `<ID> --where` for the lines that carry it (`--source` prints them), `--areas` for what the specification is divided into, `--open` for a page a non-engineer can read; `.claude/skills/srs-page/SKILL.md` is the procedure around it.
- **Check a finished change** — `.claude/skills/srs-check/SKILL.md` reads the `verification` method and the `tests` field of every requirement the change touched, and offers exactly those; it runs nothing unasked.
- **Skills** — the procedures in `.claude/skills/*/SKILL.md` are plain markdown; an agent without a skill system reads them directly as workflow guides.
- **Freeze a baseline** — `python3 srs-dd/tools/srs_baseline.py X.Y.Z` writes the row into `specs/92-baselines.md`; the commit that carries it is the baseline, and `.claude/skills/srs-baseline/SKILL.md` is the procedure. Nothing here commits or tags for you.
- **Date requirements** — `python3 srs-dd/tools/srs_dates.py` writes into each requirement the date its identifier first appeared in the history; `--dry-run` says what it would write. Run on purpose, never by a gate.
- **Grounds register**, where the project keeps `grounds/` — `python3 srs-dd/tools/srs_grounds.py` checks it and regenerates `grounds/90-dashboard.md`; `--blast <path>` says what the requirements behind a file stand on, and `--html` prints the dashboard as a page. `.claude/skills/srs-bet/SKILL.md` is the procedure.
- **Architecture layer**, where the project keeps `arch/` — `python3 srs-dd/tools/srs_arch.py` checks it against the specification and regenerates `arch/90-map.md`; a part still `proposed` is a design, and `--plan` says what moving to it requires. `python3 srs-dd/tools/srs_arch_doc.py` prints the layer as a document for a person, on request, and `--html` prints it as a page. `.claude/skills/srs-arch/SKILL.md` is the procedure.
- **Publish the pages** — `index.html`, `arch.html` and `grounds.html` side by side (*Published pages*, `srs-dd/standard.md`); `--link` says which others are beside a page, and it links exactly those, so none promises a page nobody rendered.
- **Upgrade the framework** — `python3 srs-dd/tools/srs_upgrade.py` shows the version transition, the upgrade notes and the file list, then asks; `.claude/skills/srs-upgrade/SKILL.md` is the procedure. No framework clone, no address to look up.

## Two ways in

A question about how the system works starts with what this project wrote about itself — `specs/00-glossary.md`, `specs/01-introduction.md`, `specs/02-overview.md`: short, and in the project's own words, which a search over requirement text assumes you already know. Then `--areas`, then one area, then the requirement, then its code.

A change to behavior starts at the loop below.

## The loop

1. Before changing behavior, find the requirements that describe it: `python3 srs-dd/tools/srs_view.py --code <path/to/file>`, or the tables in `specs/90-traceability.md`. None exist — create one first, with the initial status per the Lifecycle section of `srs-dd/standard.md`.
2. Plans reference requirement IDs, not prose.
3. Implement.
4. Record what you chose: each way the change met a requirement that could have been met another way is a decision — *Workflow* in `srs-dd/standard.md` says what counts — and goes into `specs/adr/`; when there was none, the report says so.
5. Close the loop: status, `code`, `tests` — in the same set of edits as the code.
6. Run the checker.

## The rules most easily broken

1. Changing behavior — first find or create the requirement, then write the code.
2. `specs/90-traceability.md` is generated by a script; never edit it by hand.
3. Builds, tests, and every other action that SRS-DD-ART-030 of the method reserves run only with the user's explicit confirmation.
4. Naming a record to a person — a requirement, a decision, and where the project keeps the layers an element or a grounds record: at its first mention in what the person reads as a whole (a message, a plan, a report), give its title, the file it is written in and its status, pasted from the tool, never typed: `python3 srs-dd/tools/srs_view.py --cite <ID>…` prints `FR-<AREA>-<NNN> — <its own title> (specs/<file>.md, <status>)` and cites a decision by its `ADR-NNNN`; `python3 srs-dd/tools/srs_arch.py --cite` and `python3 srs-dd/tools/srs_grounds.py --cite` print the same form for an element and a register record. Afterwards the number alone is enough; inside `specs/`, `arch/` and `grounds/` the identifier is the name. A line a checker printed is run through `--cite` before it is relayed. The rule holds in a table, a list, the steps of a plan and the report of any procedure — a template with no place for the citation is one you add it to. It is checked at sending: what was pasted is what the tool printed — no bold around it, no backticks around the file, nothing added inside the brackets. A mention in passing is a mention. A span named as a set — `FR-<AREA>-010` through `FR-<AREA>-090`, a whole area — is one name, not a mention of each member. A commit message and the changelog are the exception and name identifiers bare, in a trailing parenthesis. A number the specification does not carry yet is a proposal, and is marked as one.
5. Reading the code behind a change — take the files from the `code` and `tests` fields of the requirements the change belongs to (`--code <path>` answers from the other end), not from a search over the repository. Go wider where you must, and say where you went.
6. Reporting to a person — write in sentences that follow one another, and keep a list or a table for what the reader has to count or compare. A label with a fragment after it is a note to yourself.
7. Saying what the project's files say — read the source in the same message and match the sentence to it before sending, not to what you remember. A count is derived over the current files, a claim that something is nowhere written names what was searched, and a paraphrase is checked against the passage it paraphrases.
8. Putting something to a person for a decision — a sentence for a document, a requirement's text, a step of a plan: the message that asks carries the text as it would be written, quoted in a block where it is long; "as shown above" is a key handed over instead of the thing, the same failure as a bare identifier.
9. A rule the conversation settles — where something agreed will bind the work after this task is over and no requirement says it, offer to author the requirement, naming what it would oblige and the area it belongs to. Offered, never written: the maintainer decides whether it is written at all.
10. A commit that alters behavior names the requirement identifiers it implements, bare, in a trailing parenthesis — SRS-DD-ART-060 asks the commit or the pull request for them, and the identifiers are the ones the change was planned from.
11. Nothing sensitive goes into the repository (SRS-DD-ART-100) — no credentials, personal data, documents shared in confidence or traces of your machine. Read what is untracked before staging, and name a file that stays local in `.gitignore` before writing it.
<!-- /srs-dd -->

## Installing SRS-DD into a project

Follow `.claude/skills/srs-init/SKILL.md` — plain markdown, no skill system required; it covers fresh initialization, adoption of an existing specification, and upgrades, and says which decisions are the maintainer's.

```
python3 tools/srs_init.py path/to/project --dry-run
python3 tools/srs_init.py path/to/project [flags]
```

Never run the installer against this repository: it would install the framework into itself. It refuses on its own (`is_inside`); do not rely on that.

## What lives where

| Path | What it is |
|---|---|
| `srs-dd/` | The framework's directory, copied whole into every project and the source here. Under `tools/`: `srs_check.py`, `srs_parse.py`, `srs_view.py`, `srs_view_model.py`, `srs_view_page.py`, `srs_upgrade.py`, `srs_baseline.py`, `srs_dates.py`, `srs_gate.py` (shipped to targets); `srs_grounds.py` (shipped where a project keeps a register); `srs_arch.py` and `srs_arch_doc.py` (shipped where a project keeps an architecture layer). Beside them `standard.md` (the specification's standard), `grounds.md` and `arch.md` (the layers' standards, shipped with their layer), `method.md` (`SRS-DD-ART-*`), `guide.md` (the region of every `AGENTS.md`), `LICENSE` and the `README.md` that carries the marker |
| `specs/` | This framework's own specification; `specs/constitution.md` holds this repository's own articles (`ART-*`) |
| `skeleton/` | Starters of a project's own files: specification files, `AGENTS.md`/`CLAUDE.md` with the region — this file and the root `CLAUDE.md` are this repository's instances of them |
| `tools/` | `srs_init.py`, `srs_release.py`, `srs_cite_eval.py`, `srs_proc_eval.py`, `ci_selftest.sh`, `test_lib.sh` (framework-only) |
| `tests/` | The suites this repository's pipeline runs; requirements cite them by path |
| `ci/` | Starters of a project's pipelines and hook — not this repository's own pipeline |
| `.claude/skills/` | Procedures; `srs-init` and `srs-release` are framework-only, the rest ship — `srs-bet` and `srs-arch` with their layer |
| `.github/workflows/srs.yml` | This repository's own pipeline |

## Two rules that protect other people's repositories

1. **Nothing framework-specific goes into `skeleton/` or `srs-dd/` as a path that exists only here.** A requirement of this repository named in a shipped file lands in every project installed afterwards — a hard checker error on a stranger's first install.
2. **Annotate the shipped tooling like anything else — the installer takes the annotations out on the way into a target.** Every tool under `srs-dd/tools/` carries `implements:`/`verifies:` lines, the second half of the two-way check this repository runs on itself; `tools/srs_init.py` replaces each as it copies (FR-INIT-180), leaving the line in place so line numbers match. Never mark such a line `srs-ignore` to quiet something — the exemption is unconditional; `srs-ignore` marks an example, never a claim.

## Working on the framework

This repository is itself an SRS-DD project: behavior changes go through `specs/` the same way they do in any target — find or create the requirement, plan by requirement identifiers, write the code, then close the loop: status, `code` and `tests` in the same set of edits, and the checker run.

- **Generated files** — `specs/90-traceability.md`, `arch/90-map.md` and `grounds/90-dashboard.md` are written by the checkers; never edit them by hand.
- **Line width** — the rule and its reasons are in `CONTRIBUTING.md` under *Ground rules*; read it before reformatting anything. Markdown is not wrapped to a width, and where a markdown line may break is INV-SPEC-070, verified by reading; `tests/line-width.sh` refuses a code line wider than 120 columns whose width no string literal on it accounts for (FR-CI-100).
- **Whether the guides hold for a fresh agent** — `python3 tools/srs_cite_eval.py` asks a fresh Claude Code instance the questions in `tests/eval/citation-questions.txt` and scores how the answers name records (FR-SKILL-290); `python3 tools/srs_proc_eval.py` runs the scenarios in `tests/eval/scenarios/` and reports what each run added to its context, burned, and whether it met its checks (FR-SKILL-310). Measurements, run by hand before and after a change to the guides or a procedure — never a gate.
- **What a procedure may cost** — `tests/skill-budget.sh` holds every procedure and both guides to a budget of words (NFR-SKILL-020); `tests/skill-instructions.sh` holds each procedure to the commands, articles, files and procedures its list in `tests/skill-instructions/` says it must name (FR-SKILL-300).
- **Local gate** — `tools/ci_selftest.sh` runs the same suites CI does, and `python3 srs-dd/tools/srs_gate.py` the gate a target's hook runs; `git config core.hooksPath .githooks` wires both into `pre-commit`.
- **Cut a release** — the `srs-release` procedure; it decides nothing about the version or the notes on its own.
- **Contribution and release rules** — `CONTRIBUTING.md`.
