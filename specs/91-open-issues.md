# Open issues

Discrepancies between the specification and the code, unfinished work, unresolved questions.
Each entry states what diverged, where it was found, and what decision is needed.
Entries are removed once the maintainer decides which side is right and the fix lands.

## Nothing in the suites exercises a gesture

**Found:** while building the explorable graph (2026-08-08).

**What diverged:** FR-VIEW-110 promises panning, zooming, collapsing an area and highlighting, and carries `verification: I` because no browser and no JavaScript engine is a dependency of this project.
`tests/view-smoke.sh` asserts that the handlers and the stage are in the page — which catches a deletion, and nothing else.
The same limit applies to the comparison of FR-VIEW-100 — its data is checked against git, its script by having been read — and to FR-VIEW-130, where the suite holds that every view links to a requirement but not that following such a link arrives anywhere.
The set this covers grows with the page: each addition to it is one more behaviour verified by a person who remembers to look.

On 2026-08-11 this stopped being hypothetical.
Clicking a node had opened nothing since the canvas began capturing the pointer on `pointerdown`: while an element holds the capture the browser dispatches the click to it rather than to the descendant under the cursor, so every click landed on the canvas and the handlers on the nodes — all present, all asserted by this suite — were never reached.
It surfaced only when a second control was added to the drawing and a person tried to use it.

**Why it is recorded rather than fixed:** every way out adds a dependency the framework does not have.
A headless browser in CI is the honest one and the heaviest; a JavaScript engine would run the logic but not the gestures;
transliterating the script into Python, as the baseline comparison already does, tests a copy rather than the thing that ships.
What went in instead is narrower: the suite now asserts *where* the capture is taken, because that is the part a text can see.

**Decision needed:** accept inspection as the method for anything the page does in the browser and say so in `50-verification.md`, or take on a headless browser for the graph and the comparison.

## The graph cannot be pinched

**Found:** while reviewing the explorable graph (2026-08-08).

**What diverged:** a limit of FR-VIEW-110, deliberate at the time and never written down.
One finger pans and a wheel zooms, but two fingers do nothing — a touch device can move the graph and not scale it.

This entry carried a second limit until 2026-08-11: `order_layers` anchored a node on the layer immediately above, so a requirement deriving from something two layers up fell to the end of its own layer.
ADR-0012 removed that layout, and the defect went with it.

**Decision needed:** whether pinch zoom is worth code.
It is a pointer handler counting two contacts.

## The standard never says how many numbers an area has

**Found:** while measuring NFR-CHK-010 against a generated specification of 500 requirements (2026-08-06). 401 of them were rejected.

**What diverged:** `RE_ID` (`tools/srs_check.py`) requires exactly three digits, so an area holds 999 numbers, of which the mandated steps of 10 use
99. The Identifier section of `specs/README.md` says numbers "go in steps of 10" and never mentions either figure.

This entry claimed until 2026-08-12 that the hundredth requirement is a hard error a project cannot work around without splitting the area.
That was wrong on both counts.
No rule requires a multiple of ten — the checker has no such rule at all — so an intermediate number passes, which is what the step of 10 leaves room for and what FR-CHK-075 used when FR-CHK-070 was split.
And the binding ceiling on a project this framework can serve is not here: the graph draws 150 linked requirements and states what it left out (`GRAPH_NODE_LIMIT`, NFR-VIEW-010), measured the same day at 150, 300 and 800.

Widening the grammar to four digits was considered and rejected on 2026-08-12. Both shapes break: mixed widths sort wrongly everywhere the tools order by identifier string, and fixed four digits with a leading zero renames every published identifier, which INV-SPEC-010 forbids.

**Decision needed:** say in the Identifier section how many numbers an area has, and that the step of 10 is a convention the checker does not enforce — or decide the standard need not say it, and close this.

## A requirement with no links at all is not in the graph

**Found:** while grouping the graph by area (2026-08-11).

**What diverged:** FR-VIEW-060 promises a graph of the links between requirements grouped by area, and `build_graph` takes its nodes from the edges — so a requirement no link touches is absent from the drawing rather than standing in it alone.
Under the layered layout that was one box fewer in a row of sixty-five and nobody could have seen it.
In a lane it is a gap in a column, and a gap at exactly the requirement worth noticing: one that rests on nothing and that nothing needs.

