# SRS-DD — spec-driven development on a real SRS

**An agent writes a week of code in an afternoon.
Six weeks later nobody can say whether the behaviour it added was ever asked for.**
SRS-DD makes that question answerable by a script: every change that alters behaviour names the numbered requirement it closes, and the build fails when it does not.

Built for repositories written with agents, and it refuses the usual price for that.
What agents get is not a prompt file with a nice name — it is a real software requirements specification: **ISO/IEC/IEEE 29148** structure and attributes, **EARS** statement patterns, immutable identifiers, a lifecycle, a generated traceability matrix, **MADR** decision records.
What people get is the same thing, in plain Markdown that diffs line by line in a review, and one self-contained page for whoever will never clone the repository.

`Python ≥ 3.9` · standard library only · plain Markdown · specification in any language · no server, no database, no service · MIT

This repository is its own example: [`specs/`](specs/) describes the checker, the viewer and the installer as numbered requirements, and the pipeline publishes them as [a page](https://crellia-s-l.github.io/srs-dd/).
For what an ordinary product looks like after adopting the standard — a small service, a superseded requirement kept for the record, tests named from both directions — see [srs-dd-example-urlshortener](https://github.com/CRELLIA-S-L/srs-dd-example-urlshortener).

## What breaks without it

Agents sharpened three old problems until they became daily ones.

- **Behaviour arrives that nobody asked for.**
  An agent fixing one thing adds another on the way past.
  It is plausible, it is tested, and it is in the diff — and nothing in the repository records whether it was wanted.
- **Intent lives where it cannot be checked.**
  In an issue tracker, in a chat log, in the head of whoever ran the prompt.
  When the code and the intent disagree, working out which one is wrong becomes archaeology.
- **Every question costs a full read.**
  "What does this file affect", "why is this here", "what breaks if I change it" — each answered by searching the whole codebase, again, by a person or by an agent burning tokens on it.

A specification with identifiers turns all three into lookups.
Plans cite `FR-CORE-020`.
Diffs carry the requirement they close.
Drift between the spec and the code becomes a build error rather than a discovery.

## A requirement, and what the tooling does with it

A requirement is a heading, a small YAML block, one statement, and the reason it exists:

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

`python3 tools/srs_check.py` regenerates `specs/90-traceability.md` — requirement → code → verification, in both directions — and fails on a dangling link, a status of `implemented` without code paths, a path that does not exist, a cycle in the derivation graph, or an annotation naming a requirement that was never written.
Softer drift is a warning: a file a requirement names that does not name it back, a requirement verified by test that lists none, a requirement no link touches.
`--strict` turns warnings into failures too.

`python3 tools/srs_view.py --html` writes one self-contained page: search, filters, a status dashboard, the coverage gaps, a graph of every kind of link that you can narrow to one requirement's surroundings, pan, zoom and pull apart, and a comparison of any two frozen baselines.
No CDN, no network, opens straight from `file://`.

## What you get back

- **Finding what a change touches stops depending on the size of the system.**
  `srs_view.py --code src/app.py` names the requirements that describe that file; `srs_view.py FR-CORE-020` resolves one of them in both directions — what it derives from, and what breaks if it changes.
  Neither is a search across the codebase.
  The work becomes proportional to the neighbourhood of the change rather than to the size of the project, which is where the time and the tokens of every fix, every review and every "why is this here" actually go.
- **Traceability is enforced, not agreed on.**
  The matrix is a committed artifact; CI regenerates it and compares byte-for-byte, so a stale one is a red build rather than a habit.
- **A listed test counts as proof only if it could fail.**
  The `srs-audit` procedure derives cases from the statement's own EARS parts, builds a decision table where conditions combine, and refuses to call a case covered until it can name the change to the code that would turn that test red.
- **Requirements have immutable identifiers and a lifecycle.**
  Cancelled ones are kept saying they were cancelled — `superseded` with a successor, `withdrawn` without — and a requirement still standing on a withdrawn one is reported.
- **A milestone can be frozen and compared.**
  `srs_baseline.py` writes a row into the baseline log; afterwards `--diff 0.14.0` says exactly which requirements were added, removed, or had a field or a statement changed since, on the terminal and on the page.
- **The specification can be written in any language.**
  The tooling reads the modal verbs it enforces from a per-project lexicon, so the requirements are in the team's language and the rules are the same — [docs/multilingual.md](docs/multilingual.md).
- **Already have code and no spec?**
  `srs-harvest` reads it area by area and proposes draft requirements in batches you approve, never writing a status or inventing a test that does not exist.
- **Nothing to install.**
  Six dependency-free Python scripts land in your repository — seven with a grounds register, eight with an architecture layer.
  No server, no database, no toolchain, no account.
- **Agent-agnostic, and optional.**
  `AGENTS.md` is read natively by Cursor, Codex, Gemini CLI and Copilot; the skills are plain Markdown any agent can follow; a team working entirely by hand loses nothing.

## Why the thing exists, not only what it does

A specification records what the system must do.
It does not record why anyone thought those were the right things to build — that reasoning lives in rationale prose, which no rule checks.
Delete a requirement's rationale and a strict run reports nothing at all.

The **grounds register** is the optional sibling of `specs/` where that reasoning goes, and it is the largest part of this framework: 63 of its 213 requirements.
The **architecture layer** is the other optional sibling: which parts the system is cut into, what each one carries, and a checker that reports a file the specification claims and no part owns.
It holds three kinds of ground, and one record that joins them to the specification.

- A **hypothesis** is a claim about the world that could turn out false — who needs the thing, what they will pay for, what they do today instead.
  It carries a bounded population, a threshold that says what would refute it, a term, and an owner who answers for measuring it.
- An **ideology** says what the product is for, and a **frame** says what it will not do for anyone whatever the measurements say.
  Neither is measured;
  both are the ground no number touches.
- A **bet** stakes a requirement on a hypothesis.
  It is a record of its own, so a requirement file carries no register field at all and a project can decline the whole layer and lose nothing.

What that buys is one thing: **when an assumption is refuted, everything built on it becomes visible where the code is** — not years later, by whoever wonders what a feature was for.
`srs_grounds.py` reports a hypothesis past its term, one built on and never measured, a verdict that does not follow from its own threshold, a threshold moved after the first measurement, evidence deleted.
The pre-commit hook says which bets the files in your commit are standing on.
The dashboard states how old the confirmed core is, what each frame has refused, and which requirements rest on no hypothesis at all — because a requirement nobody can say why the product has is the signal this layer exists to protect, and demanding a bet for every one of them would destroy it.

**When not to keep a register.** Where the basis of the work is fixed outside the project and does not move — avionics, a protocol implementation, a compliance obligation, a component whose contract is somebody else's specification.
There the requirement tree already carries everything, the hypotheses would be invented to fill the file, and a register of invented entries teaches every reader that the register is decoration.
The question is not "could we write hypotheses down" but "will anybody measure them".

## Install

<!-- canonical-url: keep in sync with the block below -->

```
git clone https://github.com/CRELLIA-S-L/srs-dd.git
python3 srs-dd/tools/srs_init.py path/to/your-project
```

It asks for the project name, requirement areas, code and test roots, source extensions, a CI template, the lexicon, whether to keep a grounds register — and if you keep one, the period its dashboard counts arrivals by — and whether to keep an architecture layer.
Then it lays out `specs/`, writes the config, generates a placeholder requirement and runs the checker in your repository.
`--defaults` answers everything; `--dry-run` writes nothing and prints the exact created / refreshed / skipped list first.

**Already have an SRS?** The installer detects it and switches to adopt mode:
your spec is validated against the proposed configuration *before* anything is touched, and on failure the target is left byte-identical.
Your specification files are never modified.
Where its requirements carry no `created` dates, you are offered `tools/srs_dates.py`, which fills each one from the commit that introduced the identifier rather than from today.

**Already run a pre-commit hook?** It is never displaced — the installer says so instead of advising the `core.hooksPath` switch that would silently disable it.

Details, modes, exit codes and the manual path: [docs/install.md](docs/install.md).
Upgrades: [docs/upgrade.md](docs/upgrade.md).

## Handing this to an agent

Point a coding agent at this repository and it can install the framework itself.
The procedure is `.claude/skills/srs-init/SKILL.md` — plain Markdown, no skill system required:

<!-- canonical-url: the published entry point; see CONTRIBUTING.md -->

```
https://raw.githubusercontent.com/CRELLIA-S-L/srs-dd/main/.claude/skills/srs-init/SKILL.md
```

Clone rather than fetch that one file: the installer copies the skeleton, the skills and the CI templates out of the clone.
Nothing beyond `git` and `python3` is needed.

```
rm -rf /tmp/srs-dd    # so a second attempt does not trip over the clone
git clone --depth 1 https://github.com/CRELLIA-S-L/srs-dd.git /tmp/srs-dd
python3 /tmp/srs-dd/tools/srs_init.py path/to/project --dry-run
python3 /tmp/srs-dd/tools/srs_init.py path/to/project [flags]
```

Add `--branch vX.Y.Z` to the clone to pin a release.
The installer detects the mode itself — fresh, adopt or upgrade — and adopt is transactional.

```
0  installed
1  checker errors, or partial completion past adopt's point of no return
2  refused before changing anything
3  adopt rolled back, target untouched
```

**Two decisions are not the agent's to make alone**, and the skill stops for them: the **requirement areas** — the middle segment of every identifier, and identifiers are immutable — and the **lexicon**, which words carry which binding force.
The agent proposes; the maintainer confirms.
The same holds for the line width your code already follows: the agent looks for it in whatever you state it in — an `.editorconfig`, a formatter's configuration, a contributing guide — shows what it found and where, and passes it on only once you approve.
Nothing is invented where nothing is found.

### What you then tell the agent to do

After the install these procedures sit in `.claude/skills/` inside your own project, as Markdown.
Ask for them by name, or describe the task and let the agent pick.

| Say this | The agent does this |
|---|---|
| "add a requirement for X" | `srs-new` — a dialog that settles type, area, number, EARS phrasing, verification method and links, judges the statement against what no checker reaches, asks what the requirement stands on where you keep a register, and stops at the written requirement. Building it is a separate task. |
| any change to behaviour | `srs` — the everyday loop: name the requirements the change belongs to *before* the code, create one where none exists, re-read their statements as the loop closes, fill `code` and `tests` with real paths. |
| "we have code and no spec" | `srs-harvest` — reads the code area by area, proposes `draft` requirements in batches you approve first, invents no tests. |
| "check this before I commit" | `srs-check` — names the checks the touched requirements actually call for: the checker, the tests those requirements list, and what a person must look at where the method is not a test. It offers; it never runs a suite unasked. |
| "audit the spec against the code" | `srs-audit` — semantic drift and test adequacy. Read-only: it reports which side looks wrong and never picks one. |
| "freeze the spec" | `srs-baseline` — shows what changed since the last baseline, offers an audit of what the diff touches, settles the version with you, writes the row. |
| "show me the spec" | `srs-page` — renders the self-contained page and opens it. |
| "why do we do X" / a measurement came in | `srs-bet` — the grounds register: write a hypothesis, stake a requirement on it, record a measurement, settle what happens when one is refuted. |
| "update SRS-DD" | `srs-upgrade` — fetches the framework this project came from, shows the upgrade before it happens, refreshes the tooling and nothing precious. |

Three rules bind every one of them, and they are why an agent with these is safer than an agent without: **it proposes, you approve** — no status is flipped and no batch is written without you; **it never runs builds or tests unasked**; **it reports what follows, not what it noticed** — an observation with no consequence is dropped rather than handed to you as homework.

More: [docs/agents.md](docs/agents.md).

## The loop

Every task that changes behaviour goes through the same five steps:

1. **Requirement before code.**
   If a task changes behaviour it has a requirement — otherwise there is no way to tell when it is finished.
2. **Plans reference numbers.**
   `FR-DATA-050`, not "fix the storage layer".
3. **Code.**
4. **Close the loop.**
   Status to `implemented`, `code` and `tests` filled with real paths, in the same set of edits as the code.
5. **Check.**
   `python3 tools/srs_check.py`, locally and in CI.

What a linter cannot check — behaviour over implementation, verifiability, unambiguity — is still binding; those rules live in `specs/README.md`, and the `srs-audit` skill covers the semantic side.

## Reading the specification

```
python3 tools/srs_view.py FR-CORE-020        one requirement, links resolved
python3 tools/srs_view.py --code src/app.py  which requirements describe a file
python3 tools/srs_view.py --tree FR-CORE-010 what derives from it
python3 tools/srs_view.py --coverage         no tests, code outside the spec, …
python3 tools/srs_view.py --cite <ID>…       how to name it to a person
python3 tools/srs_view.py --diff 0.14.0      working tree against a baseline
python3 tools/srs_view.py --json             the model, for your own tooling
python3 tools/srs_view.py --html             a page for people who do not grep
```

The viewer never writes to `specs/` and never gates anything.
Where a project keeps a register, `python3 tools/srs_grounds.py --blast <path>` answers the other question: what the requirements describing that file are standing on.

## Where things are

| Path | What it is |
|---|---|
| `specs/README.md` | The standard: markup rules, identifier scheme, lifecycle, annotations, baselines, configuration |
| `specs/` | This framework's own specification — it uses itself. Also `91-open-issues.md` (questions nobody has settled), `92-baselines.md` (the frozen milestones) and `adr/` (the decisions) |
| `skeleton/` | What the installer copies into your project |
| `grounds/` | This framework's own grounds register: the hypotheses under its requirements, and the standard for them |
| `arch/` | This framework's own architecture layer: which parts it is cut into, what each one carries, and the standard for them |
| `tools/` | `srs_check.py`, `srs_parse.py`, `srs_view.py`, `srs_upgrade.py`, `srs_baseline.py`, `srs_dates.py` (yours after install); `srs_grounds.py` (yours if you keep a register); `srs_arch.py` (yours if you keep an architecture layer); `srs_init.py`, `srs_release.py` (stay here) |
| `.claude/skills/` | `srs`, `srs-new`, `srs-audit`, `srs-harvest`, `srs-upgrade`, `srs-baseline`, `srs-check`, `srs-page`, `srs-bet` (with the register), `srs-arch` (with the layer), and `srs-init`, `srs-release` (framework-only) |
| `tests/` | The suites this repository runs on itself; its requirements cite them by path |
| `ci/` | CI templates and a pre-commit hook for target projects |
| `docs/` | [install](docs/install.md) · [upgrade](docs/upgrade.md) · [agents](docs/agents.md) · [any language](docs/multilingual.md) |
| `CONTRIBUTING.md`, `CHANGELOG.md` | Framework governance and versioning |
