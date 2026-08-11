# Verification

How the methods in the `verification` field are carried out in this
repository.

| Method | What it means here |
|---|---|
| `T` | An automated suite in `tests/` asserts it. The suite is named in the requirement's `tests` field |
| `D` | Demonstrated by running the tool and observing the result |
| `I` | Inspection of the file named in `code` — used where the requirement is about the content of a document or a procedure rather than executable behavior |
| `A` | Analysis or measurement, with the reasoning recorded next to the requirement |

## The suites

| Suite | Covers |
|---|---|
| `tests/spec-check.sh` | This repository's own specification passes strictly, and the committed matrix matches what the checker generates now |
| `tests/installer-smoke.sh` | Fresh install, upgrade, dry-run honesty, precious files, hook coexistence, payload isolation |
| `tests/adopt-smoke.sh` | Adoption of a non-English specification, transactional rollback, dry-run/real parity, refusal on markdown without requirements |
| `tests/view-smoke.sh` | Every viewer query mode, and the page: content, escaping, no CDN, determinism, no bytecode left behind |
| `tests/checker-rules.sh` | One fixture per checker rule: the exit code and the message for a broken specification |
| `tests/upgrade-smoke.sh` | Upgrading a project from an older framework, the version transition and the notes it prints |
| `tests/baseline-smoke.sh` | Freezing a baseline in a target and in a clone, including a hand-written row and a history too shallow to hold one |
| `tests/release-smoke.sh` | Preparing a release: refusals, the dry run, and that nothing is committed or tagged |

All eight run in CI and locally through `tools/ci_selftest.sh`, which
executes every suite in `tests/` rather than a copy of them.

## Recorded measurements

| Requirement | Measurement | Date |
|---|---|---|
| NFR-CHK-010 | 52 ms by the same method, after five rules were added — the required-key and retired-key checks, the two reports on tests and links, and the routing that gives every rule a severity | 2026-08-11 |
| NFR-CHK-010 | A generated specification of 500 requirements validates in 45 ms wall clock, interpreter startup included (`--no-write`, Python 3.14, Apple silicon) | 2026-08-06 |

Newest first, as in the baseline log. A measurement is not replaced when it
is retaken: the older row is what the newer one is a change from.

## Known gap

The suites are end-to-end: they exercise the installer and the viewer through
whole scenarios, and they prove the checker accepts a valid specification.
They do *not* exercise the checker's individual rules — each `FR-CHK-*`
requirement with an empty `tests` field is a rule no test would notice the
loss of. This is recorded in `91-open-issues.md`.
