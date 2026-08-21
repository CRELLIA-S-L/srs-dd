# Functional requirements — bel

The grounds register: an optional subsystem recording what the requirements
rest on. Hypotheses about people, the bets that tie them to requirements, and
the checker that reads both. A project without `grounds/` has none of this
and is unaffected by all of it.

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
```

Where a project carries a grounds register, the grounds checker **shall** read
every record in it.

**Rationale.** This is the entry the rest of the subsystem hangs from: exit
codes describe this run, the dashboard is what this run produces, and the
constraint on where the tool may write is a constraint on this run. Stating
it separately keeps those from each having to restate what they are about.

Scoped to a project that carries the register, because the layer is optional
in the way `--ci` is optional: a target that declined it has no `grounds/`
directory, and nothing about its checker, its gate or its skills changes.
The presence of the register is the switch — not a flag recorded somewhere
that can disagree with what is on disk.

Reading is separated from judging on purpose. What counts as an error, a
warning or a silence is the business of the rules, each with its own
requirement and its own name; this one says only that the records are read
and that the run says something about them.

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
```

If a register identifier is repeated or does not match `<KIND>-<NNN>` with a
kind the register's standard defines, the grounds checker **shall** report
it as an error naming both occurrences.

**Rationale.** A duplicate is the quiet failure: one entry shadows the other,
the reader sees a record where they expect one, and the bet that names the
number points at whichever the parser reached last. Naming both occurrences
is what makes it a report somebody can act on rather than a complaint.

An error and not a rule with a severity, because a project that silenced this
would be running on a register whose entries cannot be resolved by number —
and every citation in a decision, a commit or a bet is by number.

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
```

Where a record omits a key the format requires, the grounds checker
**shall** report that key as missing rather than as holding a bad value.

**Rationale.** The same distinction `FR-CHK-170` draws, and it matters more
here: a hypothesis without `refuted_if` is not a hypothesis with an empty
threshold, it is a claim nobody agreed how to kill. Told the value is bad, an
author goes looking at what they wrote; told the key is absent, they write it.

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
```

Where a record names a requirement absent from the requirement model, the
grounds checker **shall** report it as an error naming the record and the
requirement.

**Rationale.** The register points into a model it does not own, and a
dangling name is the way that pointer rots. Left unreported it is worse than
useless: the reduction skips what it cannot resolve, so a requirement whose
ground has silently vanished reads as one with no ground claimed — which is
the state the orphan counter is supposed to mean something about.

An error rather than a warning because the cause is never legitimate. A
requirement that was cancelled still exists and is `FR-GND-050`; a name that
resolves to nothing is a typo or a rename nobody carried through.

Two kinds of record name a requirement and both are covered by one
obligation, because the failure is one thing: a pointer into a model this
register does not own. A declaration is the quieter half — it says a
requirement rests on nothing, and where the requirement does not exist it
says that about nothing at all, while looking from the outside exactly like
the honest declaration the whole layer is built to encourage.

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
```

When a bet names a requirement that has been cancelled, the grounds checker
**shall** report it as a warning naming both.

**Rationale.** Cancelling a requirement leaves every bet on it standing, and
what those bets now claim is that something rests on ground nobody will
build. `FR-CHK-190` is in the same position for requirements resting on a
withdrawn one, and takes the same view: a warning, because this is the
aftermath of a legitimate act and the resolution is a decision — retire the
bet, or move it to whatever replaced the requirement.

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
```

Where a hypothesis's term has run out, the grounds checker **shall** report
it as a warning naming the hypothesis.

**Rationale.** The term is the whole point of recording one: a measurement
taken two years ago is not evidence about today, and without a term nothing
ever asks. Reporting is all this does — the record is left exactly as it was,
because expiry is not a verdict and a tool that moved the status would be
answering a question only a measurement can answer. What forbids the tool to
touch it is `CON-GND-030`.

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
```

The grounds checker **shall** take the hypothesis that decides a
requirement to be the weakest of those its bets require and the strongest of
those they offer as alternatives.

**Rationale.** Confidence is a weakest-link property: a requirement is no
better supported than the shakiest thing it cannot do without. Where the
hypotheses are alternatives the reading inverts — any one of them carries it,
so the strongest decides. Collapsing the two into one rule produces a number
wrong in the optimistic direction, which is the direction that gets nobody's
attention.

One act over two cases rather than two requirements, in the reading
`specs/README.md` gives for a rule that covers the cases it names: the
obligation is the reduction, and half of it computed is not half the
obligation met.

Which hypothesis decides, rather than what is read off it. The status is what
this is reduced over first, because that is what the debt reading in
`FR-GND-130` needs; a grade reduces the same way and along the same edges
once there is one. Saying it this way keeps one rule where there would
otherwise be two that must agree.

Across several bets on one requirement the weakest wins again, which is why
`FR-GND-080` reports the case where that was not intended.

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
```

