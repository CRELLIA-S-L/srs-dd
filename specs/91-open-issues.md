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

**Re-measured 2026-09-08.** The dependency is still absent rather than merely unused: no browser, headless or otherwise, and no JavaScript engine is named anywhere in `ci/`, in `.github/workflows/` or in `tools/ci_selftest.sh`.
`50-verification.md` now carries this under *Known gaps* and points back here, so the limit is written down; the decision below is not.

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

**2026-09-08.** The ceiling that binds is the one named above, and it is now the one being reached.
213 requirements, every one of them linked, against a `GRAPH_NODE_LIMIT` of 150: the page says `63 node(s) beyond the first 150 are not drawn` and names the families that went with them.
No area is near its 999, and a four-digit identifier is still refused — a fixture carrying `FR-CORE-0100` answers `identifier does not match <TYPE>-<AREA>-<NNN>` and exits 1.

**Decision needed:** say in the Identifier section how many numbers an area has, and that the step of 10 is a convention the checker does not enforce — or decide the standard need not say it, and close this.

## A requirement with no links at all is not in the graph

**Found:** while grouping the graph by area (2026-08-11).

**What diverged:** FR-VIEW-060 promises a graph of the links between requirements grouped by area, and `build_graph` takes its nodes from the edges — so a requirement no link touches is absent from the drawing rather than standing in it alone.
Under the layered layout that was one box fewer in a row of sixty-five and nobody could have seen it.
In a lane it is a gap in a column, and a gap at exactly the requirement worth noticing: one that rests on nothing and that nothing needs.

**Why it is recorded rather than fixed:** this specification has no such requirement — every one of them carries at least one link, which the `unlinked` rule keeps true — so nothing that ships is wrong.
Still true on 2026-09-08 at 213 requirements: a strict run reports no `unlinked` finding, and nothing here is `withdrawn`.
What the drawing does with one was run rather than read on the same day — a fixture of three requirements, two linked and one standing alone, renders a page that carries the island in the census, in the list and in its own article, and leaves it out of the graph.
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
All seven duplicates in this repository on 2026-08-17 were the honest kind: FR-INIT-080 marks installing the hook beside an existing one and saying so; FR-INIT-110 marks deciding which upgrade notes apply and printing them; FR-INIT-140 marks computing the framework address and recording it; FR-VIEW-040 and FR-VIEW-210 each mark a computation and its rendering; IF-SPEC-010 marks the parser and the tolerance of an unknown key; FR-CHK-150 marks the isolation rule and the exemption cancelled requirements have from it.
A rule warning on all of them would fire seven times on the first run with nothing wrong, and be silenced — which is what FR-CHK-160 argues makes a rule worthless.

**Re-measured 2026-09-08: 118**, counted over every tracked file with the checker's own `RE_ANNOTATION` and its `srs-ignore` exemption — 42 in `tests/grounds-rules.sh`, 23 in `tools/srs_grounds.py`, 14 in `tests/arch-rules.sh`, the rest spread over ten files.
The grounds and architecture layers arrived in between, and each is checked by a suite that names a requirement in its header and again at the fixture covering it, which is the honest kind at scale.
The argument keeps its direction and multiplies its weight by seventeen: the rule would fire 118 times on the first run with nothing wrong.

Finer granularity is the way out and is closed: telling a block from a file means understanding the structure of the code, and the checker is language-neutral by construction — the same rule has to work in a project written in Swift.

A narrow reading works and is nearly empty.
A requirement named twice inside one uninterrupted run of comment lines is unambiguously one entity, needs no understanding of code, and occurs zero times here — measured again on 2026-09-08 over every tracked file, still zero.
It would catch a duplicated paste and nothing else.

**Decision needed:** write the narrow rule as a guard that will rarely speak — the position FR-CHK-030 is in — or accept that a duplicate annotation is the author's business and close this.

## FR-INIT-060 carries two obligations under one number

**Found:** while putting the standard into the precious bucket (2026-08-18).

