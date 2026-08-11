# Open issues

Discrepancies between the specification and the code, unfinished work,
unresolved questions. Each entry states what diverged, where it was found,
and what decision is needed. Entries are removed once the maintainer decides
which side is right and the fix lands.

## Nothing in the suites exercises a gesture

**Found:** while building the explorable graph (2026-08-08).

**What diverged:** FR-VIEW-110 promises panning, zooming, collapsing an
area and highlighting, and carries `verification: I` because no browser and
no JavaScript engine is a dependency of this project. `tests/view-smoke.sh`
asserts that the handlers and the stage are in the page — which catches a
deletion, and nothing else. The same limit applies to the comparison of
FR-VIEW-100 — its data is checked against git, its script by having been
read — and to FR-VIEW-130, where the suite holds that every view links to a
requirement but not that following such a link arrives anywhere. The set
this covers grows with the page: each addition to it is one more behaviour
verified by a person who remembers to look.

On 2026-08-11 this stopped being hypothetical. Clicking a node had opened
nothing since the canvas began capturing the pointer on `pointerdown`: while
an element holds the capture the browser dispatches the click to it rather
than to the descendant under the cursor, so every click landed on the canvas
and the handlers on the nodes — all present, all asserted by this suite —
were never reached. It surfaced only when a second control was added to the
drawing and a person tried to use it.

**Why it is recorded rather than fixed:** every way out adds a dependency
the framework does not have. A headless browser in CI is the honest one and
the heaviest; a JavaScript engine would run the logic but not the gestures;
transliterating the script into Python, as the baseline comparison already
does, tests a copy rather than the thing that ships. What went in instead is
narrower: the suite now asserts *where* the capture is taken, because that
is the part a text can see.

**Decision needed:** accept inspection as the method for anything the page
does in the browser and say so in `50-verification.md`, or take on a
headless browser for the graph and the comparison.

## The graph cannot be pinched

**Found:** while reviewing the explorable graph (2026-08-08).

**What diverged:** a limit of FR-VIEW-110, deliberate at the time and never
written down. One finger pans and a wheel zooms, but two fingers do nothing
— a touch device can move the graph and not scale it.

This entry carried a second limit until 2026-08-11: `order_layers` anchored a
node on the layer immediately above, so a requirement deriving from something
two layers up fell to the end of its own layer. ADR-0012 removed that layout,
and the defect went with it.

**Decision needed:** whether pinch zoom is worth code. It is a pointer
handler counting two contacts.

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

## The width of the installer's output belongs to no requirement

**Found:** while reviewing the checker-rules suite (2026-08-10).

**What diverged:** `tests/installer-smoke.sh` asserts that everything a
fresh install prints fits inside a fixed number of columns, and nothing in
`specs/` says so. The closest requirement, FR-INIT-150, describes *what* the
installer prints — the procedures, where the first requirement goes, the
commands, the upgrade — and is silent about how wide. The assertion arrived
in 0.8.0 with the first-steps block, which had reached 121 columns; the
comment beside it is the only record of why.

The number itself was never argued: 79 was taken as the classic terminal
width and has now been raised to 120 by the maintainer, which is exactly the
kind of change a requirement is supposed to make visible and a test comment
cannot.

**Why it is recorded rather than fixed:** extending FR-INIT-150 to name the
width is an authoring act, and authoring does not ride along with an
implementation phase (FR-SKILL-090). The suite keeps the assertion at 120
meanwhile, so the behaviour is guarded even while the rule is homeless.

**Decision needed:** extend FR-INIT-150 to state that the output fits a
terminal of a stated width, record the width somewhere it can be argued
with, or drop the assertion if the wrapping does not in fact matter. To be
taken up when the requirements frozen in baseline 0.12.0 are implemented.

## A requirement with no links at all is not in the graph

**Found:** while grouping the graph by area (2026-08-11).

**What diverged:** FR-VIEW-060 promises a graph of the links between
requirements grouped by area, and `build_graph` takes its nodes from the
edges — so a requirement no link touches is absent from the drawing rather
than standing in it alone. Under the layered layout that was one box fewer
in a row of sixty-five and nobody could have seen it. In a lane it is a gap
in a column, and a gap at exactly the requirement worth noticing: one that
rests on nothing and that nothing needs.

**Why it is recorded rather than fixed:** this specification has no such
requirement — all 88 carry at least one link — so nothing that ships is
wrong. What is unresolved is what a project in that position should see,
and the answer is not obvious: a fresh install spends its first weeks with
a specification that is mostly unlinked, and a drawing that reserved a row
for every one of them would be tall and empty at exactly the moment it is
first opened.

**Decision needed:** draw every requirement and let the unlinked ones stand
in their lane as islands, or keep the drawing to what has links and say so
on the page next to the count of what was left out.
