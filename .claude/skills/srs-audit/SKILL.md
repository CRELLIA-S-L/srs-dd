---
name: srs-audit
description: Semantic drift audit between the specification and the code, including test adequacy — whether the listed tests actually prove the statements. Invoke when the user asks to audit the spec, verify that code matches requirements, find undocumented behavior, check whether requirements are adequately tested, or derive test cases from statements. Read-only analysis with a report; fixes nothing by itself, except that on explicit request it can author the missing tests. For the everyday workflow use the srs skill.
---

# Auditing spec ↔ code drift

The checker (`tools/srs_check.py`) already catches everything mechanical:
broken links, missing paths, stale annotations by ID. This audit covers
what the checker cannot judge — whether the code actually does what the
statements say, and whether the listed tests would prove them. Do not
re-report what the checker reports.

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

## Test adequacy

Beyond drift, judge whether the listed tests would prove the statements.
Only requirements with `verification: T` get derived test cases; for
`D`, `I`, and `A`, check that the evidence `specs/50-verification.md`
expects is recorded, and report (ART-050).

1. Decompose the statement along its EARS parts: trigger (“When…”),
   state (“While…”), condition, the obligation itself, and any
   constraint. Each part is a test dimension — the trigger fires or does
   not, the state holds or does not, the boundary of the constraint.
2. A quantified constraint implies property-style cases: “within
   2 seconds” — at the boundary and beyond; “all unsaved changes” —
   none, one, many.
3. Map the derived cases against what the `tests` files actually
   assert. Classify each: covered, partial, uncovered — or asserted by a
   test yet not derivable from the statement, which means the statement
   is under-specified: report it, do not edit it.
4. On the user's explicit request — and only then — author the missing
   tests; the new test path goes into `tests` in the same set of edits
   (ART-050). Running them still needs its own confirmation (ART-030).

## Boundaries

- Do not flip statuses, edit requirements, or change code during the
  audit — which side is wrong is the maintainer's call (ART-010 of the
  constitution).
- Write findings into `specs/91-open-issues.md` only with the user's
  explicit confirmation.
- Do not run builds or tests (ART-030). The audit itself is read-only;
  authoring missing tests (Test adequacy, step 4) is the one exception,
  and only on explicit request.
