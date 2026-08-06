# SRS-DD — Spec-Driven Development on a real SRS

A lightweight standard for spec-driven development built on the bones of a
classic Software Requirements Specification, made for codebases written
with AI coding agents. The specification — not the issue tracker, not the
chat log — is the source of truth for what the system does; code changes
close the loop back to numbered, linked, traceable requirements, and an
agent that changes behavior has to name the requirement it closes.

Built for that without depending on it: the rules live in `AGENTS.md` and
in plain-markdown skills any tool can read, the enforcement is a
standard-library script, and a team working entirely by hand loses nothing.

The form is deliberately boring and standards-based:

- **ISO/IEC/IEEE 29148** — section structure, requirement attributes, the
  sentence-construction formula, traceability;
- **EARS** — ready-made phrase patterns for statements;
- **MADR** — the architecture decision log.

Everything is plain Markdown plus dependency-free Python scripts — a
checker and a viewer in your repository, an installer in this one. No
server, no database, no toolchain to install. The specification itself can
be written in **any language**: the tooling knows no natural language and
reads the modal verbs it enforces from a per-project lexicon.

## What is in the box

| Path | What it is |
|---|---|
| `specs/README.md` | The single normative document: markup rules, identifier scheme, lifecycle, annotations, baselines, configuration |
| `specs/` | The specification skeleton: glossary, introduction, FR/NFR/interface/invariant files, constitution, baselines log, ADR log |
| `specs/srs-config.json` | Project settings: areas, code and test roots, extensions, and the statement lexicon |
| `tools/srs_check.py` | Integrity checker and traceability-matrix generator. Standard library only, Python ≥ 3.9 |
| `tools/srs_view.py` | Viewer: terminal queries and a self-contained HTML page. Read-only, same dependency budget |
| `tools/srs_init.py` | Installer: fresh setup, adoption of existing SRS projects, upgrades (stays in the framework repo) |
| `AGENTS.md` | Canonical agent guide, read by any coding agent; `CLAUDE.md` is a thin pointer to it |
| `.claude/skills/` | Agent skills: `srs` (the workflow and planning), `srs-new` (author a requirement), `srs-audit` (drift audit and test adequacy), `srs-harvest` (mine a spec from existing code), `srs-init` (guided setup, framework-only) |
| `ci/` | Templates for target projects: CI (GitHub Actions, GitLab CI) and a pre-commit hook enforcing traceability freshness, plus an optional job that publishes the rendered specification |
| `CONTRIBUTING.md`, `CHANGELOG.md` | Framework governance and versioning |

## Quickstart

Clone the framework and run the installer against your repository:

```
git clone https://gitlab.com/crellia-public/srs-dd.git
python3 srs-dd/tools/srs_init.py path/to/your-project
```

It asks for the project name, requirement areas, code/test roots, source
extensions, a CI template, and the lexicon — then copies the skeleton,
writes `specs/srs-config.json`, generates a placeholder requirement, and
runs the checker in your repository. Non-interactive: add `--defaults` or
pass explicit flags (`--help`). `--dry-run` writes nothing and prints the
exact created / refreshed / skipped list first.

To write the specification in another language, either pass the word lists
yourself (`--modal-verbs "должен,должна,…" --negation-words "не"
--rationale-markers "Обоснование"`) or open a coding agent in the framework
clone and ask it to initialize your project — the `srs-init` skill
generates the lexicon for any language and asks you to confirm it.

Then: replace the placeholder requirement, and commit everything —
including `specs/90-traceability.md`, which is version-controlled on
purpose: CI regenerates it and fails if the committed copy is stale. The
same gate runs locally once you activate the installed hook:
`git config core.hooksPath .githooks`.

**Already run a pre-commit hook?** It is never displaced. The installer
looks at what the repository does on commit — `core.hooksPath`, an
existing hook, husky or the pre-commit framework — and when something is
already there it says so instead of advising the `core.hooksPath` switch,
which would silently disable it. Your hook then calls the gate:
`sh .githooks/pre-commit || exit 1`. If `.githooks/pre-commit` is itself
yours, the gate is installed beside it as `.githooks/pre-commit.srs-dd`.

**Already have an SRS?** The installer detects an existing specification
and switches to adopt mode: it validates your spec against the proposed
configuration (areas, lexicon) **before touching anything** — on failure
the target is left untouched — then installs the tooling and only the
missing service files. Your spec files are never modified.

Manual fallback: copy `specs/`, `tools/srs_check.py`,
`tools/srs_view.py`, the `srs`, `srs-new`, `srs-audit`, and
`srs-harvest` skills from `.claude/skills/`
(not `srs-init` — it is framework-only), `AGENTS.md`, `CLAUDE.md`, and
`.gitattributes` into your repository, then edit `specs/srs-config.json`
by hand.

## Handing this to an agent

Point a coding agent at this repository and it can install the framework
itself. The procedure to follow is `.claude/skills/srs-init/SKILL.md` —
plain markdown, no skill system required:

```
https://gitlab.com/crellia-public/srs-dd/-/raw/main/.claude/skills/srs-init/SKILL.md
```

Clone rather than fetch a single file: the installer copies the
specification skeleton, the skills and the CI templates out of the clone.
Nothing beyond `git` and `python3` is needed.

