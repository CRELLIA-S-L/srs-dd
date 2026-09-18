# Functional requirements — bel

The grounds register: an optional subsystem recording what the requirements rest on.
Hypotheses about people, the bets that tie them to requirements, and the checker that reads both.
A project without `grounds/` has none of this and is unaffected by all of it.

### FR-GND-010 — The register is read and reported on

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh, tests/grounds-check.sh]
created: 2026-08-20
```

Where a project carries a grounds register, the grounds checker **shall** read every record in it.

**Rationale.** This is the entry the rest of the subsystem hangs from: exit codes describe this run, the dashboard is what this run produces, and the constraint on where the tool may write is a constraint on this run.
Stating it separately keeps those from each having to restate what they are about.

Scoped to a project that carries the register, because the layer is optional in the way `--ci` is optional: a target that declined it has no `grounds/` directory, and nothing about its checker, its gate or its skills changes.
The presence of the register is the switch — not a flag recorded somewhere that can disagree with what is on disk.

Reading is separated from judging on purpose.
What counts as an error, a warning or a silence is the business of the rules, each with its own requirement and its own name; this one says only that the records are read and that the run says something about them.

### FR-GND-020 — Well-formed and unique identifiers

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

If a register identifier is repeated or does not match `<KIND>-<NNN>` with a kind the register's standard defines, the grounds checker **shall** report it as an error naming both occurrences.

**Rationale.** A duplicate is the quiet failure: one entry shadows the other, the reader sees a record where they expect one, and the bet that names the number points at whichever the parser reached last.
Naming both occurrences is what makes it a report somebody can act on rather than a complaint.

An error and not a rule with a severity, because a project that silenced this would be running on a register whose entries cannot be resolved by number — and every citation in a decision, a commit or a bet is by number.

### FR-GND-030 — A missing required key is named as missing

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a record omits a key the format requires, the grounds checker **shall** report that key as missing rather than as holding a bad value.

**Rationale.** The same distinction `FR-CHK-170` draws, and it matters more here: a hypothesis without `refuted_if` is not a hypothesis with an empty threshold, it is a claim nobody agreed how to kill.
Told the value is bad, an author goes looking at what they wrote; told the key is absent, they write it.

### FR-GND-040 — A record names a requirement that exists

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-GND-020]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a record names a requirement absent from the requirement model, the grounds checker **shall** report it as an error naming the record and the requirement.

**Rationale.** The register points into a model it does not own, and a dangling name is the way that pointer rots.
Left unreported it is worse than useless: the reduction skips what it cannot resolve, so a requirement whose ground has silently vanished reads as one with no ground claimed — which is the state the orphan counter is supposed to mean something about.

An error rather than a warning because the cause is never legitimate.
A requirement that was cancelled still exists and is `FR-GND-050`; a name that resolves to nothing is a typo or a rename nobody carried through.

Two kinds of record name a requirement and both are covered by one obligation, because the failure is one thing: a pointer into a model this register does not own.
A declaration is the quieter half — it says a requirement rests on nothing, and where the requirement does not exist it says that about nothing at all, while looking from the outside exactly like the honest declaration the whole layer is built to encourage.

### FR-GND-050 — A bet on a cancelled requirement is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-GND-020]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

When a bet names a requirement that has been cancelled, the grounds checker **shall** report it as a warning naming both.

**Rationale.** Cancelling a requirement leaves every bet on it standing, and what those bets now claim is that something rests on ground nobody will build.
`FR-CHK-190` is in the same position for requirements resting on a withdrawn one, and takes the same view: a warning, because this is the aftermath of a legitimate act and the resolution is a decision — retire the bet, or move it to whatever replaced the requirement.

### FR-GND-060 — A hypothesis past its term is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a hypothesis's term has run out, the grounds checker **shall** report it as a warning naming the hypothesis.

**Rationale.** The term is the whole point of recording one: a measurement taken two years ago is not evidence about today, and without a term nothing ever asks.
Reporting is all this does — the record is left exactly as it was, because expiry is not a verdict and a tool that moved the status would be answering a question only a measurement can answer.
What forbids the tool to touch it is `CON-GND-030`.

### FR-GND-070 — The weakest necessary hypothesis decides

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-GND-020]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The grounds checker **shall** take the hypothesis that decides a requirement to be the weakest of those its bets require and the strongest of those they offer as alternatives.

**Rationale.** Confidence is a weakest-link property: a requirement is no better supported than the shakiest thing it cannot do without.
Where the hypotheses are alternatives the reading inverts — any one of them carries it, so the strongest decides.
Collapsing the two into one rule produces a number wrong in the optimistic direction, which is the direction that gets nobody's attention.

One act over two cases rather than two requirements, in the reading `specs/README.md` gives for a rule that covers the cases it names: the obligation is the reduction, and half of it computed is not half the obligation met.

Which hypothesis decides, rather than what is read off it.
The status is what this is reduced over first, because that is what the debt reading in `FR-GND-130` needs; a grade reduces the same way and along the same edges once there is one.
Saying it this way keeps one rule where there would otherwise be two that must agree.

Across several bets on one requirement the weakest wins again, which is why `FR-GND-080` reports the case where that was not intended.

### FR-GND-080 — Two bets on one requirement are reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-GND-020]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where more than one bet names the same requirement, the grounds checker **shall** report it as a warning naming them.

**Rationale.** Two bets on one requirement are how two independent sets of alternatives are expressed, and they are also how a duplicate arrives when an author does not notice the existing one.
The two are indistinguishable in the file and not in the arithmetic: deliberate, the grade is the weaker of the two records; accidental, a maximum quietly became a minimum.
This is the only silent failure the record encoding introduces (ADR-0016), and a warning is what turns it loud without forbidding the legitimate case.

### FR-GND-090 — A declared unclaimed requirement carries a reason

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-GND-030]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a requirement is declared as resting on no hypothesis, the grounds checker **shall** report a declaration without a reason as an error.

**Rationale.** `INV-GND-030` forbids demanding a bet, which leaves the question of what an author does with a requirement that honestly has none.
The answer is a declaration, and what keeps it honest is that it costs a sentence: a reason somebody wrote is a reason somebody can disagree with, and a blank one is a silencer wearing the shape of a record.

The asymmetry is the point and is worth stating so it is not optimised away.
Inventing a bet means inventing a falsifiable claim with an owner and a term that somebody will ask about in a quarter.
Declaring costs one line.
Nobody made declaring cheap; what was made expensive is lying.

### FR-GND-100 — A declaration that stopped being true is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-GND-030]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a requirement declared as resting on no hypothesis is named by a bet that stakes it on one, the grounds checker **shall** report the declaration as superfluous.

**Rationale.** An exemption nobody retires is an exemption that outlives its reason, and the register would fill with declarations describing a state that ended months ago.
The pattern is borrowed from linters, where a suppression must carry a description and the tool removes it once the rule it suppressed stops firing: the machine retires the exemption, not the person who has forgotten it exists.

What retires it is a bet that stakes the requirement on something.
Both lists of a bet are optional, so a record naming neither is legal and stands the requirement on nothing — and a declaration retired by one would be replaced by a record saying less than it did.

### FR-GND-110 — What a hypothesis rule costs is the project's to set

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The grounds checker **shall** let a project lower a rule to a report or silence it altogether in the register's configuration.

**Rationale.** The same lever `FR-CHK-160` gives the specification checker, and the layer needs it more, not less.
A project adopting the register mid-flight has requirements older than any hypothesis anyone will write for them, and a rule firing on every one of them is a wall rather than a queue.

Only the project-wide lever, not a per-record one.
The exemption a requirement carries in its own block exists because a requirement can be a legitimate exception to a rule about requirements; here the analogous case — a requirement resting on nothing — already has its own affordance in `FR-GND-090`, and a second way to silence it would be a way to skip the reason.

### FR-GND-120 — Strict mode

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh, tests/grounds-check.sh]
created: 2026-08-20
```

