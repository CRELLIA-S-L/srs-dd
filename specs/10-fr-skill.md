# Functional requirements — skill

The agent procedures in `.claude/skills/`.
They are plain markdown read by whatever tool the project uses, so their behavior is what they oblige an agent to do, not code that runs.

### FR-SKILL-010 — The everyday loop

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [.claude/skills/srs/SKILL.md]
tests: []
created: 2026-08-07
```

The `srs` procedure **shall** require naming the requirements a change belongs to before the code is written, creating one where none exists, and re-reading their statements as the loop is closed, so that anything built and not described is written down or taken out.

**Rationale.** Everything else in the framework is downstream of this single habit; the checker can prove a link exists but never that the change was thought about first.
Both ends are needed, and the second was learned the hard way: a change that begins as a fix to an existing requirement is exempt from writing a new one, and that exemption quietly covers whatever else gets added along the way — a control appeared on the rendered page that no statement mentioned, because the work was framed as repair and nobody re-read the requirement it repaired.
Re-reading one statement costs a paragraph; a change that names no requirement at all is itself the signal that either nothing behavioural happened or the requirement is missing.

### FR-SKILL-020 — Rules are stated once

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-010]
refines: []
conflicts_with: []
code: [.claude/skills/srs/SKILL.md, .claude/skills/srs-new/SKILL.md, .claude/skills/srs-harvest/SKILL.md, .claude/skills/srs-init/SKILL.md, .claude/skills/srs-baseline/SKILL.md, .claude/skills/srs-audit/SKILL.md, .claude/skills/srs-bet/SKILL.md, .claude/skills/srs-check/SKILL.md, .claude/skills/srs-page/SKILL.md, .claude/skills/srs-release/SKILL.md, .claude/skills/srs-upgrade/SKILL.md, .claude/skills/srs-arch/SKILL.md, specs/README.md, grounds/README.md, arch/README.md]
tests: []
created: 2026-08-07
```

The skills **shall** point at the standard defining a format rather than restating what that standard defines.

**Rationale.** Two copies of the same rule diverge, and the copy an agent happens to read wins — which is the failure mode this whole framework exists to prevent.

**Named by role, and there is more than one.** This said `specs/README.md` while `srs-bet` was already obeying it word for word against `grounds/README.md` — "deliberately not restated here: two descriptions of the same rules would eventually diverge" — and no requirement covered that half.
Naming both would have written the register into a rule that holds where there is none, so the statement names neither: a standard is whatever document defines a format, and a project has as many as it has formats.
The generality is the point rather than an evasion — a third standard would be covered on the day it appears, which is the day somebody would otherwise restate it.

Nothing here reaches the register's own machinery.
The two files this added are shipped sources that exist whether or not this repository runs a register — `grounds/README.md` is the canonical copy the installer reads, as `specs/README.md` is — and no link into the grounds area was made.
A project that declined the layer has no `srs-bet` to hold to this and no second standard to point at, and the statement is simply quiet about it.

**All of them, because the rule binds all of them.** Six skills define no format and satisfied this by having nothing to restate, and the field named none of them — so `--code` on those six answered as though no rule governed the file, which is the question asked before anybody edits one.
An incomplete field here is green forever: the checker proves the paths exist and never that they are all of them.

What is forbidden is a second definition, not a second mention.
This read as an absolute ban on saying anything the standard also says, and under that reading step 4 of `srs-new` stood in violation of it, recorded as an open question rather than fixed: it names the qualities a statement owes — one capability, verifiable, unambiguous, about behaviour — which `specs/README.md` owns under *How to phrase*.
Cutting it to a pointer would have left the step that teaches the judgement saying nothing about it, because the passage is not a list.
It says what the checker proves and what it cannot see, gives an agent the sentences to say back — "this names two capabilities, I would split it" — and argues why no word list would serve instead.
That is teaching, and it belongs where the teaching happens.

The line is where a reader would go looking.
A procedure that says what the form is — which keys a block carries, what the statuses are, how a link field is spelled — is writing a second standard, and a project that edits one of them gets two answers.
A procedure explaining why a rule exists, or drilling the reader on applying it, is doing its own job.