**Why it is recorded rather than fixed:** this specification has no such requirement — every one of them carries at least one link, which the `unlinked` rule keeps true — so nothing that ships is wrong.
What is unresolved is what a project in that position should see, and the answer is not obvious: a fresh install spends its first weeks with a specification that is mostly unlinked, and a drawing that reserved a row for every one of them would be tall and empty at exactly the moment it is first opened.

Since 2026-08-12 the question has a second half.
A `withdrawn` requirement is deliberately outside the `unlinked` report (FR-CHK-150) because it has no link left to forget, and one that nothing ever pointed at is invisible in the drawing for the same reason as any other isolated requirement.
Whatever is decided here, the two should agree: a requirement the checker has stopped asking about is a poor candidate for a lane of its own.

**Decision needed:** draw every requirement and let the unlinked ones stand in their lane as islands, or keep the drawing to what has links and say so on the page next to the count of what was left out.

## One requirement annotated twice in a file cannot be judged from the file

**Found:** while considering a rule against it (2026-08-17).

**What diverged:** nothing yet — this is a rule proposed and left unbuilt, recorded so the reasoning is not lost.
Two `implements:` lines naming one requirement in one file are noise when they mark the same thing twice, and correct when the requirement is realized in two places.
The checker knows only the path, so it cannot tell those apart.

The evidence says the noise is not what is there.
All seven duplicates in this repository are the honest kind: FR-INIT-080 marks installing the hook beside an existing one and saying so; FR-INIT-110 marks deciding which upgrade notes apply and printing them; FR-INIT-140 marks computing the framework address and recording it; FR-VIEW-040 and FR-VIEW-210 each mark a computation and its rendering; IF-SPEC-010 marks the parser and the tolerance of an unknown key; FR-CHK-150 marks the isolation rule and the exemption cancelled requirements have from it.
A rule warning on all of them would fire seven times on the first run with nothing wrong, and be silenced — which is what FR-CHK-160 argues makes a rule worthless.

Finer granularity is the way out and is closed: telling a block from a file means understanding the structure of the code, and the checker is language-neutral by construction — the same rule has to work in a project written in Swift.

A narrow reading works and is nearly empty.
A requirement named twice inside one uninterrupted run of comment lines is unambiguously one entity, needs no understanding of code, and occurs zero times here.
It would catch a duplicated paste and nothing else.

**Decision needed:** write the narrow rule as a guard that will rarely speak — the position FR-CHK-030 is in — or accept that a duplicate annotation is the author's business and close this.

## FR-INIT-060 carries two obligations under one number

**Found:** while putting the standard into the precious bucket (2026-08-18).

**What diverged:** the statement says the installer refreshes the checker, the viewer and the skills without a flag, *and* that files which may be the project's own are refreshed only with `--force` and only when marked.
Two capabilities, one identifier, one `verification` field, one status.
It reads as a single sentence because the second half is written as a `while` clause, which is a subordinate grammatical form doing the work of a second requirement.

Nothing about this is new — the compound has stood since the requirement was written — but 0.14.0 added the standard to the second half, so the number now answers for one more thing than it did.

The cost is not tidiness.
A test proving the first half says nothing about the second, and the status is a single word for both: `implemented` was true of this requirement while its second half had a gap the size of the standard, which is exactly how that gap survived to 0.14.0 unseen.

**Decision needed:** split it into two requirements — the second one taking a new number, since identifiers are never reused — or leave the compound and accept that its status and its tests speak for two behaviours at once.

## A project that adopted the framework never receives the standard

**Found:** while making upgrades refresh the standard (2026-08-18).

**What diverged:** `--mode adopt` deliberately keeps a project's own `specs/README.md` (FR-INIT-040), and the file it keeps carries no `SRS-DD-<version>` marker — so `--force` will not replace it either, now or ever.
Verified end to end: adopt on a project whose `specs/README.md` says "We follow the SRS-DD standard", then `--force`, answers `specs/README.md (no SRS-DD marker — not ours, merge manually)` and leaves the file alone.

That refusal is correct in itself.
What follows from it is that such a project has no copy of the standard at all, while the skills installed alongside cite its sections by name — a licence `CON-SPEC-020` grants on the grounds that the standard is the same document in every project.
For an adopted project it is no document at all.
The installer says one advisory line about merging, once, at adopt time.