**What diverged:** the statement says the installer refreshes the checker, the viewer and the skills without a flag, *and* that files which may be the project's own are refreshed only with `--force` and only when marked.
Two capabilities, one identifier, one `verification` field, one status.
It reads as a single sentence because the second half is written as a `while` clause, which is a subordinate grammatical form doing the work of a second requirement.

Nothing about this is new — the compound has stood since the requirement was written — but 0.14.0 added the standard to the second half, so the number now answers for one more thing than it did.
0.16.0 did it again on 2026-09-08 with the architecture standard: the second half now enumerates seven kinds of file against the first half's three, under one identifier, one status and one `tests` field.

The cost is not tidiness.
A test proving the first half says nothing about the second, and the status is a single word for both: `implemented` was true of this requirement while its second half had a gap the size of the standard, which is exactly how that gap survived to 0.14.0 unseen.

**Decision needed:** split it into two requirements — the second one taking a new number, since identifiers are never reused — or leave the compound and accept that its status and its tests speak for two behaviours at once.

## A project that adopted the framework never receives the standard

**Found:** while making upgrades refresh the standard (2026-08-18).

**What diverged:** `--mode adopt` deliberately keeps a project's own `specs/README.md` (FR-INIT-040), and the file it keeps carries no `SRS-DD-<version>` marker — so `--force` will not replace it either, now or ever.
Verified end to end: adopt on a project whose `specs/README.md` says "We follow the SRS-DD standard", then `--force`, answers `specs/README.md (no SRS-DD marker — not ours, merge manually)` and leaves the file alone.
Re-run on 0.16.0 (2026-09-08): the answer is unchanged, and no copy of the standard reaches the target under any name.
What the installed procedures then cite into nothing is eight references across three of them — the Baselines section three times, *How to phrase* twice, and one each to Lifecycle, What-not-to-do and the map of which file holds what.

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

**2026-09-08.** Two more, both inside this file.
The entry on `carries` below said the specification checker was equally silent about a path nobody has; `FR-CHK-055` has reported it as an error since 0.14.0, and one run of the checker says so.
The entry on where a cross-cutting rule lives said six skills cite `ART-030`; four do, in seven lines, and four was also the count on the day that entry was written.
Both are claims about files in this repository, both cost one `grep`, neither had one.

**Decision needed:** write a third requirement in that family — a procedure asserting what another procedure does, or what a file holds, reads it first — or accept that this is a matter of care rather than of rule, and that the two existing members of the family draw the line where it can be drawn.

## Calibration is built at a fraction of what the concept describes

**Found:** while planning the grounds layer (2026-08-20).

**What diverged:** the concept the layer is built from weighs a judgement by its author's measured accuracy, after Cooke's method — calibration questions with known answers, experts scored against them, opinions combined by that score.
What FR-GND-210 builds is the half that needs no programme: how many of an author's verdicts a later measurement reversed.
It answers whether this person has been right before, and nothing else.
No rule weighs a class III verdict by it, and the register has no way to acquire calibration questions in the first place.

**Why it is recorded rather than fixed:** the missing half is an organizational undertaking — somebody writes the questions, somebody runs them, somebody keeps the scores — and none of that is a file format or a rule.
No amount of code here produces it.

**2026-09-08.** Half of this is already decided, and not where the entry looks for it: the rationale of `FR-GND-210` says the weighting needs calibration questions and a programme to run them, and calls the reversal count its affordable half.
What is missing is the layer's standard — the word calibration does not occur in `grounds/README.md` at all, so a reader comparing the concept with the register meets the gap exactly where no note is.

**Decision needed:** say in the layer's standard that calibration stops at the reversal count and the weighting is deliberately not attempted; or carry the fuller model as intended work and name what a project would have to run to get it.

## An unchangeable minimum can be made loud, not prevented

**Found:** while planning the grounds layer (2026-08-20).

**What diverged:** the concept holds that an ideology carries a minimum that changes only by dissolving the ideology itself — not amendable, whatever the evidence arrives.
A repository delivers no such thing.
A file is a file: the minimum can be edited by anyone who can commit, and what the framework actually offers is that the edit is visible, attributable and diffable.