### FR-SKILL-030 — Harvesting proposes, the maintainer approves

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CHK-070]
refines: []
conflicts_with: []
code: [.claude/skills/srs-harvest/SKILL.md]
tests: []
created: 2026-08-07
```

The `srs-harvest` procedure **shall** write requirements only in batches shown to the maintainer beforehand, with status `draft` and without inventing tests that do not exist.

**Rationale.** A mined specification is a reading of the code, not a decision; the draft status makes the warning list the approval queue.

### FR-SKILL-040 — Setup brings two decisions back to the maintainer

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-INIT-090]
refines: []
conflicts_with: []
code: [.claude/skills/srs-init/SKILL.md]
tests: []
created: 2026-08-07
```

The `srs-init` procedure **shall** have the agent show the requirement areas and the generated lexicon to the maintainer, together with the dry-run install list, and install only after they approve.

**Rationale.** Areas are the middle segment of every identifier and identifiers are immutable; the lexicon decides which words bind.
Both are normative for the target project forever, so neither is settled by whoever happens to be driving the agent.

### FR-SKILL-050 — An audit reports, it does not repair

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-040]
refines: []
conflicts_with: []
code: [.claude/skills/srs-audit/SKILL.md]
tests: []
created: 2026-08-07
```

The `srs-audit` procedure **shall** report drift between the specification and the code without changing either side on its own.

**Rationale.** When the two disagree it is unknown which one is wrong, and that is the maintainer's call — a helpful fix here would silently pick a side.

### FR-SKILL-060 — The upgrade procedure travels with the project

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-120]
refines: []
conflicts_with: []
code: [.claude/skills/srs-upgrade/SKILL.md, tools/srs_init.py]
tests: [tests/upgrade-smoke.sh]
created: 2026-08-08
```

The skills installed into a project **shall** include the upgrade procedure, so that an agent working there can upgrade the framework without being told where it lives.

**Rationale.** `srs-init` stays framework-only by design — it installs into somebody else's repository.
Upgrading is the one part of it a project needs to carry itself, and until now nothing in an installed project mentioned upgrades at all.

### FR-SKILL-070 — The release procedure travels with the framework

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CI-070]
refines: []
conflicts_with: []
code: [.claude/skills/srs-release/SKILL.md, tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-08
```

Before cutting a release, the `srs-release` procedure **shall** have the agent propose the version number for the maintainer to confirm and draft the changelog section by its format contract; it stays in the framework repository and is never installed into a project.

**Rationale.** The command is one line, but two of its inputs are not the agent's to settle.
The version number follows from what actually changed — an article amended, a shipped file touched, a requirement reworded — and that reading belongs to the maintainer, exactly as the areas and the lexicon do in `srs-init`.
The changelog section an agent can draft, provided it knows the rule this project tripped over four times: the first sentence of every entry stands alone, because the installer prints that sentence and cuts the rest.
Framework-only, like `srs-init`: a target releases nothing of ours.

That half is kept by the installer, not by this file: `SKILLS` in `tools/srs_init.py` lists what travels, and `srs-release` is absent from it.
Named in `code` for the reason FR-SKILL-060 and FR-SKILL-080 name the same file — a field short of where an obligation is realized is green forever, and whoever edits that tuple is the one who needs to be told.

### FR-SKILL-080 — The baseline procedure travels with the project

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-SPEC-010]
refines: []
conflicts_with: []
code: [.claude/skills/srs-baseline/SKILL.md, tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-09
```

The skills installed into a project **shall** include the baseline procedure, so that freezing a specification is asked for by name in the project that owns it.

**Rationale.** `srs-release` stays in the framework repository because a target releases nothing of ours; a baseline is the opposite — every project freezes its own specification, and the procedure has to be where that happens.
What the procedure contains is FR-SKILL-130: this one is about it being there, which is the half a suite can hold.

### FR-SKILL-130 — The baseline procedure settles the number and offers an audit

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-080]
refines: []
conflicts_with: []
code: [.claude/skills/srs-baseline/SKILL.md]
tests: []
created: 2026-08-11
```

Before a baseline row is written, the procedure **shall** show what changed since the previous baseline, offer an audit of the requirements that change touches, and propose the version for the maintainer to settle.

**Rationale.** The command is one line, and none of the three things around it is the agent's to decide.
The number is a claim about the specification.
The audit is offered because a baseline is the last cheap moment: after it, the frozen state is what every reader compares against, and a statement nobody can test freezes exactly as well as a good one — scoped to what the diff names, because auditing everything at every baseline is the step people stop taking.
And the commit that makes the baseline real happens in whatever git client the project uses (CON-SPEC-030).

Verified by inspection, like every other requirement about what a procedure says: `tests/installer-smoke.sh` can prove the file arrives and nothing more, which is why that half is FR-SKILL-080 and this half is read.

### FR-SKILL-090 — Authoring a requirement is not implementing it

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [.claude/skills/srs-new/SKILL.md, .claude/skills/srs/SKILL.md]
tests: []
created: 2026-08-10
```

