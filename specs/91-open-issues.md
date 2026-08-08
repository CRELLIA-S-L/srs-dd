# Open issues

Discrepancies between the specification and the code, unfinished work,
unresolved questions. Each entry states what diverged, where it was found,
and what decision is needed. Entries are removed once the maintainer decides
which side is right and the fix lands.

## Nothing in the suites exercises a gesture

**Found:** while building the explorable graph (2026-08-08).

**What diverged:** FR-VIEW-110 promises panning, zooming, dragging and
highlighting, and carries `verification: I` because no browser and no
JavaScript engine is a dependency of this project. `tests/view-smoke.sh`
asserts that the handlers and the stage are in the page — which catches a
deletion, and nothing else. The same limit applies to the comparison of
FR-VIEW-100: its data is checked against git, its script is checked by
having been read.

**Why it is recorded rather than fixed:** every way out adds a dependency
the framework does not have. A headless browser in CI is the honest one and
the heaviest; a JavaScript engine would run the logic but not the gestures;
transliterating the script into Python, as the baseline comparison already
does, tests a copy rather than the thing that ships.

**Decision needed:** accept inspection as the method for anything the page
does in the browser and say so in `50-verification.md`, or take on a
headless browser for the graph and the comparison.

## The graph cannot be pinched, and skip-layer edges have no anchor

**Found:** while reviewing the explorable graph (2026-08-08).

**What diverged:** two limits of FR-VIEW-110 and of the layered layout, both
deliberate at the time and neither written down. One finger pans and a wheel
zooms, but two fingers do nothing — a touch device can move the graph and
not scale it. And `order_layers` places a node by the barycentre of its
parents *in the layer immediately above*; a requirement deriving from
something two layers up finds no anchor and falls to the end of its layer.
Neither shows on this repository's own graph, where crossings are already
zero.

**Decision needed:** whether either is worth code. Pinch zoom is a pointer
handler counting two contacts; the layout would have to rank against every
layer above, not just the previous one — more code in the part of the viewer
that has to stay deterministic.

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