Where `--strict` is given, the grounds checker **shall** exit non-zero when warnings were reported even if no error was.

**Rationale.** Most of what this checker says is a warning by design — an expired hypothesis, a bet on a cancelled requirement, a superfluous declaration are all conditions somebody must decide about rather than defects.
A gate that only failed on errors would therefore never fail, and the register would drift with nothing to notice.

Stated separately from `IF-GND-020` for the reason the specification checker keeps `FR-CHK-120` beside `IF-CI-020`: one says what the run does, the other publishes the numbers a caller binds to.

### FR-GND-130 — The debt is on the dashboard

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-GND-020]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The dashboard **shall** state what proportion of the requirements carrying a bet rest on hypotheses that are `refuted`, `expired` or `assumed`.

**Rationale.** This is the reading the subsystem exists to produce.
Everything else it records — the terms, the thresholds, the grades — is machinery for computing one number that nobody currently has: how much of what is built stands on ground its owners no longer believe in.

The three states are one reading rather than three, because what the number answers is a single question.
Splitting them would invite the answer that matters least: `assumed` alone is a measure of how little has been measured, and `refuted` alone flatters a project that never checks anything.

Scoped to the requirements carrying a bet.
Those carrying none are a different reading with a different meaning, and folding them in here would let a project improve this number by writing fewer bets.

### FR-GND-140 — A verdict follows from the threshold

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a measurement's verdict does not follow from comparing it against the hypothesis's threshold, the grounds checker **shall** report it as an error naming both.

**Rationale.** The threshold is declared before the measurement precisely so that the verdict stops being a matter of opinion.
A verdict left to disagree with it is worse than a missing one: it reads as a judgement somebody made rather than an arithmetic nobody did.

What "follow from" means is not a bare comparison, and this is the one place it would be easy to get backwards.
A value sitting below its threshold by less than the measurement's own error has not refuted anything, and a row saying so is right.
How much error a measurement carries depends on what kind of quantity it is, which is FR-GND-150's business and deliberately not this one's.

Two halves need no criterion at all and are what this rule can always say.
A row claiming refutation while its value sits on the safe side of its own threshold contradicts itself whatever the error is.
So does one claiming refutation on a sample smaller than the threshold's own `at n >=`, because that gate is part of the sentence the author wrote.
A verdict that is neither `supported` nor `refuted` follows from no comparison at all and is the same finding.

### FR-GND-150 — The criterion follows the kind of quantity

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-140]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The grounds checker **shall** take the reconfirmation criterion from the kind of quantity the threshold names, and report a hypothesis of class I whose kind it supports no criterion for.

**Rationale.** "Reconfirm automatically" has no content until the quantity is typed, because what a measurement's error is depends entirely on what was measured.
A proportion's follows from the proportion and its denominator; a count's follows from the count itself.
A mean's does not follow from anything the row carries — it needs the spread of the underlying values, and the row records the mean and the sample size and nothing else.
Naming the kind in the threshold is what makes the criterion choosable rather than assumed.

A kind with no criterion closes class I rather than falling back to a naive comparison, because automatic reconfirmation is the whole of what class I means.
Left to fall back, the naive comparison would refute on the first dip:
a threshold of `proportion < 0.25 at n >= 200` and a measurement of `0.24` on exactly 200 is forty-eight people where fifty were wanted, and burying a hypothesis that requirements and code already stand on because two people answered otherwise is a coin toss wearing an arithmetic's clothes.

### FR-GND-160 — A class III verdict names who made it

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-140]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a verdict on a class III measurement does not name who made it, the grounds checker **shall** report it.

