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
FR-VIEW-100 — its data is checked against git, its script by having been
read — and to FR-VIEW-130, where the suite holds that every view links to a
requirement but not that following such a link arrives anywhere. The set
this covers grows with the page: each addition to it is one more behaviour
verified by a person who remembers to look.

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

## The graph is layered over a specification that is not

**Found:** while drawing every kind of link (2026-08-10).

**What diverged:** FR-VIEW-060 promises a graph layered by derivation, and
the data does not support the axis. This specification holds 21 derivation
links against 54 dependencies; 64 of its 85 requirements have no derivation
parent at all and land in one row, and the deepest derivation chain is two.
The drawing measures 8689 by 179 — a ribbon that says almost nothing
vertically and cannot be read when fitted to a screen. FR-VIEW-150 narrows
it in a click, but the default view is the one a newcomer sees.

The structure the specification actually has is the area: six of them,
between 9 and 19 requirements each, with 48 of the 75 links staying inside
one. Types do not group — 70 of 85 are `FR`.

**Why it is recorded rather than fixed:** the candidate is an arc diagram
grouped by area — a column of requirements ordered by area and identifier,
links drawn as arcs beside it, roughly 1200 by 1900 instead of the ribbon,
and less code than the layered layout it would replace. That is a change of
what the page promises, not a repair: FR-VIEW-060 would be reworded,
ADR-0010 loses its subject entirely and would have to be superseded rather
than amended, and FR-VIEW-110's "pull a node aside" stops meaning anything
where a node's position is its place in an ordering. Authoring does not
ride along with an implementation phase (FR-SKILL-090).

**Decision needed:** adopt the arc diagram and supersede ADR-0010, deciding
at the same time what replaces dragging a node — nothing, a collapse of a
whole area, or dragging kept as decoration. Or keep the layered drawing and
accept that its vertical axis carries two levels for a fifth of the
requirements.