When a requirement is authored, the authoring procedure **shall** end at the written requirement and at whatever architecture decision the discussion settled, leaving the building of it to a task started separately.

**Rationale.** Requirements here have been born `implemented` in the same commit as their code, so `deferred` never happened and no state existed in which the specification described something not yet built.
A baseline can then only record what already shipped, which is why freezing one felt like bookkeeping rather than a statement of intent (INV-SPEC-030).
Separating the two acts is what gives a baseline something to freeze.
The architectural part of that discussion is a decision, not behaviour, so it goes where decisions go — `specs/adr/` — and only when there was a choice to settle: a requirement describes what the system must do, and how it will be built has no place in it.

### FR-SKILL-100 — The checks a change calls for are named, not guessed

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-010]
refines: []
conflicts_with: []
code: [.claude/skills/srs-check/SKILL.md, tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-10
```

When a change is finished, the check procedure **shall** name the checks the requirements it touched call for — the specification checker, the grounds checker where the project carries a register, the architecture checker where it carries the layer, the tests those requirements list, and what a person has to look at where the method is not a test — and offer to run them rather than running them unasked.

**Rationale.** The specification already answers this and nobody reads it for the purpose: every requirement carries a `verification` method and the paths that verify it, so which checks a change calls for is derivable rather than a matter of memory.
A method of `I` or `D` is where this matters most — those never appear in a suite, and the reader is told what to look at or learns about it from a bug.
Offering rather than running is not politeness but ART-030: builds and test runs need the user's word each time.

The statement said "the checker" while there was one.
A project carrying a grounds register has two, and its gate fails on a dashboard the change left stale (`FR-GND-370`) — so a procedure naming only the first hands back work that passes everything it named and reddens the pipeline.
Naming the second is conditional, because a project without a register has no such command to run.
The third arrived with the architecture layer and on the same terms: it regenerates a map the gate compares, so a change that moved a file between parts and did not run it fails exactly where the register's does.
The procedure named it before this sentence did, which is the direction that stays invisible — a check the code offers and no statement asks for is reported by nothing.

### FR-SKILL-110 — The specification can be read as a page on request

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060, FR-VIEW-140]
refines: []
conflicts_with: []
code: [.claude/skills/srs-page/SKILL.md, tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-10
```

When the specification is to be read rather than grepped, the page procedure **shall** render it as one self-contained page and open it.

**Rationale.** Two commands and a path, which is two commands and a path more than a reader should have to remember — and the reason to have the page at all is the audience that will never run either.
What the procedure adds beyond the commands is what the commands do not say: the file is self-contained and can simply be sent to somebody, `--repo-url` is what makes its links to the code work, and CI publishes the same page from the default branch so a link may already exist.

### FR-SKILL-120 — Whoever writes a statement judges what no checker reaches

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-090, INV-SPEC-060]
refines: []
conflicts_with: []
code: [.claude/skills/srs-new/SKILL.md, .claude/skills/srs-harvest/SKILL.md, .claude/skills/srs/SKILL.md]
tests: []
created: 2026-08-10
```

When a statement is written or reworded, the procedure doing so **shall** judge it against the qualities no checker reaches — one capability, verifiable, unambiguous, and about behavior rather than implementation — and say what it found before the text is recorded.

**Rationale.** A specification may be written in any language, so a word list is the wrong instrument: what reads as vague depends on the sentence, not on the vocabulary, and a script strict enough to catch "as needed" would reject half of a language it does not know.
An agent reads the sentence and can judge it, and that judgement is the only thing standing between a requirement and a statement nobody can test.
It stays out of audit because the cost of fixing a statement is lowest before anything derives from it — but a statement enters through more doors than the authoring dialog.
One is mined from code in a batch, another is reworded while the loop is closed around changed behavior, and both land in the same file at the same cost.
Guarding one door and leaving two open protects the requirements least likely to be wrong.

### FR-SKILL-140 — The declared method is checked against the statement

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: [FR-SKILL-120]
conflicts_with: []
code: [.claude/skills/srs-new/SKILL.md]
tests: []
created: 2026-08-11
```