**Rationale.** Forty thousand in a cohort and a dozen conversations both end in the word `supported`, and only for the second is the word somebody's reading.
A reading with no reader named is not evidence anyone can weigh, and it is also the hook `FR-GND-210` needs: an author whose verdicts keep being reversed cannot be noticed if the verdicts are anonymous.

Reported and not corrected.
Which status is right is a question only whoever took the measurement can answer, and `CON-GND-030` forbids the tool to touch the record in any case.

### FR-GND-170 — A grade permits only the actions declared for it

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-110]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a hypothesis declares an action its grade does not permit in the register's configuration, the grounds checker **shall** report it.

**Rationale.** A grade with nothing attached is a label.
What makes it do work is the binding: the configuration says which actions each grade permits, and a hypothesis acting beyond its evidence is reported rather than left to the reader to notice (ADR-0017).

The map lives in the configuration and not in the format because what a weakly supported hypothesis may be used for is a matter of appetite.
A project betting a quarter on low certainty and one betting a release are both coherent; neither is the framework's to decide.

### FR-GND-180 — A declined hypothesis carries a reason and a date

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a hypothesis is declined without a reason or without the date the refusal was made, the grounds checker **shall** report it as an error.

**Rationale.** A refusal is recorded so that the same question returning in six months is answered from the record instead of argued again.
Without the reason it answers nothing; without the date nobody can tell whether the answer is still the current one or predates everything that has changed since.

### FR-GND-190 — The threshold was not moved after the first measurement

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-140]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a hypothesis's threshold was last changed after its earliest recorded measurement, the grounds checker **shall** report it.

**Rationale.** A threshold named after the result turns every outcome into an encouraging one, which is the failure the declared-in-advance rule exists to prevent — and a rule nothing checks is a rule that decays into a habit.

Read from the history of the file rather than from the file, which is the only place the ordering exists.
Where that history cannot be read — a shallow clone, a squashed import — the run says so rather than passing in silence, the position `FR-VIEW-090` takes for baselines it cannot reach.

### FR-GND-200 — Evidence is only ever added

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-GND-030]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a measurement recorded earlier is absent from a hypothesis or differs from what was recorded, the grounds checker **shall** report it.

**Rationale.** The older measurement is what the newer one is a change from.
Deleting it deletes the change, and a hypothesis whose evidence shows only the result that suited its author is a hypothesis with no history at all.

Distinct from `CON-GND-030`, which forbids the tool to modify a record.
That one binds the machinery; this one catches a person, and neither covers the other.
Same reliance on history, same answer where the history is missing.

### FR-GND-210 — How often an author's verdicts were reversed

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-160]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The dashboard **shall** state, for each author of a verdict, how many of their verdicts a later measurement reversed.

**Rationale.** Weighting expert judgement by measured accuracy needs calibration questions with known answers and a programme to run them, which is an organizational undertaking and not a file format.
This is its affordable half: it needs nothing the register does not already hold, and it answers the question that matters most about a class III verdict — whether this person has been right before.

### FR-GND-220 — The weight of an unclaimed requirement

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-GND-030]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The dashboard **shall** state, for each requirement that has not been cancelled and rests on no hypothesis, how much of the system rests on that requirement.

**Rationale.** An unclaimed requirement that twelve others depend on and that names eight files is a different reading from a leaf naming one, and treating them alike is how the signal drowns in its own volume.

No field is asked of anyone.
The weight of a missing hypothesis cannot be recorded, because there is no hypothesis to record it on; what is available is the requirement's own weight, and it is available already — what depends on it and how much code it names.

Cancelled requirements are outside the reading, in the wording the checker and the viewer already use (`FR-CHK-210`, `FR-VIEW-040`).
One that was withdrawn rests on no hypothesis and never will, and nothing of the system rests on it;
left in, it sits on this list forever and the same run describes the specification two ways.
Its links do not carry weight either, for the reason `FR-CHK-190` gives — but only here, where the weight is computed.
The viewer still resolves every incoming link, because settling a withdrawal is exactly the case that needs them whole.

### FR-GND-230 — New unclaimed requirements, and where they cluster

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-220]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The dashboard **shall** state how many requirements that have not been cancelled came to rest on no hypothesis within each period of the length the register's configuration names, and in which areas.

**Rationale.** One unclaimed requirement is noise and is meant to be.
Five in a quarter, four of them in one area, is the product having become something nobody said out loud — and that reading is unavailable from any single one of them.

Whether they point in one direction is a question about meaning and stays with the reader.
The area is the part a machine can see, and it is a good enough proxy to make the question worth asking.

The length of the period is the project's and not this format's, for the reason the map from grade to permitted action is: a product shipping weekly and one shipping twice a year do not have the same unit of "lately", and a quarter that gives the first of them four readings a year gives them too late.
It is named in the register's configuration, and the dashboard says which length it used, so that a reader never has to guess what a row counts.

Periods are calendar ones — whole months, quarters or years — and never a window measured back from today.
This file is committed and compared against a fresh run, so a boundary that moved every night would fail the gate every morning while saying nothing new.

Cancelled requirements are outside the count, as they are outside `FR-GND-220`.
The reading is the product having become something nobody said out loud; a withdrawal is the case where somebody did, and counting it inflates the one signal this exists to produce.

### FR-GND-240 — The age of the core, by class of confirmation

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-GND-020]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The dashboard **shall** state how old the confirmations in the core are, separately for each class of confirmation.

**Rationale.** A single figure lets a cheap class refresh often enough to hide an expensive one that has not been checked in a year — and the expensive classes are the ones carrying the claims about whether the product should exist at all.
Separated, the reading says not only how fresh the core is but which part of it is fresh, which is the difference between reassurance and information.

### FR-GND-250 — What each frame has refused

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-GND-020]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The dashboard **shall** state, for each frame, what it has refused and when.