**Corrected 2026-09-08.** The entry ended here with "the requirements for ideology and its self-revision are not written yet, so the difference is at present written down nowhere", and that stopped being true three days after it was written.
`FR-GND-510` and `FR-GND-520` landed on 2026-08-23 and charge for widening what may move an ideology, and `grounds/README.md` states the weaker promise in its own words: the register cannot stop the opposite failure, because a file is a file.
So the promise is written down.
What is not written down is anything stronger.

**Decision needed:** whether immutability is placed outside the repository — protected paths, required review or signed commits, none of which this framework configures in any target today — or the loud-not-prevented promise is all this layer will ever offer, and is said once where the ideology is defined rather than in a rationale a reader arrives at by accident.

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

## Whether the specification could live in a database

**Found:** raised by the maintainer (2026-08-20).

**What is being asked:** keep requirements in a database rather than in markdown files, and put a real editing interface on top of it.

**What the argument actually is, and it is sharper than "concurrency".** Identifiers are allocated per branch: `srs-new` picks "the next free one in the area" by reading the file in front of it.
Two branches authoring at once therefore pick the same number, and the collision is not an accident of timing but the design.

Worse than a conflict, and this was run rather than reasoned.
Two branches each adding `FR-CORE-050` to the same file, one near the top and one at the end, **merge cleanly**: git reports no conflict and exits 0, because the texts do not overlap.
What lands is a specification with the number twice.
Nobody is asked to resolve anything, so nobody knows there was anything to resolve.
Re-run 2026-09-08 on a fresh pair of branches forked from one base, one inserting `FR-CORE-050` in the middle of the file and the other appending it: still exit 0, still no conflict, still the number twice.

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
- `NFR-SPEC-010` keeps the tooling to the standard library, and a database ends that whether it is embedded or served;
- `INV-SPEC-070` stands on it by name — a line breaks where the meaning breaks *because* a review tool diffs the file line by line, and that rule has nothing to govern once the store is rows.

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
Unchanged on 2026-09-08: a fresh run of the dashboard still reads `0 ideology, 0 frame, 2 hypothesis, 0 bet, 0 unclaimed`, while the specification grew by 28 requirements in 0.16.0, not one of which carries a bet.

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

**Run rather than reasoned, 2026-09-08.** A class III record with `refuted_if: proportion < 0.50 at n >= 2`, a measurement of 0 at n = 2 and a verdict of `refuted` fails the checker: "0 is < 0.5 by less than a sample of 2 can miss by: at 95% confidence the truth reaches 0.575, so the verdict it compels is 'supported'".
The arithmetic above was on paper until then.

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

ART-030 — builds and test runs need the user's word each time — is stated once in `specs/constitution.md` and cited from four of the twelve skills in seven lines: three of them in `srs-audit`, two in `srs`, one each in `srs-check` and `srs-harvest`.
`skeleton/AGENTS.md` carries the same shape under *The three most frequently broken rules*: cross-cutting obligations, one line each, the constitution cited where the reasoning lives.

The two differ in what they cost and in how they fail.
Restating puts the rule where the agent is already reading and lets each procedure phrase it for its own work; it also means N copies that drift, and it is what FR-SKILL-020 forbids for a standard while saying nothing about a specification.
Citing keeps one copy and one edit; it also means an agent that never follows the citation is bound by a sentence it did not read.

**Decision needed:** whether the two patterns are one rule applied to different cases — and if so, what distinguishes the cases — or whether one of them should absorb the other.
Bringing FR-SKILL-170's family onto the cite-once pattern is the larger move and touches three skills; declaring the split deliberate costs a paragraph in `specs/README.md` and leaves the cost where it is.
FR-SKILL-200 and FR-SKILL-220 are being built on the cite-once pattern meanwhile, which adds two more entries on that side of a split nobody has ruled on.

**2026-09-08.** An audit finished `FR-SKILL-200`'s set: `srs-release` was the ninth procedure that names requirements to a person, and the only one carrying no line.
It adds no entry to either side — the rule was already on the cite-once side, and this completes it rather than choosing again.

