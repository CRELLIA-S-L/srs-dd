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

All four run in CI and locally through `tools/ci_selftest.sh`, which executes
the pipeline's own job scripts rather than a copy of them.

## Recorded measurements

| Requirement | Measurement | Date |
|---|---|---|
| NFR-CHK-010 | A generated specification of 500 requirements validates in 45 ms wall clock, interpreter startup included (`--no-write`, Python 3.14, Apple silicon) | 2026-08-06 |

## Known gap

The suites are end-to-end: they exercise the installer and the viewer through
whole scenarios, and they prove the checker accepts a valid specification.
They do *not* exercise the checker's individual rules — each `FR-CHK-*`
requirement with an empty `tests` field is a rule no test would notice the
loss of. This is recorded in `91-open-issues.md`.
