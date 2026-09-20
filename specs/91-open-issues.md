# Open issues

Discrepancies between the specification and the code, unfinished work, unresolved questions.
Each entry states what diverged, where it was found, and what decision is needed.
Entries are removed once the maintainer decides which side is right and the fix lands.

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
Moved on 2026-09-18, by one file: `03-bets.md` exists and holds twenty-one bets, `B-010` to `B-210`, every one on `H-030`, so the dashboard reads `0 ideology, 0 frame, 3 hypothesis, 21 bet, 0 unclaimed`; the ideology, the frames and the unclaimed list are still no files, and every bet is on the one hypothesis about the documentation rather than on any of the 236 requirements that predate it.

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
The comparison survives it — one statement against three restatements is still the shape — but a claim about this repository's own files went in without the `grep` that settles it, which is what `FR-SKILL-280` was later written against.

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
That is the failure mode `FR-SKILL-280` was later written against — a statement about what the project's files say, made without reading them — arriving in the register the entry itself lives in.

The remaining case is ordinary rather than exotic: a file is renamed or deleted, the element's `carries` keeps the old path, and the map goes on publishing a part that owns something nobody has.
The specification's own side of it is covered and fails the build; the layer's side is silent.
Both halves were run on 2026-09-08 rather than read: an element carrying `carries: [src, src/vanished.py]` passes `srs_arch.py --strict` with exit 0 and no mention of the path, while a requirement carrying `code: [src/a.py, src/gone.py]` answers `error: code points to a nonexistent path src/gone.py` and exits 1.

**Decision needed:** whether a path an element names and nobody has is a finding.
Two answers, the third having been built already.
The architecture layer could report it for `carries`, which makes the layer say about its own field what `FR-CHK-055` already says about the specification's — the symmetric answer, and the cheap one.
Or it stays unreported deliberately, on the ground that a path is a claim about a working tree rather than about the description, and a checker that reads the disk starts failing for reasons that have nothing to do with what is written — a sparse checkout, a generated file, a submodule not initialised.
That second answer is harder to hold now than it was: the specification checker already reads the disk for exactly this, so the cost it warns about is one this project has already accepted once.

## Releases on the forge, and when to start them

**Found:** raised by the maintainer (2026-09-19), after the first release whose changelog section was held to the installer's summary by a test.

**What is being asked:** whether the framework's releases should also be published as releases on the forge — a page per `vX.Y.Z` tag with notes, the source archives the forge attaches itself, a "latest" mark, and the releases box on the repository's front page.

**What it does not touch.** Nothing the tooling does depends on it.
Installs and upgrades clone by tag — `git clone --branch vX.Y.Z`, `srs_upgrade.py --ref` — and a release page is a page for people over a tag that already exists.
Starting or not starting changes no procedure and no requirement.

**What would have to hold when it starts, settled now so that the decision is not re-derived:**

- The notes are the `## [X.Y.Z]` section of `CHANGELOG.md` and nothing else, extracted the way `tools/srs_init.py` parses it for an upgrade; a second text written for the page is a second source of truth for the same release.
- The pipeline publishes on a pushed `v*` tag and only then, so that `CON-SPEC-030` stands — the maintainer tags, the pipeline reacts — and refuses where the tag's number is not the version `tools/srs_check.py` prints, which is the mistake a hand-made release makes most.
- `spec/v*` tags are not releases; the trigger filters them out, or `INV-SPEC-030` is broken by the forge on the maintainer's behalf.
- Tags are annotated from then on — the seventeen that exist are lightweight and stay so.
- The older sections in `CHANGELOG.md` can be published for their tags after the fact in one pass, so that the page does not open with a single entry.

**Decision taken 2026-09-19:** not before 1.0.0.
A release page is a claim to be read by strangers, and the first part of the version is still zero; the first `1.` is the maintainer's claim that the shape has settled, and the releases page starts with it.
What stays open until then is only the order of the two acts on that day — the requirement in area CI with its test on the extraction, and the step in `srs-release` that says what the pushed tag will cause.

## Documents outside a repository, and whether they want a tool of their own

**Found:** a working note of 2026-09-18, written after the landing page was specified (ADR-0027, `FR-DOC-010` to `FR-DOC-210`) and no requirement of that area named a file under `tools/` — the checks it needed are two suites under `tests/` — recorded here on 2026-09-20 and the note discarded.

**What is being asked:** whether the way the landing page is described — the cut into sections recorded as a decision, each section owing its reader something and naming the sources it restates, everything machine-readable held by a test, and currency a hypothesis with a threshold (`H-030`) — should become an instrument of its own for documents that live where there is no code, no specification and no git in front of the author: a company policy over laws and decisions, an onboarding over configuration and an org chart, an API description over code and schemas, in a wiki or a cloud editor.

**What is already settled.** Inside a repository that carries the framework, nothing is missing: any document can be described today with an area of its own, a requirement per section and its checks under `tests/`, and the everyday rule `FR-DOC-200` states — re-read the section when a source it restates moves — rides on the blast radius the links already compute.
The four principles are not the open part; they are written in the DOC area's rationales.

**Decision taken 2026-09-20:** not a separate instrument while the question it shares with every idea of a product for people outside git — who holds the branch, and how a change reaches a document nobody edits in a repository — stays unanswered.
Until then the instrument for such a document is this framework installed where the document is put by somebody's hand.

**What stays open, and would have to be answered first:**

- A source outside git — an article of a law, a record in a directory, a schema kept elsewhere — is a link no checker resolves. Whether it wants a layer of external sources of its own, each carrying the date it was last read against, the way a hypothesis carries a term.
- A document with no single owner: whose decision the cut into sections is.
- Documents that are meant to drift — a log, a changelog, a protocol — where what can be described is the form of an entry and not a set of sections; a different shape, and possibly a different instrument.

What would be measured, if this were ever taken up, is drafted and not recorded, by the register's rule that a threshold and an owner are set by whoever will answer for the measurement: the currency of a described document against an undescribed one on another corpus, the hours a first description costs per thousand words, and the share of sections whose sources the author named rather than an agent inferred afterwards.
