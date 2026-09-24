# ADR-0032 — What concerns a target alone is excused in the test, not in the specification

- **Status:** accepted
- **Date:** 2026-09-24
- **Related requirements:** INV-SKILL-010, FR-INIT-220

## Context and problem statement

`INV-SKILL-010` excepts "what concerns a target alone".
One requirement names a shipped guide and has no business in this repository's: `FR-INIT-220`, the line on the project's width that the installer fills into a target's `AGENTS.md`.
The check of `ADR-0031` must know it is excused, and so must a reader wondering why the requirement names one guide.

## Considered options

1. The requirement's `exempt` field, which `specs/README.md` defines for excusing a requirement from a checker rule.
2. A file of its own beside the lists, such as `tests/guide-parity/exempt.txt`.
3. A table at the top of the test, each entry beside its reason.

## Decision outcome

Option 3.
`exempt` names rules of the checker and is read by the checker, which refuses a name it does not know ("exempt names an unknown rule"); this check is a suite, not a checker rule, so the field could not carry it without a checker rule invented to hold the name.
A separate file would split the exception from the only code that reads it and invite entries with no reason attached; beside the check, the reason is read by whoever reads why the check passes.
The target-only lines that no requirement carries — the upgrade command, the width line's placeholder — are kept out of the token lists, and the lists of the two guides say so in their header comments.

### Consequences

- An exception is a code change to the test, reviewed as one.
- A whole file can concern a target alone too: the starter files under `skeleton/specs/`, `skeleton/grounds/` and `skeleton/arch/` teach a project how to fill its first files, so they are left out of the test's table of pairs rather than excused one rule at a time, and `INV-SKILL-010`'s rationale says why.
- The requirement's rationale does not say it is excused; the test does, by identifier, so a search for the identifier finds the exception — `--where` does not, since it reads annotations and the entry is not one.