Where more than one bet names the same requirement, the grounds checker
**shall** report it as a warning naming them.

**Rationale.** Two bets on one requirement are how two independent sets of
alternatives are expressed, and they are also how a duplicate arrives when an
author does not notice the existing one. The two are indistinguishable in the
file and not in the arithmetic: deliberate, the grade is the weaker of the
two records; accidental, a maximum quietly became a minimum. This is the only
silent failure the record encoding introduces (ADR-0016), and a warning is
what turns it loud without forbidding the legitimate case.

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
```

Where a requirement is declared as resting on no hypothesis, the grounds
checker **shall** report a declaration without a reason as an error.

**Rationale.** `INV-GND-030` forbids demanding a bet, which leaves the
question of what an author does with a requirement that honestly has none.
The answer is a declaration, and what keeps it honest is that it costs a
sentence: a reason somebody wrote is a reason somebody can disagree with, and
a blank one is a silencer wearing the shape of a record.

The asymmetry is the point and is worth stating so it is not optimised away.
Inventing a bet means inventing a falsifiable claim with an owner and a term
that somebody will ask about in a quarter. Declaring costs one line. Nobody
made declaring cheap; what was made expensive is lying.

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
```

Where a requirement declared as resting on no hypothesis is named by a bet,
the grounds checker **shall** report the declaration as superfluous.

**Rationale.** An exemption nobody retires is an exemption that outlives its
reason, and the register would fill with declarations describing a state that
ended months ago. The pattern is borrowed from linters, where a suppression
must carry a description and the tool removes it once the rule it suppressed
stops firing: the machine retires the exemption, not the person who has
forgotten it exists.

### FR-GND-110 — What a hypothesis rule costs is the project's to set

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-GND-030]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
```

The grounds checker **shall** let a project lower a rule to a report or
silence it altogether in the register's configuration.

**Rationale.** The same lever `FR-CHK-160` gives the specification checker,
and the layer needs it more, not less. A project adopting the register
mid-flight has requirements older than any hypothesis anyone will write for
them, and a rule firing on every one of them is a wall rather than a queue.

Only the project-wide lever, not a per-record one. The exemption a
requirement carries in its own block exists because a requirement can be a
legitimate exception to a rule about requirements; here the analogous case —
a requirement resting on nothing — already has its own affordance in
`FR-GND-090`, and a second way to silence it would be a way to skip the
reason.

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
```

Where `--strict` is given, the grounds checker **shall** exit non-zero when
warnings were reported even if no error was.

**Rationale.** Most of what this checker says is a warning by design — an
expired hypothesis, a bet on a cancelled requirement, a superfluous
declaration are all conditions somebody must decide about rather than defects.
A gate that only failed on errors would therefore never fail, and the register
would drift with nothing to notice.

Stated separately from `IF-GND-020` for the reason the specification checker
keeps `FR-CHK-120` beside `IF-CI-020`: one says what the run does, the other
publishes the numbers a caller binds to.

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
```

The dashboard **shall** state what proportion of the requirements carrying a
bet rest on hypotheses that are `refuted`, `expired` or `assumed`.

**Rationale.** This is the reading the subsystem exists to produce. Everything
else it records — the terms, the thresholds, the grades — is machinery for
computing one number that nobody currently has: how much of what is built
stands on ground its owners no longer believe in.

The three states are one reading rather than three, because what the number
answers is a single question. Splitting them would invite the answer that
matters least: `assumed` alone is a measure of how little has been measured,
and `refuted` alone flatters a project that never checks anything.

Scoped to the requirements carrying a bet. Those carrying none are a
different reading with a different meaning, and folding them in here would
let a project improve this number by writing fewer bets.

### FR-GND-140 — A verdict follows from the threshold

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a measurement's verdict does not follow from comparing it against the
hypothesis's threshold, the grounds checker **shall** report it as an error
naming both.

**Rationale.** The threshold is declared before the measurement precisely so
that the verdict stops being a matter of opinion, and a row saying the
hypothesis survived at a value below its own threshold is the record
disagreeing with itself. Left alone it is worse than a missing verdict: it
reads as a judgement somebody made rather than an arithmetic nobody did.

### FR-GND-150 — The criterion follows the kind of quantity

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-GND-140]
refines: []
conflicts_with: []
code: []
tests: []
```