When a verification method is chosen, the authoring procedure **shall** report a statement that the chosen method has no way to confirm, before the requirement is recorded.

**Rationale.** The method is asked for after the sentence is settled, and the dialog never comes back to it, so `T` gets declared over a statement no test could assert.
Nothing catches that: the checker only sees that the `tests` field is empty, and it says so long afterwards, when the requirement is already built and somebody has to write a test that cannot be written.
The two are on the table together in exactly one step, which is where the question costs nothing.
It is narrower than the judgement it refines:
FR-SKILL-120 asks whether anyone could confirm the statement, this asks whether the declared method can.

### FR-SKILL-150 — Withdrawing a requirement resolves what stands on it

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [INV-SPEC-050]
refines: []
conflicts_with: []
code: [.claude/skills/srs/SKILL.md]
tests: []
created: 2026-08-12
```

Before a requirement's status becomes `withdrawn`, the procedure doing so **shall** show what links to it and settle each dependant with the maintainer.

**Rationale.** A withdrawal is the one edit that breaks requirements it never touches, and the four link fields break differently: `depends_on` leaves a requirement meaningless, `derives_from` leaves it with no reason, `refines` leaves it a special case of nothing, and `conflicts_with` leaves nothing wrong at all.
FR-CHK-190 reports the wreckage afterwards; this is what stops it being made.

Directly is what the procedure shows — grouped by field, with the transitive remainder as a number.
Not to spare the screen: every resolution acts on the requirements that point at this one, and any of those resolutions may itself be a withdrawal with a tree of its own.
The closure is settled one level per decision, and a display that showed it whole would invite the opposite (ADR-0013).

Inspection rather than test, because what is verified is that a procedure written for a person says these things.
No suite here runs a dialog, and one that asserted the wording would be a copy of the file rather than a check on it.

### FR-SKILL-170 — An observation is reported as a finding only once it is one

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-160]
refines: []
conflicts_with: []
code: [.claude/skills/srs/SKILL.md, .claude/skills/srs-audit/SKILL.md, .claude/skills/srs-harvest/SKILL.md]
tests: []
created: 2026-08-17
```

Before reporting something as a finding, the procedure doing so **shall** establish what follows from it, and say so with the finding or drop it.

**Rationale.** An agent reading a specification notices far more than matters: a count that looks stale, a file in an odd place, a flag no statement names.
Reported as they come, each arrives at the maintainer as homework — read this, work out whether it means anything.
A list of those is worse than a short list, because the reader cannot tell the two kinds apart and starts skimming both.

The test is a sentence the reporter has to be able to finish: *therefore*.
Therefore this must be fixed; therefore this is deliberate and here is why;
therefore nobody can tell without a decision that is the maintainer's.
All three are findings.
What is not a finding is an observation with no therefore — and the cost of writing one is paid by the reader, which is why the rule sits on the reporter.

"Cannot tell" stays a legitimate answer and is not an escape from this: it is a finding whose consequence is *a decision is needed*, and it is reported with the options.
What it may not become is a place to put anything unresolved — the difference is whether the reporter looked and could not settle it, or did not look.

This is FR-SKILL-160 one step up.
That one refuses to call a test proof until the edit that would redden it is named; this refuses to call an observation a finding until its consequence is named.
Both replace a feeling that something is wrong with a statement that can be checked, and both put the work on the side that has the context — which is never the reader.

Verified by inspection, like every requirement about what a procedure says.
No suite runs a dialog, and one that asserted the wording would be a copy of the file rather than a check on it.