**Rationale.** A frame is a rule about what the product will not do whatever the evidence, and its whole value is in the refusals.
One that has refused nothing in a year is either a slogan or a rule applied at the wrong moment, and neither is visible without the journal.

### FR-GND-260 — How many ideologies the core carries

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-GND-020]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The dashboard **shall** state how many ideologies the core carries.

**Rationale.** One or two is the intended state.
Grown to five, what the register describes is a suite of products sharing a repository, and the counting is the cheapest way to notice a drift nobody decided on.

### FR-GND-270 — History that cannot be read is said to be unread

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-190]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a rule needs the register's history and that history cannot be read, the grounds checker **shall** report that it could not be read rather than pass the rule.

**Rationale.** Two rules read history rather than files — the threshold's ordering and the evidence that must only grow — and both meet the same wall in a shallow clone, a squashed import, or a checkout that is not a repository at all.

Two and not three: the count of an author's reversed verdicts looks like a history rule and is not one.
A verdict and the measurement that reversed it are two rows of the same evidence table, ordered by their own dates, so that reading needs nothing but the file in front of it — which is what its own rationale says, and what makes it the affordable half of a method whose expensive half needs a programme.

Passing in silence there is the worst of the three available answers.
It turns a rule into an assertion that cannot fail, which is the shape `FR-CI-080` exists to forbid, and it does so exactly where somebody would most want to know: a history nobody can read is also a history nobody can audit.
Failing outright is the other extreme and would make the register unusable in every environment that clones shallowly, which includes most default pipelines.

Saying so is the answer `FR-VIEW-090` already gives for baselines it cannot reach, and the reason carries over: a reader who is told nothing assumes the check ran.

### FR-GND-280 — The register is a choice at install

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-20
```

A fresh install and an adoption **shall** offer the grounds register as a choice, installing nothing of it where it is declined.

**Rationale.** The layer answers a question many projects do not have.
Its own scope note excludes a project whose basis is externally fixed and stable — avionics, a protocol implementation, regulatory compliance — and installing it there produces records nobody will ever measure.

Declined, it leaves nothing: no directory, no tool, no skill, no configuration key.
A target that said no is byte-for-byte a target that was never asked, which is what makes the choice cheap to make and cheap to reverse.

### FR-GND-290 — The register is added deliberately, never silently

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-280]
refines: []
conflicts_with: []
code: [tools/srs_init.py, tools/srs_upgrade.py]
tests: [tests/installer-smoke.sh, tests/upgrade-smoke.sh]
created: 2026-08-20
```

An upgrade **shall** refresh the grounds register's tooling only where the register is already present, adding it to a project that has none only when asked.

**Rationale.** Upgrades refresh the tooling and the skills without a flag, and along that path a new subsystem would arrive at every project that merely updated.
The ones it would surprise are exactly the ones the scope note excludes: they did not decline the register, they never heard of it.

Asking has to be possible with the command a project actually has.
`tools/srs_upgrade.py` is the one command a target runs to pick up a new framework version, and a register that could only be added by reaching for the framework's own installer would be a register most projects never add.

Presence is read from the register itself rather than from a setting, so there is nothing to disagree with what is on disk.
The same reading the installer already makes when it decides between a fresh install and an upgrade.

### FR-GND-300 — A fresh register is one its own checker accepts

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-280]
refines: []
conflicts_with: []
code: [tools/srs_init.py, skeleton/grounds]
tests: [tests/installer-smoke.sh]
created: 2026-08-20
```

Where the grounds register is installed, the target's own grounds checker **shall** pass strictly on what was installed.

**Rationale.** The same promise `FR-INIT-020` makes for the specification: a project's first run is green, so the first red one means something the project did.
A skeleton that arrives already warning teaches its reader that the warnings are furniture.

Strictly, and not merely without errors, because almost everything this checker says is a warning by design — a skeleton that passes only the loose run would be hiding its own state from the gate the project is about to switch on.

### FR-GND-310 — The hook says which bets the commit touches

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-010]
refines: []
conflicts_with: []
code: [ci/pre-commit, tools/srs_grounds.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-20
```

Where a project carries a grounds register, the installed hook **shall** report, without failing the commit, the bets on the requirements whose files the commit changes.

**Rationale.** The register's promise is that a stale hypothesis becomes visible where the code is, and a dashboard nobody is obliged to open does not keep it.
The hook is the one place the framework already reaches everyone who opted into the gate, and the moment it reaches them is the moment they are touching the code in question.

Scoped to the commit, because a refuted hypothesis elsewhere in the project is not this commit's business and a report that always speaks is a report nobody reads.
Never failing, because a refuted hypothesis is not the committer's fault and may be precisely what they are in the middle of repairing.

What may not fail is this report, not the hook.
The hook already fails on a stale matrix, and the shipped template invites a project to add `--strict` and fail on warnings besides; nothing here takes either away.

### FR-GND-320 — The register procedure travels with the project

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-280]
refines: []
conflicts_with: []
code: [tools/srs_init.py, .claude/skills/srs-bet/SKILL.md]
tests: [tests/installer-smoke.sh]
created: 2026-08-20
```

The skills installed into a project **shall** include the grounds procedure where the register is installed.

**Rationale.** A project's hypotheses are its own, and nothing about writing one is about this repository — the reading `FR-SKILL-080` gives for the baseline procedure, and the opposite of the one `FR-SKILL-070` gives for the release procedure, which stays here because a target releases nothing of ours.

Only where the register is installed.
A skill for a subsystem a project declined is a file explaining something it does not have.

### FR-GND-330 — Whoever writes a hypothesis judges what no checker reaches

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [.claude/skills/srs-bet/SKILL.md]
tests: []
created: 2026-08-20
```

When a hypothesis is written or reworded, the procedure doing so **shall** judge it against the qualities no checker reaches — a bounded population, an observable action rather than an attitude, a magnitude, and no solution carried inside the need — and say what it found before the text is recorded.