The grounds checker **shall** take the reconfirmation criterion from the
kind of quantity the threshold names, and report a hypothesis of class I whose
kind it supports no criterion for.

**Rationale.** "Reconfirm by a sequential criterion" has no content until the
quantity is typed. A sequential probability ratio test is meaningful for a
proportion with a denominator; for a mean it is a different test, for a count
a different one again, and for a revenue figure the prescription says nothing
at all. Naming the kind in the threshold is what makes the criterion
choosable rather than assumed.

A kind with no criterion closes class I rather than falling back to a naive
comparison, because automatic reconfirmation is the whole of what class I
means. Left to fall back, the naive comparison would refute on the first dip
— which is the failure the criterion exists to prevent, arriving through the
door marked convenience.

### FR-GND-160 — A class III verdict names who made it

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-GND-140]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a verdict on a class III measurement does not name who made it, the
grounds checker **shall** report it.

**Rationale.** Forty thousand in a cohort and a dozen conversations both end
in the word `supported`, and only for the second is the word somebody's
reading. A reading with no reader named is not evidence anyone can weigh, and
it is also the hook `FR-GND-210` needs: an author whose verdicts keep being
reversed cannot be noticed if the verdicts are anonymous.

Reported and not corrected. Which status is right is a question only whoever
took the measurement can answer, and `CON-GND-030` forbids the tool to touch
the record in any case.

### FR-GND-170 — A grade permits only the actions declared for it

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-GND-110]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a hypothesis declares an action its grade does not permit in the
register's configuration, the grounds checker **shall** report it.

**Rationale.** A grade with nothing attached is a label. What makes it do work
is the binding: the configuration says which actions each grade permits, and a
hypothesis acting beyond its evidence is reported rather than left to the
reader to notice (ADR-0017).

The map lives in the configuration and not in the format because what a
weakly supported hypothesis may be used for is a matter of appetite. A project
betting a quarter on low certainty and one betting a release are both
coherent; neither is the framework's to decide.

### FR-GND-180 — A declined hypothesis carries a reason and a date

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [INV-GND-010]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a hypothesis is declined without a reason or without the date the
refusal was made, the grounds checker **shall** report it as an error.

**Rationale.** A refusal is recorded so that the same question returning in
six months is answered from the record instead of argued again. Without the
reason it answers nothing; without the date nobody can tell whether the
answer is still the current one or predates everything that has changed
since.

### FR-GND-190 — The threshold was not moved after the first measurement

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-GND-140]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a hypothesis's threshold was last changed after its earliest recorded
measurement, the grounds checker **shall** report it.

**Rationale.** A threshold named after the result turns every outcome into an
encouraging one, which is the failure the declared-in-advance rule exists to
prevent — and a rule nothing checks is a rule that decays into a habit.

Read from the history of the file rather than from the file, which is the
only place the ordering exists. Where that history cannot be read — a shallow
clone, a squashed import — the run says so rather than passing in silence,
the position `FR-VIEW-090` takes for baselines it cannot reach.

### FR-GND-200 — Evidence is only ever added

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [CON-GND-030]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a measurement recorded earlier is absent from a hypothesis or differs
from what was recorded, the grounds checker **shall** report it.

**Rationale.** The older measurement is what the newer one is a change from.
Deleting it deletes the change, and a hypothesis whose evidence shows only the
result that suited its author is a hypothesis with no history at all.

Distinct from `CON-GND-030`, which forbids the tool to modify a record. That
one binds the machinery; this one catches a person, and neither covers the
other. Same reliance on history, same answer where the history is missing.