```
rm -rf /tmp/srs-dd    # so a second attempt does not trip over the clone
git clone --depth 1 https://gitlab.com/crellia-public/srs-dd.git /tmp/srs-dd
python3 /tmp/srs-dd/tools/srs_init.py path/to/project --dry-run
python3 /tmp/srs-dd/tools/srs_init.py path/to/project [flags]
```

Add `--branch vX.Y.Z` to the clone to pin a release. `--dry-run` writes
nothing and prints the exact created / refreshed / skipped list, so the
maintainer sees the change before it happens. The installer detects the
mode itself — fresh, adopt or upgrade — and adopt is transactional: a
validation failure leaves the target byte-identical. Exit codes:

```
0  installed
1  checker errors, or partial completion past adopt's point of no return
2  refused before changing anything
3  adopt rolled back, target untouched
```

Two decisions are not the agent's to make alone, and the skill says so:
the **requirement areas** — the middle segment of every identifier, and
identifiers are immutable — and the **lexicon**, which words carry which
binding force. The agent proposes; the maintainer confirms. The rest —
code roots, source extensions, the CI platform — the agent can read off
the repository and pass as flags without asking.

## Upgrading

To pick up a new framework version in an initialized project:

```
git -C path/to/srs-dd pull
python3 path/to/srs-dd/tools/srs_init.py path/to/your-project
```

The installer prints the checker version transition and the relevant
upgrade notes from the CHANGELOG, then refreshes `tools/srs_check.py`,
`tools/srs_view.py` and the skills (no flags needed). Precious files —
CI config, `CLAUDE.md`/`AGENTS.md`, `.gitattributes` — are refreshed only with
`--force`, and only when they carry the SRS-DD marker. `--dry-run` shows
the whole list without touching anything. Commit the refreshed tooling
together with the regenerated `specs/90-traceability.md`.

For `CLAUDE.md`/`AGENTS.md` there is a gentler path than `--force`: run
the guided upgrade (the `srs-init` skill, from a framework clone) and
the agent will propose a merge that folds the framework changes in
while preserving your local content.

## Other coding agents

`AGENTS.md` is the canonical, agent-agnostic guide, and modern agents
(Cursor, Codex, Gemini CLI, GitHub Copilot, …) read an `AGENTS.md` at
the repository root natively — for them, an initialized target works
out of the box. The skills in `.claude/skills/` are plain markdown with
no Claude-specific machinery; an agent without a skill system can read
them directly as workflow guides.

If your tool wants its own rules file (for example
`.cursor/rules/srs.mdc` or `.github/copilot-instructions.md`), a
two-line pointer is enough — no need to duplicate the rules:

```
This project follows the SRS-DD standard.
Read AGENTS.md first; the specification rules live in specs/README.md.
```

## The loop

Every task that changes behavior goes through the same five steps:

1. **Requirement before code.** Write down what must change, with the
   initial status per the Lifecycle section of `specs/README.md`. If a
   task changes behavior, it has a requirement — otherwise there is no way
   to tell when it is finished.
2. **Plans reference numbers.** `FR-DATA-050`, not “fix the storage layer”.
3. **Code.**
4. **Close the loop.** Status to `implemented`, fill `code` and `tests`
   with real paths; optionally annotate the files themselves
   (`implements:` / `verifies:`).
5. **Check.** `python3 tools/srs_check.py` locally and in CI
   (`--strict` if warnings must not accumulate).

The checker enforces what a linter can: unique well-formed identifiers,
exactly one bolded modal verb per statement (from your lexicon), no
dangling links, no cycles in derivation links, no `implemented` without
code paths, no paths that do not exist, no annotation drift. What it cannot check — behavior
over implementation, verifiability, unambiguity — is still binding; the
rules live in `specs/README.md`, and the `srs-audit` skill covers the
semantic side.

## Reading the specification

`tools/srs_view.py` reads what the checker validates. It never writes to
`specs/` and never gates anything — the traceability matrix stays the
committed artifact; this is a projection of the same data.

```
python3 tools/srs_view.py FR-CORE-020        one requirement, links resolved
python3 tools/srs_view.py --code src/app.py  which requirements describe a file
python3 tools/srs_view.py --tree FR-CORE-010 what derives from it
python3 tools/srs_view.py --coverage         no tests, code outside the spec, …
python3 tools/srs_view.py --diff spec/v0.1.0 working tree against a baseline
python3 tools/srs_view.py --html             a page for people who do not grep
```

`--html` writes one self-contained file (default `.srs-site/index.html`,
a directory that ignores itself): search, filters, clickable links in
both directions, a status dashboard, and a layered graph of the
derivation links — no CDN, no fonts, no network at all, so it opens
straight from `file://`. The CI templates in `ci/` publish it as a build
artifact, one rename away from GitLab or GitHub Pages. Set `repo_url` in
`specs/srs-config.json` (or pass `--repo-url`) to turn the `code` and
`tests` paths into links to your forge.

Requirements are what it renders; the glossary, the constitution and the
ADRs are linked from the page, not rendered — they carry no identifiers
for the tooling to resolve.

## Why not just write code

Working with AI coding agents sharpens an old problem: an agent will happily
change behavior nobody asked for, and a week later nobody can say whether
the code or the intent is right. A specification with identifiers gives both
humans and agents a shared, greppable ground truth: plans cite `FR-CORE-020`,
diffs carry the requirement they close, and drift between spec and code is a
checkable error, not an archaeology project.