### FR-SKILL-160 — A test counts as proof only if it could fail

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-050]
refines: []
conflicts_with: []
code: [.claude/skills/srs-audit/SKILL.md]
tests: []
created: 2026-08-12
```

When judging whether a listed test proves a statement, the `srs-audit` procedure **shall** count it proven only where it can name the change to the code that would make that test fail.

**Rationale.** Reading a test says what it mentions, not what it would catch, and the two come apart exactly where it matters.
A requirement whose statement carries two obligations can have a suite that exercises one of them and a `tests` field that looks filled; a rule that fires on three link fields can have a fixture for one.
Both shapes read as covered — the file is named, the fixtures are there, the subject matches — and both leave a behaviour that could be deleted with the suite still green.
Naming the edit that would redden the test is the question that separates them, and it is the same question a reader asks anyway, only made explicit.

Named rather than run, because the audit does not execute anything: it is read-only by FR-SKILL-050, and ART-030 puts a test run behind the maintainer's confirmation.
The reasoning form costs nothing and is available while reading, which is where the judgement is being made.

This is a criterion, not a method of deriving what to judge.
How cases come out of a statement is the procedure's own business and no requirement governs it — a gap this one does not close.

### FR-SKILL-180 — Authoring asks what the requirement stands on

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-GND-500]
refines: []
conflicts_with: []
code: [.claude/skills/srs-new/SKILL.md]
tests: []
created: 2026-08-23
```

Where the project carries a grounds register, the authoring procedure **shall** ask what the new requirement stands on, leaving the answer to a bet on a hypothesis already recorded, to a declaration that it rests on none, or to nothing.

**Rationale.** The register's join lives in a bet, and until now nothing in the authoring dialog mentioned the register at all: the two trees were connected by a procedure somebody had to remember to run afterwards (`srs-bet`), which is the arrangement under which the connection does not get made.
Authoring is the one moment when whoever knows why the requirement exists is in the room, and it costs a question.

**Asks, and does not require.** INV-GND-030 forbids a rule of the layer from demanding that a requirement be named by a bet.
This is a rule about a procedure rather than about the layer, so a demand made here would keep that invariant's letter and lose its point: the invented link it exists to prevent would get invented at the one moment somebody is being asked for one.
"Neither" is a complete answer and the one an author gives most often; what the question buys is that it was asked while the answer was still cheap, not that it came back positive.

The third answer is the one that needs saying out loud.
Where the claim looks worth making and no hypothesis carries it, the procedure says so and stops:
writing that hypothesis belongs to whoever will answer for measuring it, and an agent filling in `owner` commits a person who was never asked (FR-GND-500).

Scoped to the dialog, and `srs-harvest` is the gap that leaves.
It produces requirements too and mentions the register nowhere, and a bet recorded after the fact — explaining why something already built is standing there — is the case `srs-bet` calls worth more rather than less.
Whether a procedure that proposes requirements in approved batches can ask this question at the same cost is not settled here.

Only where the register exists — and the guard is in the text rather than in what gets installed.
FR-GND-320 can withhold the register procedure from a target that declined the layer, because that skill is about nothing else;
authoring happens in every project, so this one ships everywhere and asks the question only where there is a `grounds/` to answer it about.
A dialog offering to record a bet in a project that has no register would be describing machinery it does not have.

### FR-SKILL-190 — Setup reads the project's line width rather than guessing it

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-040]
refines: []
conflicts_with: []
code: [.claude/skills/srs-init/SKILL.md]
tests: []
created: 2026-08-26
```

The `srs-init` procedure **shall** have the agent look for a line width the project already states, show what it found and where, and pass it to the installer only once the maintainer approves it.

**Rationale.** Where a project keeps this is not one place: `.editorconfig`, a formatter's configuration, a linter's section in the build file, a line in a contributing guide, or nowhere.
Reading those is what an agent does well and what a script does badly — a script needs a rule per convention, is silently wrong on the ones it was never taught, and acquires a branch with every tool that becomes fashionable.
The agent reads, says what it found and where it found it, and a wrong reading is caught by the person who can see the file it came from.

Approved rather than applied, on the pattern this procedure already uses for the areas and the lexicon: the value ends up in the project's configuration and in its agent guides, so a mistake here is one a maintainer would be reading back for a long time.

Nothing is invented where nothing is found.
A project that has never stated a width gets no parameter and no line in its guides, because a default inserted here would be this framework deciding how somebody else's code is formatted.

### FR-SKILL-200 — A requirement is named by more than its number

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [IF-SPEC-010]
refines: []
conflicts_with: []
code: [AGENTS.md, skeleton/AGENTS.md, specs/README.md, .claude/skills/srs/SKILL.md, .claude/skills/srs-audit/SKILL.md, .claude/skills/srs-check/SKILL.md, .claude/skills/srs-new/SKILL.md, .claude/skills/srs-harvest/SKILL.md, .claude/skills/srs-baseline/SKILL.md, .claude/skills/srs-bet/SKILL.md, .claude/skills/srs-arch/SKILL.md, .claude/skills/srs-release/SKILL.md]
tests: []
created: 2026-08-27
```