**Rationale.** `FR-SKILL-120` makes this obligation for requirement statements and gives the reason no word list can do it.
The qualities differ here, and two of them are where hypotheses go wrong.

Attitudes do not measure.
"Studios need time roll-up" cannot be false; "at least a quarter of those who reach the report take a paid plan within a fortnight" can.
And the commoner mistake runs the other way: a solution smuggled into the need.
"We need a comparison screen" is already an answer, and a hypothesis written that way tests the answer instead of the need — which is how a project ends up measuring whether its idea was popular rather than whether the problem was real.

Verified by inspection for the reason every procedure requirement is: no suite runs a dialog, and one asserting the wording would be a copy of the file rather than a check on it.

### FR-GND-340 — The class is checked against the measurement

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-GND-330]
refines: []
conflicts_with: []
code: [.claude/skills/srs-bet/SKILL.md]
tests: []
created: 2026-08-20
```

When a hypothesis's class is chosen, the procedure doing so **shall** check that the declared measurement can produce a number the threshold compares against, and say where it cannot.

**Rationale.** `FR-SKILL-140` puts the same question to a requirement's verification method at the one moment it costs nothing — while the statement and the method are on the table together.
Left to surface later, it surfaces when somebody has to take a measurement that cannot be taken.

Class I is where this bites.
It claims the measurement is passive and automatic, and an author who declares it over a quantity nobody instruments has written a hypothesis that will sit unconfirmed until its term runs out, with nothing saying why.

### FR-GND-350 — A refutation opens a decommissioning, not a deletion

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-GND-140]
refines: []
conflicts_with: []
code: [.claude/skills/srs-bet/SKILL.md]
tests: []
created: 2026-08-20
```

When a hypothesis is refuted, the procedure doing so **shall** settle each requirement that rested on it with the maintainer, taking removal as the default.

**Rationale.** The requirements do not evaporate: they are shipped, people use them, their data is in the schema.
What refutation takes away is the ground, not the code, and the difference between those two is a project with a date rather than a deletion.

Removal is the default because the opposite default is how dead features survive for years.
Where somebody still uses it, that is not a reason to keep it — it is a new fact: something other than the refuted hypothesis is holding it up.
Naming that hypothesis is the price of keeping the code, and where nobody will name it the code goes.

Which requirements rested on it is read from the bets, and the shape of the conversation is the one `FR-SKILL-150` prescribes for a withdrawal: show what stands on it, settle each dependant, do not cascade silently.

### FR-GND-360 — Admission to the core is its own act

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-GND-180]
refines: []
conflicts_with: []
code: [.claude/skills/srs-bet/SKILL.md]
tests: []
created: 2026-08-20
```

When a hypothesis is confirmed, the procedure doing so **shall** put its admission to the core to the maintainer as a decision of its own, and record a refusal with its reason.

**Rationale.** Confirmation answers whether something is true.
Admission answers whether being true makes it ours, and only the first has a measurement.
A register that admits whatever confirms has a core that cannot decline anything, which is the one thing a core is for.

The outcomes are absorb, spin off as a second product, or refuse.
The third is the one that needs writing down: without it nobody can tell a hypothesis nobody tested from one tested, confirmed and turned down, and the same question returns every six months to be argued from scratch.

### FR-GND-370 — The dashboard is compared, not trusted

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-GND-020]
refines: []
conflicts_with: []
code: [.github/workflows/srs.yml, ci/github-workflow.yml, ci/gitlab-ci.yml]
tests: [tests/grounds-check.sh]
created: 2026-08-20
```

Where a project carries a grounds register, its gate **shall** regenerate the dashboard and fail when the committed copy differs from it.

**Rationale.** `CON-GND-020` says the dashboard is generated and never edited by hand; this is what makes that true rather than hoped for.
Generated output that nothing compares is output somebody will eventually edit, and the readings it carries — how much of the system stands on refuted ground, how old the confirmations are — are exactly the numbers worth editing.

Both gates do it: this repository's own pipeline through `tests/grounds-check.sh`, and a target's through the step the shipped templates carry, which is inert in a project that keeps no register.
An upgrade does not deliver that step on its own — the CI template is a file a project may have edited, and `FR-INIT-060` refreshes it only with `--force`.

`FR-CI-010` states the same obligation for the traceability matrix and lives in the area about gates.
This one lives here instead, because what it is about is the register's own integrity; the gate is where it happens, not what it concerns.