### FR-GND-210 — How often an author's verdicts were reversed

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-GND-160]
refines: []
conflicts_with: []
code: []
tests: []
```

The dashboard **shall** state, for each author of a verdict, how many of
their verdicts a later measurement reversed.

**Rationale.** Weighting expert judgement by measured accuracy needs
calibration questions with known answers and a programme to run them, which
is an organizational undertaking and not a file format. This is its
affordable half: it needs nothing the register does not already hold, and it
answers the question that matters most about a class III verdict — whether
this person has been right before.

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
```

The dashboard **shall** state, for each requirement resting on no hypothesis,
how much of the system rests on that requirement.

**Rationale.** An unclaimed requirement that twelve others depend on and that
names eight files is a different reading from a leaf naming one, and treating
them alike is how the signal drowns in its own volume.

No field is asked of anyone. The weight of a missing hypothesis cannot be
recorded, because there is no hypothesis to record it on; what is available is
the requirement's own weight, and it is available already — what depends on
it and how much code it names.

### FR-GND-230 — New unclaimed requirements, and where they cluster

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-GND-220]
refines: []
conflicts_with: []
code: []
tests: []
```

The dashboard **shall** state how many requirements came to rest on no
hypothesis within the period and in which areas.

**Rationale.** One unclaimed requirement is noise and is meant to be. Five in
a quarter, four of them in one area, is the product having become something
nobody said out loud — and that reading is unavailable from any single one of
them.

Whether they point in one direction is a question about meaning and stays
with the reader. The area is the part a machine can see, and it is a good
enough proxy to make the question worth asking.

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
```

The dashboard **shall** state how old the confirmations in the core are,
separately for each class of confirmation.

**Rationale.** A single figure lets a cheap class refresh often enough to
hide an expensive one that has not been checked in a year — and the expensive
classes are the ones carrying the claims about whether the product should
exist at all. Separated, the reading says not only how fresh the core is but
which part of it is fresh, which is the difference between reassurance and
information.

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
```

The dashboard **shall** state, for each frame, what it has refused and when.

**Rationale.** A frame is a rule about what the product will not do whatever
the evidence, and its whole value is in the refusals. One that has refused
nothing in a year is either a slogan or a rule applied at the wrong moment,
and neither is visible without the journal.

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
```

The dashboard **shall** state how many ideologies the core carries.

**Rationale.** One or two is the intended state. Grown to five, what the
register describes is a suite of products sharing a repository, and the
counting is the cheapest way to notice a drift nobody decided on.

### FR-GND-270 — History that cannot be read is said to be unread

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-GND-190]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a rule needs the register's history and that history cannot be read,
the grounds checker **shall** report that it could not be read rather than
pass the rule.

**Rationale.** Three rules read history rather than files — the threshold's
ordering, the evidence that must only grow, the verdicts a later measurement
reversed — and all three meet the same wall in a shallow clone, a squashed
import, or a checkout that is not a repository at all.

Passing in silence there is the worst of the three available answers. It
turns a rule into an assertion that cannot fail, which is the shape
`FR-CI-080` exists to forbid, and it does so exactly where somebody would
most want to know: a history nobody can read is also a history nobody can
audit. Failing outright is the other extreme and would make the register
unusable in every environment that clones shallowly, which includes most
default pipelines.

Saying so is the answer `FR-VIEW-090` already gives for baselines it cannot
reach, and the reason carries over: a reader who is told nothing assumes the
check ran.

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
```

A fresh install and an adoption **shall** offer the grounds register as a
choice, installing nothing of it where it is declined.

**Rationale.** The layer answers a question many projects do not have. Its
own scope note excludes a project whose basis is externally fixed and
stable — avionics, a protocol implementation, regulatory compliance — and
installing it there produces records nobody will ever measure.

Declined, it leaves nothing: no directory, no tool, no skill, no
configuration key. A target that said no is byte-for-byte a target that was
never asked, which is what makes the choice cheap to make and cheap to
reverse.

### FR-GND-290 — The register is added deliberately, never silently

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-280]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
```

An upgrade **shall** refresh the grounds register's tooling only where the
register is already present, adding it to a project that has none only when
asked.