**Decision needed:** install the standard beside theirs under a name that cannot collide, so the citations resolve; or drop the citations from the shipped procedures and let them explain themselves; or accept that adopted projects merge the standard by hand and say so where it will be read twice rather than once.

## A procedure states what another procedure does without reading it

**Found:** twice in one session, while reviewing the 0.14.0 work (2026-08-18).

**What diverged:** an agent reported that the `## [X.Y.Z]` changelog section "is written by a person" and belongs to the maintainer.
It does not: step 3 of `srs-release` drafts it, and the description line of that skill says so in so many words.
The claim was inferred from the refusal message in `tools/srs_release.py`, which only says the section is missing.
The same agent had earlier reported that the template section of the `srs` skill could not be removed without loss, and withdrew it two rounds later on discovering that nothing referenced it — again a claim about this project's own files, made without opening them.

Neither is covered by what exists.
FR-SKILL-160 binds a claim that a test proves something; FR-SKILL-170 binds a claim that an observation is a finding, and demands its consequence.
Both leave alone the plainest kind of claim there is: what a procedure prescribes, what a file contains, who performs a step.
Those are read in seconds and were not read.

Adding a summary of each procedure somewhere central was considered and rejected while writing this entry: every skill's `description` already carries one, `srs-release`'s already names the drafting step, and a second copy inside another skill is what FR-SKILL-020 forbids.
The gap is not in what is available to read.

**Decision needed:** write a third requirement in that family — a procedure asserting what another procedure does, or what a file holds, reads it first — or accept that this is a matter of care rather than of rule, and that the two existing members of the family draw the line where it can be drawn.

## Calibration is built at a fraction of what the concept describes

**Found:** while planning the grounds layer (2026-08-20).

**What diverged:** the concept the layer is built from weighs a judgement by its author's measured accuracy, after Cooke's method — calibration questions with known answers, experts scored against them, opinions combined by that score.
What FR-GND-210 builds is the half that needs no programme: how many of an author's verdicts a later measurement reversed.
It answers whether this person has been right before, and nothing else.
No rule weighs a class III verdict by it, and the register has no way to acquire calibration questions in the first place.

**Why it is recorded rather than fixed:** the missing half is an organizational undertaking — somebody writes the questions, somebody runs them, somebody keeps the scores — and none of that is a file format or a rule.
No amount of code here produces it.

**Decision needed:** say in the layer's standard that calibration stops at the reversal count and the weighting is deliberately not attempted; or carry the fuller model as intended work and name what a project would have to run to get it.

## An unchangeable minimum can be made loud, not prevented

**Found:** while planning the grounds layer (2026-08-20).

**What diverged:** the concept holds that an ideology carries a minimum that changes only by dissolving the ideology itself — not amendable, whatever the evidence arrives.
A repository delivers no such thing.
A file is a file: the minimum can be edited by anyone who can commit, and what the framework actually offers is that the edit is visible, attributable and diffable.
The requirements for ideology and its self-revision are not written yet, so the difference is at present written down nowhere.

**Decision needed:** state the weaker promise when those requirements are authored — the minimum is changed loudly, never silently — or place immutability outside the repository, in protected paths, required review or signed commits, none of which this framework configures in any target today.

## A hypothesis carries one number where the concept carries two

**Found:** while reviewing the grounds standard against the concept it is built from (2026-08-20).

**What diverged:** the record format has `refuted_if` and nothing else numeric.
The concept has two numbers and says plainly that confusing them is expensive: the target magnitude is what the thing is being built for, the refutation threshold is the line below which the claim is false, and a result landing between them neither supports nor refutes — it says the claim survived and its magnitude was wrong.
That middle band cannot be expressed here at all, and `grounds/README.md` demonstrates the collapse in its own worked example, where the statement claims three studios in ten and `refuted_if` fires below the same 0.30.

The cost is not that a number is missing.
It is that a measurement in the middle has no name, so it reads as support to whoever compares it against the threshold and as failure to whoever compares it against the target — and both are looking at the same row of evidence.
The concept's example is exactly this case: 19% measured against a 15% floor and a 30% aim, where what actually happened was that the pricing built on 30% had to go back for review while the hypothesis itself stood.

