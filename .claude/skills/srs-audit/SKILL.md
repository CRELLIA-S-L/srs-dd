---
name: srs-audit
description: Semantic drift audit between the specification and the code. Invoke when the user asks to audit the spec, verify that code matches requirements, or find undocumented behavior. Read-only analysis with a report; fixes nothing by itself. For the everyday workflow use the srs skill.
---

# Auditing spec ↔ code drift

The checker (`tools/srs_check.py`) already catches everything mechanical:
broken links, missing paths, stale annotations by ID. This audit covers
what the checker cannot judge — whether the code actually does what the
statements say. Do not re-report what the checker reports.

## Procedure

1. Run `python3 tools/srs_check.py --no-write` to start from a known
   mechanical state; note any warnings.
2. For every `implemented` and `partial` requirement: read the files in
   its `code` and `tests` fields and judge whether the behavior matches
   the statement — the whole statement, including its condition and
   constraint, not just the action.
3. Go through “Code files outside the specification” in
   `specs/90-traceability.md`: for each orphan file, determine whether it
   carries behavior that deserves a requirement.
4. Compare `tests` entries against what the tests actually assert: a test
   that exists but checks something else is drift too.
5. Report findings grouped by requirement, each with three parts: what the
   spec says, what the code does, where exactly they diverge
   (`file:line`). Distinguish “code is wrong”, “spec is outdated”, and
   “cannot tell” — do not guess which.

## Boundaries

- Do not flip statuses, edit requirements, or change code during the
  audit — which side is wrong is the maintainer's call (ART-010 of the
  constitution).
- Write findings into `specs/91-open-issues.md` only with the user's
  explicit confirmation.
- Do not run builds or tests (ART-030); this audit is read-only.