**Rationale.** Upgrades refresh the tooling and the skills without a flag,
and along that path a new subsystem would arrive at every project that merely
updated. The ones it would surprise are exactly the ones the scope note
excludes: they did not decline the register, they never heard of it.

Presence is read from the register itself rather than from a setting, so
there is nothing to disagree with what is on disk. The same reading the
installer already makes when it decides between a fresh install and an
upgrade.

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
```

Where the grounds register is installed, the target's own grounds checker
**shall** pass strictly on what was installed.

**Rationale.** The same promise `FR-INIT-020` makes for the specification: a
project's first run is green, so the first red one means something the
project did. A skeleton that arrives already warning teaches its reader that
the warnings are furniture.

Strictly, and not merely without errors, because almost everything this
checker says is a warning by design — a skeleton that passes only the loose
run would be hiding its own state from the gate the project is about to
switch on.

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
```

Where a project carries a grounds register, the installed hook **shall**
report, without failing the commit, the bets on the requirements whose files
the commit changes.

**Rationale.** The register's promise is that a stale hypothesis becomes
visible where the code is, and a dashboard nobody is obliged to open does not
keep it. The hook is the one place the framework already reaches everyone who
opted into the gate, and the moment it reaches them is the moment they are
touching the code in question.

Scoped to the commit, because a refuted hypothesis elsewhere in the project is
not this commit's business and a report that always speaks is a report nobody
reads. Never failing, because a refuted hypothesis is not the committer's
fault and may be precisely what they are in the middle of repairing.

What may not fail is this report, not the hook. The hook already fails on a
stale matrix, and the shipped template invites a project to add `--strict`
and fail on warnings besides; nothing here takes either away.

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
```

The skills installed into a project **shall** include the grounds procedure
where the register is installed.

**Rationale.** A project's hypotheses are its own, and nothing about writing
one is about this repository — the reading `FR-SKILL-080` gives for the
baseline procedure, and the opposite of the one `FR-SKILL-070` gives for the
release procedure, which stays here because a target releases nothing of ours.

Only where the register is installed. A skill for a subsystem a project
declined is a file explaining something it does not have.

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
```

When a hypothesis is written or reworded, the procedure doing so **shall**
judge it against the qualities no checker reaches — a bounded population, an
observable action rather than an attitude, a magnitude, and no solution
carried inside the need — and say what it found before the text is recorded.

**Rationale.** `FR-SKILL-120` makes this obligation for requirement
statements and gives the reason no word list can do it. The qualities differ
here, and two of them are where hypotheses go wrong.

Attitudes do not measure. "Studios need time roll-up" cannot be false; "at
least a quarter of those who reach the report take a paid plan within a
fortnight" can. And the commoner mistake runs the other way: a solution
smuggled into the need. "We need a comparison screen" is already an answer,
and a hypothesis written that way tests the answer instead of the need — which
is how a project ends up measuring whether its idea was popular rather than
whether the problem was real.

Verified by inspection for the reason every procedure requirement is: no
suite runs a dialog, and one asserting the wording would be a copy of the
file rather than a check on it.

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
```

When a hypothesis's class is chosen, the procedure doing so **shall** check
that the declared measurement can produce a number the threshold compares
against, and say where it cannot.

**Rationale.** `FR-SKILL-140` puts the same question to a requirement's
verification method at the one moment it costs nothing — while the statement
and the method are on the table together. Left to surface later, it surfaces
when somebody has to take a measurement that cannot be taken.

Class I is where this bites. It claims the measurement is passive and
automatic, and an author who declares it over a quantity nobody instruments
has written a hypothesis that will sit unconfirmed until its term runs out,
with nothing saying why.

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
```

When a hypothesis is refuted, the procedure doing so **shall** settle each
requirement that rested on it with the maintainer, taking removal as the
default.

**Rationale.** The requirements do not evaporate: they are shipped, people
use them, their data is in the schema. What refutation takes away is the
ground, not the code, and the difference between those two is a project with
a date rather than a deletion.

Removal is the default because the opposite default is how dead features
survive for years. Where somebody still uses it, that is not a reason to keep
it — it is a new fact: something other than the refuted hypothesis is holding
it up. Naming that hypothesis is the price of keeping the code, and where
nobody will name it the code goes.

