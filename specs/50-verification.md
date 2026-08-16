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
| `tests/installer-smoke.sh` | Fresh install, upgrade, dry-run honesty, precious files and what `--force` does to them, the exit code of a target the checker rejects, hook coexistence, payload isolation |
| `tests/adopt-smoke.sh` | Adoption of a non-English specification, transactional rollback, dry-run/real parity, refusal on markdown without requirements |
| `tests/view-smoke.sh` | Every viewer query mode, the browser it opens the page in, and the page: content, search and filters, the dashboard's census and gap lists, escaping, no CDN, determinism, no bytecode left behind |
| `tests/checker-rules.sh` | One fixture per checker rule: the exit code and the message for a broken specification, and the refusals that happen before one is read |
| `tests/upgrade-smoke.sh` | Upgrading a project from an older framework, the version transition and the notes it prints |
| `tests/baseline-smoke.sh` | Freezing a baseline in a target and in a clone, including a hand-written row and a history too shallow to hold one |
| `tests/release-smoke.sh` | Preparing a release: refusals, the dry run, and that nothing is committed or tagged |

All eight run in CI and locally through `tools/ci_selftest.sh`, which
executes every suite in `tests/` rather than a copy of them.

## Recorded measurements

| Requirement | Measurement | Date |
|---|---|---|
| NFR-CHK-010 | 50 ms by the same method, after the two pairing rules were added — every file a requirement names checked for its back-reference, every scanned file checked for being claimed at all, with all 500 requirements annotated in the fixture | 2026-08-14 |
| NFR-CHK-010 | 52 ms by the same method, after five rules were added — the required-key and retired-key checks, the two reports on tests and links, and the routing that gives every rule a severity | 2026-08-11 |
| NFR-CHK-010 | A generated specification of 500 requirements validates in 45 ms wall clock, interpreter startup included (`--no-write`, Python 3.14, Apple silicon) | 2026-08-06 |

Newest first, as in the baseline log. A measurement is not replaced when it
is retaken: the older row is what the newer one is a change from.

## Known gaps

The checker's rules are no longer among them: `checker-rules.sh` carries a
fixture per rule, and an audit that asked of every fixture "which change to
the code would redden it" closed what remained — the clauses a rule states
and a single fixture never reached. Two gaps outlived that question, and for
opposite reasons: one cannot be reached without a dependency this project
does not have, the other cannot be reached without staging the failure the
fixture would then be asserting.

**What the page does in a browser.** Gestures, and the following of a link,
are asserted as markup and handlers: their presence is proved, their working
is not. The suites run no browser, because none is a dependency of this
project. Recorded in `91-open-issues.md`, where the decision is stated as
open — accept inspection as the method here, or take on a headless browser.

**Adopt past its point of no return.** A step failing after the checker is
in place reports partial completion and exits 1; reaching it needs a fault
injected into the installer, and a fixture for that would assert the
injection rather than the behaviour. The exit code itself is covered from
the other direction — an upgrade returning the target checker's verdict.
