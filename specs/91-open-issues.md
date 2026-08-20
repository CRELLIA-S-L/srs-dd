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
requirement — every one of them carries at least one link, which the
`unlinked` rule keeps true — so nothing that ships is wrong. What is unresolved is what a project in that position should see,
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

## One requirement annotated twice in a file cannot be judged from the file

**Found:** while considering a rule against it (2026-08-17).

**What diverged:** nothing yet — this is a rule proposed and left unbuilt,
recorded so the reasoning is not lost. Two `implements:` lines naming one
requirement in one file are noise when they mark the same thing twice, and
correct when the requirement is realized in two places. The checker knows
only the path, so it cannot tell those apart.

The evidence says the noise is not what is there. All seven duplicates in
this repository are the honest kind: FR-INIT-080 marks installing the hook
beside an existing one and saying so; FR-INIT-110 marks deciding which
upgrade notes apply and printing them; FR-INIT-140 marks computing the
framework address and recording it; FR-VIEW-040 and FR-VIEW-210 each mark a
computation and its rendering; IF-SPEC-010 marks the parser and the
tolerance of an unknown key; FR-CHK-150 marks the isolation rule and the
exemption cancelled requirements have from it. A rule warning on all of
them would fire seven times on the first run with nothing wrong, and be
silenced — which is what FR-CHK-160 argues makes a rule worthless.

Finer granularity is the way out and is closed: telling a block from a file
means understanding the structure of the code, and the checker is
language-neutral by construction — the same rule has to work in a project
written in Swift.

A narrow reading works and is nearly empty. A requirement named twice
inside one uninterrupted run of comment lines is unambiguously one entity,
needs no understanding of code, and occurs zero times here. It would catch
a duplicated paste and nothing else.

**Decision needed:** write the narrow rule as a guard that will rarely
speak — the position FR-CHK-030 is in — or accept that a duplicate
annotation is the author's business and close this.

## FR-INIT-060 carries two obligations under one number

**Found:** while putting the standard into the precious bucket (2026-08-18).

**What diverged:** the statement says the installer refreshes the checker,
the viewer and the skills without a flag, *and* that files which may be the
project's own are refreshed only with `--force` and only when marked. Two
capabilities, one identifier, one `verification` field, one status. It reads
as a single sentence because the second half is written as a `while` clause,
which is a subordinate grammatical form doing the work of a second
requirement.

Nothing about this is new — the compound has stood since the requirement was
written — but 0.14.0 added the standard to the second half, so the number now
answers for one more thing than it did.

The cost is not tidiness. A test proving the first half says nothing about
the second, and the status is a single word for both: `implemented` was true
of this requirement while its second half had a gap the size of the standard,
which is exactly how that gap survived to 0.14.0 unseen.

**Decision needed:** split it into two requirements — the second one taking a
new number, since identifiers are never reused — or leave the compound and
accept that its status and its tests speak for two behaviours at once.

## A project that adopted the framework never receives the standard

**Found:** while making upgrades refresh the standard (2026-08-18).

**What diverged:** `--mode adopt` deliberately keeps a project's own
`specs/README.md` (FR-INIT-040), and the file it keeps carries no
`SRS-DD-<version>` marker — so `--force` will not replace it either, now or
ever. Verified end to end: adopt on a project whose `specs/README.md` says
"We follow the SRS-DD standard", then `--force`, answers `specs/README.md
(no SRS-DD marker — not ours, merge manually)` and leaves the file alone.

That refusal is correct in itself. What follows from it is that such a
project has no copy of the standard at all, while the skills installed
alongside cite its sections by name — a licence `CON-SPEC-020` grants on the
grounds that the standard is the same document in every project. For an
adopted project it is no document at all. The installer says one advisory
line about merging, once, at adopt time.

**Decision needed:** install the standard beside theirs under a name that
cannot collide, so the citations resolve; or drop the citations from the
shipped procedures and let them explain themselves; or accept that adopted
projects merge the standard by hand and say so where it will be read twice
rather than once.

## A procedure states what another procedure does without reading it

**Found:** twice in one session, while reviewing the 0.14.0 work
(2026-08-18).

**What diverged:** an agent reported that the `## [X.Y.Z]` changelog section
"is written by a person" and belongs to the maintainer. It does not: step 3
of `srs-release` drafts it, and the description line of that skill says so in
so many words. The claim was inferred from the refusal message in
`tools/srs_release.py`, which only says the section is missing. The same
agent had earlier reported that the template section of the `srs` skill could
not be removed without loss, and withdrew it two rounds later on discovering
that nothing referenced it — again a claim about this project's own files,
made without opening them.

Neither is covered by what exists. FR-SKILL-160 binds a claim that a test
proves something; FR-SKILL-170 binds a claim that an observation is a
finding, and demands its consequence. Both leave alone the plainest kind of
claim there is: what a procedure prescribes, what a file contains, who
performs a step. Those are read in seconds and were not read.