Which requirements rested on it is read from the bets, and the shape of the
conversation is the one `FR-SKILL-150` prescribes for a withdrawal: show what
stands on it, settle each dependant, do not cascade silently.

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
```

When a hypothesis is confirmed, the procedure doing so **shall** put its
admission to the core to the maintainer as a decision of its own, and record
a refusal with its reason.

**Rationale.** Confirmation answers whether something is true. Admission
answers whether being true makes it ours, and only the first has a
measurement. A register that admits whatever confirms has a core that cannot
decline anything, which is the one thing a core is for.

The outcomes are absorb, spin off as a second product, or refuse. The third
is the one that needs writing down: without it nobody can tell a hypothesis
nobody tested from one tested, confirmed and turned down, and the same
question returns every six months to be argued from scratch.

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
```

Where a project carries a grounds register, its gate **shall** regenerate the
dashboard and fail when the committed copy differs from it.

**Rationale.** `CON-GND-020` says the dashboard is generated and never edited
by hand; this is what makes that true rather than hoped for. Generated output
that nothing compares is output somebody will eventually edit, and the
readings it carries — how much of the system stands on refuted ground, how
old the confirmations are — are exactly the numbers worth editing.

Realized in part: this repository's own gate regenerates the dashboard and
compares it, and a project that installs the register has no gate doing so
until the layer is shipped with one. That is the half this status records.

`FR-CI-010` states the same obligation for the traceability matrix and lives
in the area about gates. This one lives here instead, because what it is
about is the register's own integrity; the gate is where it happens, not what
it concerns.

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
```

Where a bet declares its requirement to be an instrument, the procedure
settling a refutation **shall** leave that requirement out of the removal it
proposes.

**Rationale.** `FR-GND-350` takes removal as the default, and that default is
right for the feature and wrong for the thing that measured it. The screen
existed because somebody believed the hypothesis; the event counting who
opened the screen existed to find out whether they were right. Refutation is
that event answering its question, and answering it is not a reason to delete
the answering.

What the instrument is for is the bet after this one. A funnel and an
attribution are what the successor hypothesis will be measured with, and a
project that removes them with every refutation is a project that has to
rebuild its measuring before it can ask anything again — which is how
measuring quietly stops happening.

Declared on the bet and not on the requirement, for the reason the join
itself is: nothing in this layer writes into a requirement file. It is also
the more accurate place. Being an instrument is a fact about a pair — the
same requirement can measure one hypothesis and rest on another — and the
bet is the record that names exactly that pair.

Verified by inspection for the reason every procedure requirement here is: no
suite runs a dialog, and one asserting the wording would be a copy of the
procedure rather than a check on it.

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
```

Where a record carries a value the format does not define for its key, the
grounds checker **shall** report it as an error naming the record, the key
and the value.

**Rationale.** Every reading this register produces is a function of a
handful of constrained values, and a value nothing recognises has to be
treated as something. Both available answers are wrong, and which one is
worse depends only on the key.

For `status` it is the reduction: rank an unrecognised one weakest and a typo
reads as a refutation, rank it strongest and it hides in the core. For
`class` there is no ranking to get wrong and the failure is quieter — the
core is reported by class, so a supported hypothesis whose class is not one
the format defines appears in no row at all, and the core reads smaller than
it is while the register plainly holds it. For a date it is louder still: a
term that cannot be read is a term that never runs out.

An error rather than a tunable finding, and for the reason a malformed
identifier is one: the alternative to failing is a number that is
confidently wrong, and a project cannot usefully choose to be told less
about that.

Separate from `FR-GND-030`, which is about a key that is absent. This is
about a key that is present and says something the format does not define —
the distinction that requirement's own statement draws.

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
```

Where a bet names a hypothesis absent from the register, the grounds checker
**shall** report it as an error naming the bet and the hypothesis.

**Rationale.** `FR-GND-040` guards the requirement end of a bet and nothing
guarded the other one. The two ends fail differently and both fail silently:
a missing requirement means the bet points outside the register, a missing
hypothesis means the bet points at nothing inside it, and in the second case
the reduction quietly computes over a shorter list and reports a requirement
as better supported than it is.

Identifiers are never reused, so a name that resolves to nothing is a
mistyped reference or a record somebody deleted rather than retired — and the
second is what `INV-GND-010` exists to prevent.