It also does not bear on the split, and that is worth recording so nobody tries it as evidence.
The one thing that came out of it looks like an argument at first: `srs-release` names identifiers in two places and the rule binds only one of them — the diff shown to the maintainer, not the changelog section, where the format is parsed by the installer and a citation would carry a status into a record nobody re-dates.
An exception, in other words, and the cite-once pattern is supposed to be the one where an exception is stated where the rule lives and inherited everywhere.
It was not: the sentence is in `srs-release` and `AGENTS.md` says nothing about it, because the exception belongs to the only procedure that writes a changelog and would sit there under either pattern.
A case that distinguishes the two would be an exception several procedures share.

**Corrected the same day.** This entry said the rule was cited from six skills in a line apiece.
Counted over `.claude/skills/*/SKILL.md` it is four skills and seven lines, and the same count holds at the commit this entry was written on, so the number was wrong when it was written rather than overtaken.
The comparison survives it — one statement against three restatements is still the shape — but a claim about this repository's own files went in without the `grep` that settles it, which is the entry above.

## An element can carry a path that is not there

**Found:** while building the architecture layer (2026-09-02), on a fixture written to test something else.
**Corrected:** 2026-09-08 — half of what this entry claimed was already false when it was written, and the correction is below.

**What diverged:** an element's `carries` may name a path that does not exist, and the architecture checker stays silent.
The fixture: an element carrying `carries: [src, src/vanished.py]` where only the directory does.
`tools/srs_arch.py` reported nothing at all, which is not a bug in it — no requirement asks for the reading.
`FR-ARCH-060` holds the ownership direction and answers the question "is this file carried", which a vanished file is not asked.

**What this entry got wrong.** It said the same of the specification checker, and that was never true.
`FR-CHK-055` reports a `code` or `tests` entry naming an absent path as an **error**, and has since baseline 0.14.0 — two weeks before this entry was written.
Run against a requirement carrying `code: [src/a.py, src/gone.py]`, `tools/srs_check.py` answers `error: code points to a nonexistent path src/gone.py` and exits 1.
The entry was written from the architecture layer's fixture outward, and the claim about the other checker was inferred rather than run; the requirement that answers it is one line in `10-fr-chk.md`, the file the entry had already opened to cite `FR-CHK-200`.
That is the failure mode *A procedure states what another procedure does without reading it* names above, arriving in the register the entry itself lives in.

The remaining case is ordinary rather than exotic: a file is renamed or deleted, the element's `carries` keeps the old path, and the map goes on publishing a part that owns something nobody has.
The specification's own side of it is covered and fails the build; the layer's side is silent.
Both halves were run on 2026-09-08 rather than read: an element carrying `carries: [src, src/vanished.py]` passes `srs_arch.py --strict` with exit 0 and no mention of the path, while a requirement carrying `code: [src/a.py, src/gone.py]` answers `error: code points to a nonexistent path src/gone.py` and exits 1.

**Decision needed:** whether a path an element names and nobody has is a finding.
Two answers, the third having been built already.
The architecture layer could report it for `carries`, which makes the layer say about its own field what `FR-CHK-055` already says about the specification's — the symmetric answer, and the cheap one.
Or it stays unreported deliberately, on the ground that a path is a claim about a working tree rather than about the description, and a checker that reads the disk starts failing for reasons that have nothing to do with what is written — a sparse checkout, a generated file, a submodule not initialised.
That second answer is harder to hold now than it was: the specification checker already reads the disk for exactly this, so the cost it warns about is one this project has already accepted once.

## The link graph sits exactly on the floor the checker sets

**Found:** while measuring what an impact query can answer (2026-09-09).

**What diverged:** nothing is broken, and that is what makes this worth recording.
`unlinked` fires only when a requirement is "linked to nothing, **and** nothing links to it" — a floor of one link in either direction.
Measured 2026-09-09 over this repository: 0.96 outgoing links per requirement, and **124 of 215 have nothing pointing at them at all**.
Over Crellian the same day, which installed the framework and wrote its own 571: 1.04 and 318 of 571.
The two projects use the fields in opposite proportions — `depends_on` carries 177 of 206 edges here, `derives_from` carries 404 of 595 there — and still land on the same number.