**Why it is recorded rather than fixed:** a second number is a new key on the hypothesis record, and no requirement prescribes one.
Writing it into the standard alone would describe machinery nothing obliges, and the format is the one thing that cannot be quietly corrected later — a key may be added but never renamed, and this register ships to other projects.

**Decision needed:** give the hypothesis record a `target` key beside `refuted_if`, with a rule that the two are not the same number and a verdict of its own for the band between them; or state in the standard that the register records only the refutation line and that the target lives in the plan it justifies, naming where; or accept the collapse and say so, so that nobody reads the single number as if it were the aim.

## A requirement does not say which frames bound it

**Found:** while sorting the concept's record format against what the layer builds (2026-08-20).

**What diverged:** the concept gives a requirement a `bounded_by` field — the frames it falls under — and this layer has no equivalent.
The reason it was left out is that nothing reads it: the dashboard states what each frame has refused from the frame's own journal, and a field with no reader is what the constitution declines by default.

**And the half of that reason which was not true.** This entry used to say frames are applied when a hypothesis is let into the fog, "by a person following a procedure rather than by a stored link".
Measured 2026-08-25:
there is no such procedure.
`srs-bet` names a frame once, in the list of what the register holds, and asks nothing about frames at any step;
`FR-GND-250` is the only requirement that mentions them, and it describes the dashboard.
So a frame in this layer is a journal and nothing else — a hypothesis a frame forbids can be recorded, staked on and built against, and the register says nothing.
The concept puts frames at the first gate precisely because refusing is cheapest before anything is built on it, and that gate is missing rather than manual.

There is a second reason it could not be copied as written.
In the concept `bounded_by` sits on the requirement, and nothing in this layer writes into a requirement file, so it would have had to move to the bet — the same displacement `bets_on` went through, and the same one the instrument marker went through after it.

**Why it is recorded rather than fixed:** leaving it out is a decision, and an undocumented decision is indistinguishable from an oversight.
A reader comparing the concept with the format will find the gap and, finding no note, will close it — adding a key that can afterwards be added to but never renamed or removed.

**The gate half was settled 2026-08-25**, and it was the half that mattered.
`FR-GND-530` puts a hypothesis against the frames before it is admitted, and a frame that refuses one takes a row in its own journal — which is also the first procedure that writes into a journal at all, so `FR-GND-250`'s reading of an empty one can finally tell a frame nobody tested from a frame nobody has.
It binds a person, deliberately: whether a claim falls under a frame is a judgement about meaning, and a frame a checker could match has stopped being a frame.

**Decision needed:** none for now.
What remains is the field, and it is still not wanted — nothing reads it, and the gate above needs no stored link to do its work.
If a reading is ever wanted — which requirements a frame would have refused, or what a frame now touches that it did not when it was drawn — the field goes on the bet and not on the requirement.

## Whether the specification could live in a database

**Found:** raised by the maintainer (2026-08-20).

**What is being asked:** keep requirements in a database rather than in markdown files, and put a real editing interface on top of it.

**What the argument actually is, and it is sharper than "concurrency".** Identifiers are allocated per branch: `srs-new` picks "the next free one in the area" by reading the file in front of it.
Two branches authoring at once therefore pick the same number, and the collision is not an accident of timing but the design.

Worse than a conflict, and this was run rather than reasoned.
Two branches each adding `FR-CORE-050` to the same file, one near the top and one at the end, **merge cleanly**: git reports no conflict and exits 0, because the texts do not overlap.
What lands is a specification with the number twice.
Nobody is asked to resolve anything, so nobody knows there was anything to resolve.

What catches it is the gate afterwards: `FR-CHK-010` reports `identifier FR-CORE-050 is already used at specs/10-fr-core.md:6`, naming both occurrences, and the build fails on a branch that was already merged.
Resolving it then means renumbering one side, which is permitted — `INV-SPEC-010` binds a *published* identifier, and one that never left a branch is not published — but choosing which side moves means understanding what both requirements say.
That is not work a product manager will do, and asking them to do it is how a specification stops being theirs.

**What the argument proves, and what it does not.** It proves a central point is needed.
It does not prove that point must also be the store:
allocation and storage are separate axes, and the collision sits on the first one.