### FR-GND-380 — An instrument outlives what it measures

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-GND-350]
refines: []
conflicts_with: []
code: [.claude/skills/srs-bet/SKILL.md]
tests: []
created: 2026-08-20
```

Where a bet declares its requirement to be an instrument, the procedure settling a refutation **shall** leave that requirement out of the removal it proposes.

**Rationale.** `FR-GND-350` takes removal as the default, and that default is right for the feature and wrong for the thing that measured it.
The screen existed because somebody believed the hypothesis; the event counting who opened the screen existed to find out whether they were right.
Refutation is that event answering its question, and answering it is not a reason to delete the answering.

What the instrument is for is the bet after this one.
A funnel and an attribution are what the successor hypothesis will be measured with, and a project that removes them with every refutation is a project that has to rebuild its measuring before it can ask anything again — which is how measuring quietly stops happening.

Declared on the bet and not on the requirement, for the reason the join itself is: nothing in this layer writes into a requirement file.
It is also the more accurate place.
Being an instrument is a fact about a pair — the same requirement can measure one hypothesis and rest on another — and the bet is the record that names exactly that pair.

Verified by inspection for the reason every procedure requirement here is: no suite runs a dialog, and one asserting the wording would be a copy of the procedure rather than a check on it.

### FR-GND-390 — A value outside the format's vocabulary is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a record carries a value the format does not define for its key, the grounds checker **shall** report it as an error naming the record, the key and the value.

**Rationale.** Every reading this register produces is a function of a handful of constrained values, and a value nothing recognises has to be treated as something.
Both available answers are wrong, and which one is worse depends only on the key.

For `status` it is the reduction: rank an unrecognised one weakest and a typo reads as a refutation, rank it strongest and it hides in the core.
For `class` there is no ranking to get wrong and the failure is quieter — the core is reported by class, so a supported hypothesis whose class is not one the format defines appears in no row at all, and the core reads smaller than it is while the register plainly holds it.
For a date it is louder still: a term that cannot be read is a term that never runs out.

An error rather than a tunable finding, and for the reason a malformed identifier is one: the alternative to failing is a number that is confidently wrong, and a project cannot usefully choose to be told less about that.

Separate from `FR-GND-030`, which is about a key that is absent.
This is about a key that is present and says something the format does not define — the distinction that requirement's own statement draws.

### FR-GND-400 — A bet names a hypothesis that exists

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-040]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

Where a bet names a hypothesis absent from the register, the grounds checker **shall** report it as an error naming the bet and the hypothesis.

**Rationale.** `FR-GND-040` guards the requirement end of a bet and nothing guarded the other one.
The two ends fail differently and both fail silently:
a missing requirement means the bet points outside the register, a missing hypothesis means the bet points at nothing inside it, and in the second case the reduction quietly computes over a shorter list and reports a requirement as better supported than it is.

Identifiers are never reused, so a name that resolves to nothing is a mistyped reference or a record somebody deleted rather than retired — and the second is what `INV-GND-010` exists to prevent.

### FR-GND-410 — A table row carries the columns its heading declares

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-21
```

Where a table row under a record has more or fewer cells than its heading declares, the grounds checker **shall** report it as an error naming the record and the row.

**Rationale.** A record's tables are read by position within the row: the evidence table's fourth cell is the verdict and its fifth is who gave it, and a row missing one shifts every cell after it or drops it altogether.
What follows is not a parse failure but a quieter thing — the row is skipped, and a reading computed over the rest comes out confidently wrong.
An author whose verdict fell out of a row stops appearing in the count of whose verdicts were reversed, which is the one reading that exists to say something about people.

An error rather than a tunable finding, for the reason a status outside the vocabulary is one: the alternative to failing is a number nobody can tell is wrong.

Separate from `FR-GND-390`, which is about the value under a key.
A table is not a key and a row is not a value, and widening that requirement a third time would leave it saying nothing in particular about either.

Rows are not checked against a fixed shape, only against their own heading.
The format identifies a table by its heading rather than by its position, so the heading is the only thing that knows how wide its rows are — and a table this register has not heard of is checked exactly as well as the three it has.

### FR-GND-420 — A hypothesis something rests on is not `untested`

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-070]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-21
```

Where a bet names a hypothesis whose status is `untested`, the grounds checker **shall** report it, naming the bet and the hypothesis.

**Rationale.** The format defines `untested` as written down, nothing measured, and nobody relying on it yet.
A bet is somebody relying on it, so the two say opposite things about the same record, and one of them is wrong by construction.
The honest status is `assumed` — taken on faith and being built on, which the format calls an honest state rather than a defect.

What the mismatch hides is a number.
The debt counts what rests on hypotheses that are `refuted`, `expired` or `assumed`, and `untested` is in none of those, so a record left in the wrong status makes the debt read smaller than it is.
That is the direction a mislabelling always goes, and the only one worth a rule.

A warning a project can lower rather than an error, because nothing here is broken: the register is describing itself inaccurately, and the repair is one word.

### FR-GND-430 — Built on and never measured

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-060]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-21
```

Where a hypothesis named by a bet has passed its term with no measurement recorded at all, the grounds checker **shall** report it, naming the hypothesis and the bets that stand on it.

**Rationale.** `FR-GND-060` reports a term that has run out and cannot tell the two cases apart: measured once and long ago, or never measured.
The second is a different fact about the project — something was built on a claim, the time to check it was set by whoever wrote the claim, and the time passed with nobody checking.

Separate from the expiry rule rather than folded into it, because the two are answered differently.
A stale measurement is answered by measuring again; nothing to measure again is answered by asking whether the measurement was ever possible, which is the question the confirmation class was supposed to have settled.

Before the term runs out this is not a finding.
Building on an unmeasured claim is what `assumed` is for, and the term is the moment the project itself chose as the one where that stops being enough.

Where this speaks, `FR-GND-060` does not: one record earns one line, and this one says everything that one would plus who is standing on it.
The stepping aside is conditional on this rule actually being heard — a project that lowered it to nothing has not lowered the other, and a record left unreported by both would be the severity lever silencing a rule nobody silenced.

### FR-GND-440 — What a requirement is staked on is read back first

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-GND-330]
refines: []
conflicts_with: []
code: [.claude/skills/srs-bet/SKILL.md]
tests: []
created: 2026-08-21
```

When a requirement is staked on a hypothesis, the procedure doing so **shall** read the hypothesis back against its own numbers — the magnitude its statement claims, the threshold that would refute it, and the sample that threshold names — and say what it found before the bet is recorded.

**Rationale.** No rule can know the intended number.
A hypothesis whose threshold lost a decimal point is well-formed, passes every check this layer has, and is wrong in the one way the format cannot see: it is consistent with itself.
What catches it is somebody reading "at least three studios in ten" beside `proportion < 0.025 at n >= 200` and noticing that those are two orders of magnitude apart — a judgement rather than a pattern, and the readers of this specification are agents, which is what makes it worth asking for.

Here rather than where the hypothesis is written, because at writing the number has nothing to be checked against yet.
Staking is the moment the intent to build appears, and it is the last cheap one: after it come requirements, and after those, code.
`FR-GND-330` asks its own four questions of a statement being written; this asks a different one of a statement about to be built on, which is why it is a second obligation and not a longer first.

Verified by inspection for the reason every procedure requirement here is:
no suite runs a dialog, and one asserting the wording would be a copy of the procedure rather than a check on it.

### FR-GND-450 — A table the format names carries the heading it declares

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-410]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-21
```