Adding a summary of each procedure somewhere central was considered and
rejected while writing this entry: every skill's `description` already
carries one, `srs-release`'s already names the drafting step, and a second
copy inside another skill is what FR-SKILL-020 forbids. The gap is not in
what is available to read.

**Decision needed:** write a third requirement in that family — a procedure
asserting what another procedure does, or what a file holds, reads it first
— or accept that this is a matter of care rather than of rule, and that the
two existing members of the family draw the line where it can be drawn.

## A project without the register never hears that it exists

**Found:** while writing the grounds layer's install and delivery
requirements (2026-08-20).

**What diverged:** FR-GND-280 offers the register as a choice at install and
at adoption, FR-GND-290 forbids an upgrade from adding it to a project that
has none, and FR-GND-320 ships the grounds procedure only where the
register is installed. Each is right on its own, and together they leave
nobody to tell a project that the layer exists. A project installed before the
layer shipped, or one that declined it once, receives nothing that mentions it
again: the tooling is refreshed, the skills are refreshed, and not one of them
says there is a subsystem available for the asking. The only description lives
in this repository — `docs/`, the changelog, the concept — which is exactly
what a target never reads.

**Decision needed:** have the upgrade say once, where the register is
absent, that it can be added and how; or accept that the layer is found
through the framework's own documentation and say so where that documentation
will be read; or install a minimal procedure everywhere, against the reason
FR-GND-320 gives for installing none.

## Calibration is built at a fraction of what the concept describes

**Found:** while planning the grounds layer (2026-08-20).

**What diverged:** the concept the layer is built from weighs a judgement by
its author's measured accuracy, after Cooke's method — calibration questions
with known answers, experts scored against them, opinions combined by that
score. What FR-GND-210 builds is the half that needs no programme: how many
of an author's verdicts a later measurement reversed. It answers whether
this person has been right before, and nothing else. No rule weighs a class
III verdict by it, and the register has no way to acquire calibration
questions in the first place.

**Why it is recorded rather than fixed:** the missing half is an
organizational undertaking — somebody writes the questions, somebody runs
them, somebody keeps the scores — and none of that is a file format or a
rule. No amount of code here produces it.

**Decision needed:** say in the layer's standard that calibration stops at
the reversal count and the weighting is deliberately not attempted; or carry
the fuller model as intended work and name what a project would have to run
to get it.

## An unchangeable minimum can be made loud, not prevented

**Found:** while planning the grounds layer (2026-08-20).

**What diverged:** the concept holds that an ideology carries a minimum that
changes only by dissolving the ideology itself — not amendable, whatever the
evidence arrives. A repository delivers no such thing. A file is a file: the
minimum can be edited by anyone who can commit, and what the framework
actually offers is that the edit is visible, attributable and diffable. The
requirements for ideology and its self-revision are not written yet, so the
difference is at present written down nowhere.

**Decision needed:** state the weaker promise when those requirements are
authored — the minimum is changed loudly, never silently — or place
immutability outside the repository, in protected paths, required review or
signed commits, none of which this framework configures in any target today.

## A hypothesis carries one number where the concept carries two

**Found:** while reviewing the grounds standard against the concept it is
built from (2026-08-20).

**What diverged:** the record format has `refuted_if` and nothing else
numeric. The concept has two numbers and says plainly that confusing them is
expensive: the target magnitude is what the thing is being built for, the
refutation threshold is the line below which the claim is false, and a result
landing between them neither supports nor refutes — it says the claim
survived and its magnitude was wrong. That middle band cannot be expressed
here at all, and `grounds/README.md` demonstrates the collapse in its own
worked example, where the statement claims three studios in ten and
`refuted_if` fires below the same 0.30.

The cost is not that a number is missing. It is that a measurement in the
middle has no name, so it reads as support to whoever compares it against the
threshold and as failure to whoever compares it against the target — and both
are looking at the same row of evidence. The concept's example is exactly
this case: 19% measured against a 15% floor and a 30% aim, where what
actually happened was that the pricing built on 30% had to go back for
review while the hypothesis itself stood.

**Why it is recorded rather than fixed:** a second number is a new key on the
hypothesis record, and no requirement prescribes one. Writing it into the
standard alone would describe machinery nothing obliges, and the format is
the one thing that cannot be quietly corrected later — a key may be added but
never renamed, and this register ships to other projects.

**Decision needed:** give the hypothesis record a `target` key beside
`refuted_if`, with a rule that the two are not the same number and a verdict
of its own for the band between them; or state in the standard that the
register records only the refutation line and that the target lives in the
plan it justifies, naming where; or accept the collapse and say so, so that
nobody reads the single number as if it were the aim.