**What it collides with, by name.** `NFR-SPEC-020` says the specification shall be stored as markdown files a review tool diffs line by line, "with no database and no build step between the author and the file".
This is not an addition to it; it is its reversal, and taking the idea up means withdrawing or superseding that requirement rather than working around it.
What hangs off it is worth listing before anyone decides, because none of it is decoration:

- a requirement change is reviewed today in the same pull request as the code it governs, by a tool that already exists and that nobody has to be taught;
- history is git's, which is what lets the checker read baselines from tags and lets `INV-SPEC-040` mean anything;
- the two generated files are compared byte for byte by a gate, which needs a text the generator and the reader agree on;
- `NFR-SPEC-010` keeps the tooling to the standard library, and a database ends that whether it is embedded or served.

**Three doors, and the expensive one should be opened last.**

*Allocate centrally, store in files.*
One small service hands out the next number per area and records that it did.
Files stay the source of truth, review tooling is untouched, git remains the history, and the collision this issue is about stops happening.
It answers nothing else — two people editing the same requirement's text still meet an ordinary content conflict.

*Keep product managers off branches altogether.*
The interface is the only way they touch requirements; it writes to one branch on their behalf and engineers merge.
There are then no parallel requirement branches to collide, no git in front of anyone who should not be looking at it, and the store is still files.
This is the shape closest to what is being asked for, and it costs a service and a UI rather than a migration.

*Move the store.*
A database holds the requirements and the files are generated from it, or abandoned.
This is the only door that gives row-level locking across a large team and offline editing with server-side merge — and the only one that ends the four things listed above.

**Decision needed:** which of the three doors, and the question that separates them is not how much concurrency there is but who is expected to hold a branch.
If the answer is "not product managers", the second door is enough and the specification survives intact.
If the store must move, then which requirement replaces `NFR-SPEC-020`, and what it promises instead about review, history and the gate.

## Four of the register's five kinds have no file

**Found:** while building the reconfirmation criterion (2026-08-22).
Narrowed on 2026-08-23, when the first records were written.

**What diverged:** ADR-0018 decided, on 2026-08-19, that this repository would keep a grounds register of its own — option 3 of three, chosen over "ship the layer, do not use it here" on the ground that a format never held by a real entry is a format whose first real entry will want a rename.

**What landed:** `grounds/10-h-authoring.md` now holds `H-010` and `H-020`, written and owned by the maintainer, and the dashboard counts them.
The argument ADR-0018 made is served: the format has held real entries and wanted no rename.

**What is still open:** there is no `00-ideology.md`, no `01-frames.md`, no `02-unclaimed.md`, no `03-bets.md` — not empty files, no files.
A target installing the layer receives all four as scaffolding; the repository that ships them has one file of its own.
The ideology is the loudest absence: the standard calls it what the hypotheses are confirmed *for*, so a register holding hypotheses and no ideology confirms them for nothing written down.

**What will not notice:** `tests/grounds-check.sh` asserts that the checker accepts the register strictly and that the committed dashboard matches a fresh run.
Both now hold of a register with two hypotheses in it, which is better than holding vacuously of an empty one — but they hold just as well of a register missing four kinds.
The suite still cannot tell a kind deliberately left unwritten from one nobody got to.

**Decision needed:** whether the other four kinds are wanted here at all.
The two halves are not alike.
An ideology and a frame say what this project is for and what it will not do, and nobody but the maintainer can say either.
A bet and a declaration follow from requirements that already exist and are written by whoever works the register — `FR-GND-500` bars an agent from inventing a hypothesis, not from recording a bet on one.
If the kinds are not wanted, the gate should say so out loud rather than passing in silence, and that part is ordinary work.

## A class III reading is overruled by arithmetic

**Found:** while deciding what the register's first real entries would say (2026-08-23).

**What diverged:** `refuted_if` is required of every `H` record — `srs_grounds.py:84-85` lists it beside `class`, `population`, `expires`, `owner` and `impact` — and FR-GND-140 judges every verdict row against that threshold without asking what class the hypothesis is.
The two class-conditional rules in the file both run the other way: `class-untestable` fires for class I alone (`srs_grounds.py:718`), `verdict-unattributed` for class III alone (`srs_grounds.py:763`).
Nothing exempts class III from the arithmetic.