Where a record carries a table the format names and its heading is not the columns the format declares for that table, the grounds checker **shall** report it as an error naming the record and the heading it found.

**Rationale.** A table is found by the one column only it has, and read by position from there: the evidence table's fourth cell is the verdict and its fifth is who gave it.
Both halves are needed and only the first was checked.
A table headed `date | verdict | by` is found — it has `verdict` — and then read as though the verdict were in the fourth cell of a three-cell row, which it is not.
Nothing errors: the rows are simply skipped, and every reading over them comes out empty while the register plainly holds the measurements.

That is the failure this layer is least able to afford, because it is indistinguishable from the honest answer.
A dashboard saying no verdicts are recorded is what a register with no verdicts looks like.

Tables the format does not name are not touched.
A record may carry a table of its own for a reader's benefit, and a rule that demanded a shape for every table would be a rule about markdown rather than about this register.

Separate from `FR-GND-410`, which checks a row against the heading above it.
That one keeps a table internally consistent; this one keeps it the table the format thinks it is, and a table can pass either while failing the other.

### FR-GND-460 — A refusal is recorded only where there was one

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-180]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-21
```

Where a record carries a `declined` value and its status is not `declined`, the grounds checker **shall** report it, naming the record.

**Rationale.** The record then says two incompatible things about itself: a line giving the date and the reason it was refused, and a status saying it holds.
A reader has no way to tell which is current, and the register exists to be read rather than interpreted.

The way it happens is ordinary and worth naming, because it is the sequence somebody will actually walk: a hypothesis is refused, a later measurement changes the picture, the status moves to `supported`, and the refusal stays behind.
Nothing about that sequence is a mistake except the leftover line.

A warning a project can lower rather than an error, because nothing is broken and the repair is a line either way — remove it, or move the status back.
Which of the two is right only the author knows, and `CON-GND-030` forbids the tool to choose.

### FR-GND-470 — An action says what grade it rests on

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-170]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-21
```

Where a record declares an action and no grade, and the register's configuration maps any grade to permitted actions, the grounds checker **shall** report it, naming the record and the action.

**Rationale.** `FR-GND-170` catches an action beyond its grade and cannot see the case that matters more: an action with no grade at all.
The map is consulted by grade, so a record with none is a decision taken without saying what it rests on — which is not a stricter version of acting beyond your evidence but a quieter one, because nothing is there to compare against.

Conditioned on a map being configured, because a project without one has expressed no appetite and there is nothing for the omission to be measured against.
Where the map exists, somebody sat down and decided what may be done at each grade, and an action that opts out of that decision is the one thing the map cannot otherwise notice.

### FR-GND-480 — The period is asked for at install, never assumed

```yaml
status: implemented
verification: T
derives_from: [FR-GND-230]
depends_on: [FR-GND-280]
refines: []
conflicts_with: []
code: [tools/srs_init.py, tools/srs_upgrade.py]
tests: [tests/installer-smoke.sh, tests/upgrade-smoke.sh, tests/adopt-smoke.sh]
created: 2026-08-21
```

Where the grounds register is taken, an install **shall** settle what length of period the dashboard counts arrivals by, recording the answer in the register's configuration rather than assuming one.

**Rationale.** The dashboard's one calendar unit is the project's, and the only moment somebody is already answering questions about their project is the install.
Asked later, it is a key nobody knows exists in a file nobody has opened; asked here, it costs one line of a conversation already happening.

Recorded rather than copied, for the reason `specs/srs-config.json` is written rather than copied: a file that carries an answer cannot be a skeleton file, and a skeleton file copied over an answer would be an upgrade silently resetting it.
The configuration is written through the installer's own writer, so the dry run reports it without a special case.

A default remains, because an install that has to stop and ask is an install somebody abandons.
The default is not the point; being able to say otherwise before the first dashboard is generated is.

### FR-GND-490 — How much error is allowed is the project's

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-150]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-21
```

The grounds checker **shall** decide how much error a measurement is allowed at the confidence the register's configuration names.

**Rationale.** A criterion that allows for error has to be told how much, and there is no answer that is right everywhere.
A team that would rather keep a dead hypothesis than bury a live one wants to be very sure before refuting; a team whose hypotheses are cheap to rewrite would rather hear the bad news early.
Both are defensible and neither is this format's business to pick.

Named levels rather than a free number, for the reason the threshold names four comparisons and no others: a confidence somebody typed as `0.973` is a number that came from nowhere and cannot be discussed, and the arithmetic behind an arbitrary level needs machinery this checker deliberately does not carry.

A default exists and is the conventional one, because a project that has not thought about this should still get a criterion rather than a refusal to run.

### FR-GND-500 — An agent names only hypotheses that already exist

```yaml
status: implemented
verification: I
derives_from: [INV-GND-030]
depends_on: [FR-GND-330]
refines: []
conflicts_with: []
code: [.claude/skills/srs-bet/SKILL.md, grounds/README.md]
tests: []
created: 2026-08-23
```

Where an agent works on the register, the procedure **shall** confine the hypotheses it may name to those already recorded, leaving a claim none of them carries to a declaration or to nothing.

**Rationale.** The protection INV-GND-030 rests on is not a rule but a price.
Declaring that a requirement stands on nothing is a line and a sentence.
Inventing a bet means inventing a hypothesis — a bounded population, a quantity, a threshold, a date and a named owner who will be asked about it next quarter — and for a person that bill is larger than the honest declaration, which is why the honest declaration gets written.

An agent is not sent that bill.
The same record costs it nothing, the plausible population and the round threshold arrive on demand, and the whole asymmetry the layer stands on is settled by whoever is cheapest to write with.
What comes out passes every check this layer has, because the checks are on the shape of a record and the invention is shaped correctly.

The owner field is where it is plainest.
`owner` names who answers for measuring the hypothesis, and an agent that fills it in has committed a person who was never asked.
That is not a defect of the field: no field can be written by somebody who will not be held to it and still mean what it says.

So the boundary is drawn where the economics stops working rather than where the format does.
An existing hypothesis was priced by whoever wrote it; a bet naming one adds no claim about the world.
A `U` declaration adds none either — it says the opposite.
Everything between the two is a person's act.

Verified by inspection, for the reason every procedure requirement in this area is: no suite runs a dialog, and one asserting the wording would be a copy of the file rather than a check on it.

### FR-GND-510 — Widening what may move the ideology is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-030]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-23
```