When a procedure first names a requirement in what it reports to a person, it **shall** give that requirement's title, the file it is written in and its status, not the identifier alone.

**Rationale.** `FR-CORE-020` is a key, not a name.
It is exactly right inside a link field, where a machine resolves it and a person is not reading; in a paragraph written for somebody it costs them a lookup per mention, and a report full of them gets skimmed rather than read.
The title is one clause, the file is clickable in a terminal and in an editor, and the status says whether this is still something to build against, so what the reader owes the report drops to nothing.

**The side effect is worth more than the rule.** Naming a requirement in full means resolving it, and an identifier cited without being resolved is how a procedure ends up asserting what another procedure does without reading it — the failure recorded in `91-open-issues.md` under that name.
A rule that says "give the title" is the cheapest available form of "open it first".
It does not make an invented title impossible — a plausible one can be written from memory — but the three parts check each other: a title that was guessed is contradicted by the file and the status standing beside it, and one command settles which.
A bare identifier offers nothing to contradict.

First mention and no more.
The same title repeated down a page is the noise this exists to remove, and after the first one the identifier is what the reader is now able to read.

**The file, and not the line.** A line number is right for the minute it is written and wrong after the next edit above it — six of this project's requirements moved in the single ordinary commit before this was reworded, and the same decay is what FR-CHK-070 gives as its reason for keeping identifiers in a warning line.
A citation is read at the speed of a sentence and checked long afterwards, so it carries the parts that keep.
Nothing is lost: the current line is never further away than `srs_view.py <ID>`, which prints it beside everything else the reader came for.
Where it is written rather than a URL, for the same reason it is not a line: `specs/10-fr-ci.md` is followed by one keystroke wherever the reader already is, and a link that leaves the repository is a separate question — for a rendered page, a review comment, somebody who will not clone — that this does not settle.

**The status is the half that catches a plan.** A `superseded` or `withdrawn` requirement named as though it were live is an error the `srs` procedure already calls one, and neither the identifier nor the title shows it.
Three words where the citation is read, and dull in almost every one of them — every requirement in this project is `implemented` as this is written.
They earn their place in the case the procedure cannot afford:
work planned against a requirement that was cancelled while nobody was looking, in a project far enough along to have cancelled some.

**Not typed by hand.** The whole citation is what `srs_view.py --cite` prints, for the reason the annotation warnings print theirs: what a person retypes from memory is what gets invented, and this project shipped an invented one — a title and a file that were never anybody's — inside this very rule's example, until a review caught it.

### FR-SKILL-210 — What is already written is read before something new is

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CHK-050]
refines: []
conflicts_with: []
code: [.claude/skills/srs-new/SKILL.md, .claude/skills/srs-harvest/SKILL.md, .claude/skills/srs/SKILL.md]
tests: []
created: 2026-08-27
```

Before a requirement is written or reworded, the procedure doing so **shall** resolve which requirements already speak to the same behaviour and what links to those, and say what it found.

**Rationale.** The authoring dialog used to ask for links in one line and call their candidates "neighboring requirements", which names the answer without saying how anyone arrives at it.
So the field got filled from whatever the agent happened to remember, and the question the step exists for — is this already said, and what does it disturb — was not asked at all.

Both directions are needed and they answer different questions.
What already speaks to the behaviour says whether it is covered; what links to those says what a new obligation lands on top of.
Either one alone leaves a statement that reads as new and is not, or one that is new and quietly contradicts what it sits beside.

Behaviour rather than files, because the three doors into a specification do not agree on whether there are files to name.
A reworded requirement carries a `code` field and the lookup is a path away; a harvested one arrives with that field already filled from the code it was read out of; and one authored through the dialog has an empty field by design, because authoring ends before building does.
A rule anchored to "the same files" would name a lookup with no input at exactly the door where the question is cheapest to answer.
Which files answer it is the procedure's business: the area, the paths the behaviour will touch, the matrix.

Said out loud rather than merely consulted, on the pattern of every other judgement in the authoring dialog: a lookup nobody reports is a lookup nobody can tell was made.

### FR-SKILL-220 — What to read comes from the specification, not from a search

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CHK-050]
refines: []
conflicts_with: []
code: [AGENTS.md, skeleton/AGENTS.md, .claude/skills/srs/SKILL.md]
tests: []
created: 2026-08-27
```

