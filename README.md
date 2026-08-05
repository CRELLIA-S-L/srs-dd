# SRS-DD — Spec-Driven Development on a real SRS

A lightweight standard for spec-driven development built on the bones of a
classic Software Requirements Specification. The specification — not the
issue tracker, not the chat log — is the source of truth for what the system
does; code changes close the loop back to numbered, linked, traceable
requirements.

The form is deliberately boring and standards-based:

- **ISO/IEC/IEEE 29148** — section structure, requirement attributes, the
  sentence-construction formula, traceability;
- **EARS** — ready-made phrase patterns for statements;
- **MADR** — the architecture decision log.

Everything is plain Markdown plus two dependency-free Python scripts. No
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
| `tools/srs_init.py` | Installer: copies the skeleton into a target repository (stays in the framework repo) |
| `AGENTS.md` | Canonical agent guide, read by any coding agent; `CLAUDE.md` is a thin pointer to it |
| `.claude/skills/` | Agent skills: `srs` (the workflow), `srs-new` (author a requirement), `srs-audit` (drift audit), `srs-init` (guided install, framework-only) |
| `ci/` | CI templates for target projects (GitHub Actions, GitLab CI) with a traceability-freshness gate |
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
pass explicit flags (`--help`).

To write the specification in another language, either pass the word lists
yourself (`--modal-verbs "должен,должна,…" --negation-words "не"
--rationale-markers "Обоснование"`) or open a coding agent in the framework
clone and ask it to initialize your project — the `srs-init` skill
generates the lexicon for any language and asks you to confirm it.

Then: replace the placeholder requirement, and commit everything —
including `specs/90-traceability.md`, which is version-controlled on
purpose: CI regenerates it and fails if the committed copy is stale.

Manual fallback: copy `specs/`, `tools/srs_check.py`, the `srs`,
`srs-new`, and `srs-audit` skills from `.claude/skills/` (not `srs-init` —
it is framework-only), `AGENTS.md`, `CLAUDE.md`, and `.gitattributes` into
your repository, then edit `specs/srs-config.json` by hand.

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

## Why not just write code

Working with AI coding agents sharpens an old problem: an agent will happily
change behavior nobody asked for, and a week later nobody can say whether
the code or the intent is right. A specification with identifiers gives both
humans and agents a shared, greppable ground truth: plans cite `FR-CORE-020`,
diffs carry the requirement they close, and drift between spec and code is a
checkable error, not an archaeology project.
