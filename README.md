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

Everything is plain Markdown plus one dependency-free Python script. No
server, no database, no toolchain to install.

## What is in the box

| Path | What it is |
|---|---|
| `specs/README.md` | The single normative document: markup rules, identifier scheme, workflow |
| `specs/` | The specification skeleton: glossary, introduction, FR/NFR/interface/invariant files, ADR log |
| `specs/srs-config.json` | Project settings: requirement areas, code roots, source extensions |
| `tools/srs_check.py` | Integrity checker and traceability-matrix generator. Standard library only, Python ≥ 3.9 |
| `.claude/skills/srs/` | A skill that teaches a coding agent the workflow: requirement before code, close the loop after |
| `CLAUDE.md` | Project instructions wiring the skill and the checker into an agent session |

## Quickstart

1. Copy `specs/`, `tools/`, `.claude/`, and `CLAUDE.md` into your repository.
2. In `CLAUDE.md`, replace `<Your Project Name>`.
3. In `specs/srs-config.json`, set your requirement **areas** (subject-matter
   partitions like `CORE`, `API`, `SEC`), the roots of your production code,
   and your source file extensions.
4. Replace the placeholder requirement in `specs/10-fr-core.md` with your
   first real one, following `specs/README.md`.
5. Run the checker:

   ```
   python3 tools/srs_check.py
   ```

   It validates the specification and regenerates
   `specs/90-traceability.md` — the requirement → code → tests matrix.

## The loop

Every task that changes behavior goes through the same five steps:

1. **Requirement before code.** Write down what must change, status
   `deferred`. If a task changes behavior, it has a requirement — otherwise
   there is no way to tell when it is finished.
2. **Plans reference numbers.** `FR-DATA-050`, not “fix the storage layer”.
3. **Code.**
4. **Close the loop.** Status to `implemented`, fill `code` and `tests` with
   real paths.
5. **Check.** `python3 tools/srs_check.py` in CI and locally.

The checker enforces what a linter can: unique well-formed identifiers,
exactly one bolded modal verb per statement (**shall**/**must** /
**should** / **may**), no dangling links, no cycles, no `implemented` without code paths,
no paths that do not exist. What it cannot check — behavior over
implementation, verifiability, unambiguity — is still binding; the rules
live in `specs/README.md`.

## Why not just write code

Working with AI coding agents sharpens an old problem: an agent will happily
change behavior nobody asked for, and a week later nobody can say whether
the code or the intent is right. A specification with identifiers gives both
humans and agents a shared, greppable ground truth: plans cite `FR-CORE-020`,
diffs carry the requirement they close, and drift between spec and code is a
checkable error, not an archaeology project.