When a procedure needs the code behind a change, it **shall** take the files to read from the requirements the change belongs to rather than from a search over the codebase, going beyond that set only where it says it did.

**Rationale.** This is the framework's headline claim about cost — the work becomes proportional to the neighbourhood of the change rather than to the size of the project — and no procedure obliges it.
Two of the eleven perform the lookup and both do it by choice: `srs` opens with it, `srs-check` reaches for it to find what a finished change touched.
Nothing holds them to it, nothing holds the next procedure to it, and nothing holds an agent inside one of them to it — a search over the codebase satisfies every rule this framework has, which is how a small change reads a large repository and pays for it in time and in tokens.

Written for what is not bound rather than for a procedure caught doing it wrong.
The ones that read code today either derive the set already or are excluded by the condition: harvesting reads the code roots because the code is its input rather than the neighbourhood of a change, and the audit's sweep of files no requirement names is the declared widening this statement allows for.

The escape hatch is in the statement rather than left implied, because the set is sometimes genuinely short: behaviour with no requirement behind it is exactly what the loop exists to catch, and a procedure that refused to look past the `code` fields would never find it.
What is forbidden is widening in silence — the reader cannot otherwise tell a neighbourhood that was read from one that was searched around.

### FR-SKILL-230 — A mined requirement is checked against what is written

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-030]
refines: []
conflicts_with: []
code: [.claude/skills/srs-harvest/SKILL.md]
tests: []
created: 2026-08-27
```

Before a mined requirement is shown to the maintainer, the harvesting procedure **shall** check it against the requirements already written and report the ones it overlaps.

**Rationale.** Harvesting is for a specification that lags its code, and its own description offers it for "areas of the spec that lag behind the code" — so the ordinary case is mining into a specification that is not empty.
The procedure mentions existing requirements nowhere.
A behaviour already described under one number is proposed again under another, the maintainer approving a batch has no reason to suspect it, and identifiers are never reused: the duplicate is permanent, and the two copies drift from the day they are both approved.

Separate from FR-SKILL-210 because the question is a different one.
That one asks what a new statement disturbs; this asks whether it is new at all, and it is asked of a batch produced from code rather than of a sentence somebody is writing.

### FR-SKILL-240 — A question about the system is entered through its vocabulary

```yaml
status: deferred
verification: I
derives_from: []
depends_on: [FR-VIEW-250]
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-09-09
```

Where a question is about how the system works rather than about a change to it, the procedure answering it **shall** read what the project wrote about itself in its own words — its terms, its purpose and its overview — before it reads any requirement or any code.

**Rationale.** Every procedure that reads the specification starts from something the reader already has — a change, a file, a behaviour about to be written down — and none of them starts from a question about how the system works.
An agent applying the accustomed move to a question of that kind is aimed away from the answer.
This was measured rather than supposed: an agent in the first project that installed this framework answered from a function signature, was corrected, and found afterwards that the answer had been in an 81-line glossary it never opened.
Its own account named the cause: the accustomed move applied to a task of another kind.

Nothing pointed it at that file, and nothing could.
Of the 214 requirements this specification then held, none mentioned the glossary or the overview.
Nothing the viewer offers leads to those documents: no terminal mode opens one, and the page it renders links the glossary rather than rendering it, which its own footer says.
The single sentence that says to read the vocabulary first sits in a table row of the standard, which a project that adopted rather than initialised does not have at all.

What the project wrote about itself, rather than three file names: the names are a convention the standard says so of, and a project may hold its introduction in one file or four.
Rather than every document that carries no requirements, which was the first wording and was wrong by a factor of fifteen — that set also holds the generated matrix, the register of open questions and the baseline log, 110 KB of it here and the matrix alone 187 KB in the first project that installed this framework.
A rule obliging that much reading before a question can be answered costs exactly what this one exists to save.
What the three have in common is the thing that matters: they are what a reader can open without already having a number, written in the words the project chose.

Before requirements and before code, because the vocabulary is what makes the next query work at all — a search over requirement text finds a word the reader guessed, and the whole failure above was a reader who guessed a word the project does not use.