The standard defines class III as "outside the system: interviews, observation, judgement".
Where the population is small the two obligations cannot both be met.
At `n = 2`, the one-sided Wilson bound FR-GND-150 computes at the default `confidence` of `0.95` reaches 0.575 even when both answers are no — so `verdict_owed` returns `supported` for a threshold as generous as `proportion < 0.50 at n >= 2`, and for every stricter one as well.
Refuting needs the threshold to sit above that bound — above three in five of them doing the thing — which is not the shape a hypothesis about whether something works for people takes.
A maintainer who talks to both, concludes it does not hold, and writes `refuted` gets an error naming a comparison nobody could have won.

That error is arithmetic nobody did, which is what FR-GND-140's own rationale was written against — inverted.
There the danger was a verdict overruling the number; here it is the number overruling the reading the class exists to admit.
Every threshold below that bound returns the same verdict however far apart they are written, and the register records a judgement as its opposite.

This repository walked around it rather than into it.
ADR-0018 predicted the register here would come out mostly class III with named owners and no instruments, and it did; the population that was first proposed for `H-010` was two people, and at that size the bound above reaches 0.575 — which a threshold refutes only by sitting above, and no claim about half of them does.
What was written instead (2026-08-23) widened the population past this team, so `H-010` carries `proportion < 0.50 at n >= 8`, which refutes at 0 or 1 of 8 and gives real gradations above that.
The corner is still there for the next class III hypothesis whose population genuinely is small, and widening is not always available — a claim about two people is a claim about two people, and rewriting it to be about more is a different claim.

**Doors:**

*Make `refuted_if` optional for class III.*
The narrowest change, and it touches the format rather than a rule: IF-GND-010 makes an addition compatible and a removal not, and a required key becoming optional is a loosening every existing record survives.
It costs the guarantee that every hypothesis was written falsifiable before it was measured — which is most of why the field is required.

*Do not apply the verdict arithmetic to class III.*
The threshold stays required and stays a declaration of what would count; the checker stops compelling a verdict from it where the measurement was a person's reading.
Keeps falsifiability visible and gives up the guard against a class III verdict that flatly contradicts its own numbers.

*Leave it, and record that class III with a small population is not supported by the register.*
Honest, and it means the layer's answer to "we asked both of them" is that this is not a hypothesis.
Then the first entries here are `U` declarations or nothing, and ADR-0018's argument for keeping a register in this repository loses its example.

**Decision needed:** which of the three.
The first two change `tools/srs_grounds.py` and at least one requirement; the third changes `grounds/README.md` and closes nothing else.

## Where a rule binding every procedure physically lives is not settled

**Found:** while deciding how to build FR-SKILL-200 and FR-SKILL-220 (2026-08-27), both of which bind "a procedure" rather than a named one.

**What diverged:** this repository holds two patterns for the same problem and nothing chooses between them.

FR-SKILL-170 — *An observation is reported as a finding only once it is one* — is written out in each skill it binds.
Its `code` field names `srs`, `srs-audit` and `srs-harvest`, and each states the rule in its own idiom:
`srs` argues the *therefore* test over three paragraphs, `srs-audit` repeats it against findings, `srs-harvest` states it about an open-issues entry.
Three copies, three wordings, one rule.

ART-030 — builds and test runs need the user's word each time — is stated once in `specs/constitution.md` and cited from six skills in a line apiece.
`skeleton/AGENTS.md` carries the same shape under *The three most frequently broken rules*: cross-cutting obligations, one line each, the constitution cited where the reasoning lives.

The two differ in what they cost and in how they fail.
Restating puts the rule where the agent is already reading and lets each procedure phrase it for its own work; it also means N copies that drift, and it is what FR-SKILL-020 forbids for a standard while saying nothing about a specification.
Citing keeps one copy and one edit; it also means an agent that never follows the citation is bound by a sentence it did not read.

**Decision needed:** whether the two patterns are one rule applied to different cases — and if so, what distinguishes the cases — or whether one of them should absorb the other.
Bringing FR-SKILL-170's family onto the cite-once pattern is the larger move and touches three skills; declaring the split deliberate costs a paragraph in `specs/README.md` and leaves the cost where it is.
FR-SKILL-200 and FR-SKILL-220 are being built on the cite-once pattern meanwhile, which adds two more entries on that side of a split nobody has ruled on.