The consequence is not tidiness.
An impact query answers from these links, so a radius computed today is worth exactly what the links are worth, and nobody knows what that is.
The transitive radius has a median of 0.

**Two readings, and they are not distinguishable from the data.**
Either a specification of this shape genuinely is that loosely coupled, or the links are under-written — every requirement carrying the one link the rule demands and stopping there, because an agent writing them satisfies the stated bar and no more.
A missing link is invisible by construction, so no rule can tell them apart.

Two mechanical proxies were tried and both fail on volume, which is the argument `FR-CHK-160` makes about a rule nobody can afford to read: "two requirements name the same file and link to neither" fires **3648** times over this repository, and the narrower "annotated in adjacent regions and not linked" fires **319** of 382.
Neither is a rule; both were run rather than reasoned.

**Why it is recorded rather than fixed:** the fix is a pass over what is already written, one area at a time, with a person settling each link — and that is planned work rather than a decision.
What is not settled is which of the two readings is true.

**What would settle the reading:** the density of the links on requirements authored *after* the authoring procedure is made to show its search, against the 0.96 measured here.
If the number does not move, the specification is loosely coupled and the floor was never a ceiling.
If it moves, the retrieval at authoring time was the cause, and the same repair is owed to everything already written.

**Decision needed:** what the link graph is for, and therefore what would count as enough of it.
`unlinked` states a floor of one and nothing states a target, so "under-written" has no meaning here that anybody wrote down — which is why the measurement above can be read two ways at all.
Either say what the graph is expected to carry, or accept that only the floor is stated and the rest is a judgement made one requirement at a time, and say that instead.

## An element's dependency is never resolved against the elements

**Found:** while planning a cycle rule for the architecture layer (2026-09-09).

**What diverged:** `check_records` in `tools/srs_arch.py` resolves an element's `requirements:` against the specification and reports what does not exist — that is `FR-ARCH-040`.
Nothing does the same for `depends_on`.
An element may declare a dependency on `E-999`, which no element carries, and the layer says nothing.

The specification's own side of this is covered from both directions: a link to a requirement that does not exist is an error, and `FR-CHK-055` reports a path that is not there.
The architecture layer resolves one of its two identifier-bearing fields and not the other.

**Why it is recorded rather than fixed:** it was found while building something else, and a rule is not written in passing.
Its cost is one comparison against a set the checker already holds, so this is cheap rather than hard — which is a reason to decide it deliberately rather than to slip it in.

**Decision needed:** report an element dependency naming no element, by the pattern `FR-ARCH-040` already set for `requirements:` — or say that `depends_on` is deliberately unresolved, and why one field is checked and the other is not.

## The page's links to the source are promised in one area and built in another

**Found:** while passing over the links of area CI (2026-09-10).

**What diverged:** `FR-CI-040` obliges the pipeline to publish the page "with links back to the source at the built revision", and that is the only statement in the specification which mentions them.
It is a CI requirement, so it describes what the pipeline does.

The pipeline does not do it. The viewer does: `--repo-url` on the command line, `repo_url` in `specs/srs-config.json`, and the code that turns a path from a `code` field into a link at a pinned revision.
No requirement of area VIEW describes any of that — the nearest `implements:` above that code names `FR-VIEW-050`, which is about comparing against a baseline.
The `code` field of `FR-CI-040` names the two pipeline files and not `tools/srs_view.py`.

Nothing mechanical can see this. The file is claimed by other requirements, the annotation is not wrong about the code it sits over, and a statement that describes another area's tool breaks no rule.

**Why it is recorded rather than fixed:** which side is wrong is not the auditor's call.
Either area VIEW is missing a requirement for a capability that has its own flag and its own configuration key, or `FR-CI-040` is claiming behaviour that belongs to the viewer and should say only that the pipeline passes the revision in.

**Decision needed:** write the missing viewer requirement and narrow `FR-CI-040` to what the pipeline actually does — or declare the source links a detail of the page already described by `FR-VIEW-060`, and say why a flag and a configuration key of their own do not make them behaviour.