Where an ideology's admissible arguments gained a member since an earlier revision, the grounds checker **shall** report it, naming what was added.

**Rationale.** A rule that governs the conditions of its own revision can immunise itself, and the capture runs through widening: the ideology is persuaded by an admissible argument to admit one more kind of argument, the wider set admits arguments that widen it further, and two steps later revenue is back by a chain of correct moves.
Every known answer to that is the same one — some part of the rule is not revised by the procedure it governs — and the cheapest approximation a repository can offer is that widening is not free.

Reported rather than refused, and the difference is the whole design.
The concept prices narrowing cheap and widening expensive; a rule that refused would price widening at infinity, which is a different claim and one no project asked for.
A finding under `rules` costs a warning, and a warning is what `--strict` fails on, so a project that wants the price higher sets it and one that wants it lower does the same.

Narrowing is silent, and deliberately: the concept prices it cheap, so a rule reporting it would be charging for the move the asymmetry exists to make free.
The gap is elsewhere and it is worth naming, because a later reader who finds narrowing unwatched will be tempted to close it here.
Narrowing carried far enough is the concept's other failure — closure, the set narrowed until nothing can move the ideology at all — and the only answer to that is a minimum no procedure may amend, which `specs/91-open-issues.md` already records as something a repository can make loud and cannot prevent.
So this rule covers one of the two failures, and reporting narrowings would not cover the second; it would only make the first look covered twice.

Read from history for the reason FR-GND-190 is: the ordering exists nowhere else.
Where history cannot be read the run says so rather than passing.

### FR-GND-520 — A widening names the territory it opens

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-510]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-23
```

Where an ideology's admissible arguments gained a member in a revision whose amendment table gained no row naming a territory, the grounds checker **shall** report the widening as undisclosed.

**Rationale.** The criterion the concept gives for telling a revision from a capture is Lakatos's: a modification is progressive where it predicts something new, degenerating where it only accommodates the anomaly that prompted it.
Named in advance, the territory is a prediction somebody can go and check a quarter later; named afterwards it is whatever happened.

So the disclosure is what makes the criterion applicable at all, and it is the only half of it this rule reaches.
Whether anyone actually went to the named territory is the other half, and the register has no way to say it: a later record does not point at the territory that admitted it.
That is a format question and belongs to a decision, not to this requirement.

The row is required in the revision that widened, not merely somewhere in the table.
An amendment written later describes a set that had already changed, which is the accommodation the criterion is meant to catch.

### FR-GND-530 — A hypothesis is put against the frames before it is admitted

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [.claude/skills/srs-bet/SKILL.md]
tests: []
created: 2026-08-25
```

When a hypothesis is written, the procedure doing so **shall** put it against the frames the register holds and, where one refuses it, record the refusal in that frame's journal instead of admitting the hypothesis.

**Rationale.** A frame is what the product will not do whatever the evidence says, and the cheapest moment to refuse is before anything is built on the claim — after that, refusing means unwinding a bet, requirements and whatever was shipped against them.
That is why the concept this layer comes from puts frames at the first gate rather than at the last.

Until this, the layer recorded frames and never applied them.
Nothing connected a frame to a hypothesis or to a bet: `FR-GND-250` states what each frame has refused, and no procedure ever wrote a refusal into a journal, so the reading it exists to give — an empty journal for a year means a slogan rather than a frame — could not distinguish a frame nobody tested from a frame nobody has.
A register can hold a veto and let straight through the one thing the veto names.

It binds a person rather than the checker, and that is not a shortfall to be repaired later.
Whether a claim about the world falls under "we do not take regulatory surface we cannot staff" is a judgement about meaning; a checker that tried it would be matching words, and a frame narrow enough to match on words is a frame that has already given up what it is for.

The refusal goes into the journal rather than into the hypothesis, because the hypothesis is not admitted at all — there is nothing yet to carry a status.
`declined` is the other refusal and a different one: it means true, measured, and deliberately not ours to act on, which happens at the far end of the lifecycle rather than at its door.

### FR-GND-540 — A record is cited like a requirement

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-010, FR-SKILL-200]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-09-17
```

When asked to cite records, the grounds checker **shall** print each one ready to paste: its identifier, its title, the file it is written in and its status.

**Rationale.** A hypothesis, a bet, a frame, an ideology and an unclaimed declaration are all named to a person — in the dashboard's readings, in a blast report, in the answer to what a requirement stands on — and every one of them was named by key, because nothing in the framework could print more: the viewer's `--cite` reaches the specification only, and reaches nothing in `grounds/` by design.
The form is the one `FR-VIEW-240` fixed; the resolver is this checker's, because the register is its to read.
All five kinds, because the rule is about naming a record to a person and does not care which kind; a `U` declaration cited in full says what it stands in for, which is the whole point of citing it.
An unknown identifier is refused in the same run, naming it.

