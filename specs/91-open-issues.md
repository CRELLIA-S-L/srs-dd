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

## The standard never says how many numbers an area has

**Found:** while measuring NFR-CHK-010 against a generated specification of
500 requirements (2026-08-06). 401 of them were rejected.

**What diverged:** `RE_ID` (`tools/srs_check.py`) requires exactly three
digits, so an area holds 999 numbers, of which the mandated steps of 10 use
99. The Identifier section of `specs/README.md` says numbers "go in steps of
10" and never mentions either figure.

This entry claimed until 2026-08-12 that the hundredth requirement is a hard
error a project cannot work around without splitting the area. That was
wrong on both counts. No rule requires a multiple of ten — the checker has
no such rule at all — so an intermediate number passes, which is what the
step of 10 leaves room for and what FR-CHK-075 used when FR-CHK-070 was
split. And the binding ceiling on a project this framework can serve is not
here: the graph draws 150 linked requirements and states what it left out
(`GRAPH_NODE_LIMIT`, NFR-VIEW-010), measured the same day at 150, 300 and
800.

Widening the grammar to four digits was considered and rejected on
2026-08-12. Both shapes break: mixed widths sort wrongly everywhere the
tools order by identifier string, and fixed four digits with a leading zero
renames every published identifier, which INV-SPEC-010 forbids.

**Decision needed:** say in the Identifier section how many numbers an area
has, and that the step of 10 is a convention the checker does not enforce —
or decide the standard need not say it, and close this.

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
requirement — all 95 carry at least one link — so nothing that ships is
wrong. What is unresolved is what a project in that position should see,
and the answer is not obvious: a fresh install spends its first weeks with
a specification that is mostly unlinked, and a drawing that reserved a row
for every one of them would be tall and empty at exactly the moment it is
first opened.

Since 2026-08-12 the question has a second half. A `withdrawn` requirement
is deliberately outside the `unlinked` report (FR-CHK-150) because it has no
link left to forget, and one that nothing ever pointed at is invisible in
the drawing for the same reason as any other isolated requirement. Whatever
is decided here, the two should agree: a requirement the checker has stopped
asking about is a poor candidate for a lane of its own.

**Decision needed:** draw every requirement and let the unlinked ones stand
in their lane as islands, or keep the drawing to what has links and say so
on the page next to the count of what was left out.

## A procedure spells out a rule that belongs to specs/README.md

**Found:** while building FR-SKILL-120 into the remaining procedures
(2026-08-11).

**What diverged:** FR-SKILL-020 has the skills point at `specs/README.md`
for the rules instead of restating them, and step 4 of `srs-new` restates
one — the qualities a statement is obliged to have, which
`specs/README.md` owns under *How to phrase*. When the judgement was
extended to `srs` and `srs-harvest` both were written to point rather than
repeat; `srs-new` was left as it stood, so the framework now names those
qualities in three places, one of which is FR-SKILL-120's own statement.

**Why it is recorded rather than fixed:** the passage is not a list. It
says what the checker proves and what it cannot see, gives an agent the
sentences to say back — "this names two capabilities, I would split it" —
and argues why no word list would serve instead. Cutting it to a pointer
would leave the step that teaches the judgement saying nothing about it.
And the third naming is a requirement rather than a document, which is the
one place a rule is supposed to live.

**Decision needed:** accept the passage as teaching text and narrow
FR-SKILL-020, which today reads as absolute, or cut it to a pointer and
accept a step 4 that only refers.
