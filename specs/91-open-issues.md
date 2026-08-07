# Open issues

Discrepancies between the specification and the code, unfinished work,
unresolved questions. Each entry states what diverged, where it was found,
and what decision is needed. Entries are removed once the maintainer decides
which side is right and the fix lands.

## An area holds at most 99 requirements, and the standard does not say so

**Found:** while measuring NFR-CHK-010 against a generated specification of
500 requirements (2026-08-06). 401 of them were rejected.

**What diverged:** `RE_ID` (`tools/srs_check.py`) requires exactly three
digits, so with the mandated steps of 10 an area runs from `010` to `990` —
99 requirements. The 100th is a hard error a project cannot work around
without splitting the area, and identifiers are immutable, so splitting late
is expensive. The Identifier section of `specs/README.md` says numbers "go in
steps of 10" and never mentions the ceiling.

**Decision needed:** document the limit and the advice to split an area early,
or widen the grammar to four digits — which changes what a released checker
accepts and therefore needs a version and upgrade notes.

## The checker's rules have no rule-level tests

**Found:** while harvesting this specification from the code (2026-08-06).

**What diverged:** every `FR-CHK-*` requirement except FR-CHK-090 and
FR-CHK-120 carries `verification: T` with an empty `tests` field. The
existing suites are end-to-end: they prove the checker accepts a valid
specification, and that the installer and the viewer behave. No test asserts
that a duplicate identifier, a dangling link, a cycle, a second modal verb or
a nonexistent path is actually *rejected* — each of those rules could be
deleted and the pipeline would stay green.

**Why it is recorded rather than fixed:** ART-050 flips a `T` requirement to
`implemented` in the same edit that adds its test. Writing that suite — a
fixture per rule, asserting the exit code and the message — is a change of
its own, not part of harvesting.

**Status:** the batch was approved on 2026-08-06 and the requirements are
`implemented`, so the gap is now live: ten `FR-CHK-*` requirements claim
`verification: T` with nothing in `tests`, which ART-050 does not allow to
stand.

**Decision needed:** write `tests/checker-rules.sh` — a fixture per rule
asserting the exit code and the message — or downgrade the affected
requirements to `verification: I` if inspection is genuinely the method the
project intends.
