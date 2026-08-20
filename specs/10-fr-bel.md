# Functional requirements — bel

The belief register: an optional subsystem recording what the requirements
rest on. Beliefs about people, the bets that tie them to requirements, and
the checker that reads both. A project without `beliefs/` has none of this
and is unaffected by all of it.

### FR-BEL-010 — The register is read and reported on

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [IF-BEL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a project carries a belief register, the belief checker **shall** read
every record in it.

**Rationale.** This is the entry the rest of the subsystem hangs from: exit
codes describe this run, the dashboard is what this run produces, and the
constraint on where the tool may write is a constraint on this run. Stating
it separately keeps those from each having to restate what they are about.

Scoped to a project that carries the register, because the layer is optional
in the way `--ci` is optional: a target that declined it has no `beliefs/`
directory, and nothing about its checker, its gate or its skills changes.
The presence of the register is the switch — not a flag recorded somewhere
that can disagree with what is on disk.

Reading is separated from judging on purpose. What counts as an error, a
warning or a silence is the business of the rules, each with its own
requirement and its own name; this one says only that the records are read
and that the run says something about them.

### FR-BEL-020 — Well-formed and unique identifiers

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [IF-BEL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

If a register identifier is repeated or does not match `<KIND>-<NNN>` with a
kind the register's standard defines, the belief checker **shall** report it
as an error naming both occurrences.

**Rationale.** A duplicate is the quiet failure: one entry shadows the other,
the reader sees a record where they expect one, and the bet that names the
number points at whichever the parser reached last. Naming both occurrences
is what makes it a report somebody can act on rather than a complaint.

An error and not a rule with a severity, because a project that silenced this
would be running on a register whose entries cannot be resolved by number —
and every citation in a decision, a commit or a bet is by number.

### FR-BEL-030 — A missing required key is named as missing

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [IF-BEL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a record omits a key the format requires, the belief checker **shall**
report that key as missing rather than as holding a bad value.

**Rationale.** The same distinction `FR-CHK-170` draws, and it matters more
here: a belief without `refuted_if` is not a belief with an empty threshold,
it is a claim nobody agreed how to kill. Told the value is bad, an author
goes looking at what they wrote; told the key is absent, they write it.

### FR-BEL-040 — A bet names a requirement that exists

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [INV-BEL-020]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a bet names a requirement absent from the requirement model, the belief
checker **shall** report it as an error naming the bet and the requirement.

**Rationale.** The register points into a model it does not own, and a
dangling name is the way that pointer rots. Left unreported it is worse than
useless: the reduction skips what it cannot resolve, so a requirement whose
ground has silently vanished reads as one with no ground claimed — which is
the state the orphan counter is supposed to mean something about.

An error rather than a warning because the cause is never legitimate. A
requirement that was cancelled still exists and is `FR-BEL-050`; a name that
resolves to nothing is a typo or a rename nobody carried through.

### FR-BEL-050 — A bet on a cancelled requirement is reported

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [INV-BEL-020]
refines: []
conflicts_with: []
code: []
tests: []
```

When a bet names a requirement that has been cancelled, the belief checker
**shall** report it as a warning naming both.

**Rationale.** Cancelling a requirement leaves every bet on it standing, and
what those bets now claim is that something rests on ground nobody will
build. `FR-CHK-190` is in the same position for requirements resting on a
withdrawn one, and takes the same view: a warning, because this is the
aftermath of a legitimate act and the resolution is a decision — retire the
bet, or move it to whatever replaced the requirement.

### FR-BEL-060 — A belief past its term is reported

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-BEL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a belief's term has run out, the belief checker **shall** report it as
a warning naming the belief.

**Rationale.** The term is the whole point of recording one: a measurement
taken two years ago is not evidence about today, and without a term nothing
ever asks. Reporting is all this does — the record is left exactly as it was,
because expiry is not a verdict and a tool that moved the status would be
answering a question only a measurement can answer. What forbids the tool to
touch it is `CON-BEL-030`.

### FR-BEL-070 — The weakest necessary belief decides

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [INV-BEL-020]
refines: []
conflicts_with: []
code: []
tests: []
```

The belief checker **shall** take the belief that decides a requirement to be
the weakest of those its bets require and the strongest of those they offer
as alternatives.

**Rationale.** Confidence is a weakest-link property: a requirement is no
better supported than the shakiest thing it cannot do without. Where the
beliefs are alternatives the reading inverts — any one of them carries it, so
the strongest decides. Collapsing the two into one rule produces a number
wrong in the optimistic direction, which is the direction that gets nobody's
attention.

One act over two cases rather than two requirements, in the reading
`specs/README.md` gives for a rule that covers the cases it names: the
obligation is the reduction, and half of it computed is not half the
obligation met.

Which belief decides, rather than what is read off it. The status is what
this is reduced over first, because that is what the debt reading in
`FR-BEL-130` needs; a grade reduces the same way and along the same edges
once there is one. Saying it this way keeps one rule where there would
otherwise be two that must agree.

Across several bets on one requirement the weakest wins again, which is why
`FR-BEL-080` reports the case where that was not intended.

### FR-BEL-080 — Two bets on one requirement are reported

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [INV-BEL-020]
refines: []
conflicts_with: []
code: []
tests: []
```

Where more than one bet names the same requirement, the belief checker
**shall** report it as a warning naming them.

**Rationale.** Two bets on one requirement are how two independent sets of
alternatives are expressed, and they are also how a duplicate arrives when an
author does not notice the existing one. The two are indistinguishable in the
file and not in the arithmetic: deliberate, the grade is the weaker of the
two records; accidental, a maximum quietly became a minimum. This is the only
silent failure the record encoding introduces (ADR-0016), and a warning is
what turns it loud without forbidding the legitimate case.

### FR-BEL-090 — A declared unclaimed requirement carries a reason

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [INV-BEL-030]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a requirement is declared as resting on no belief, the belief checker
**shall** report a declaration without a reason as an error.

**Rationale.** `INV-BEL-030` forbids demanding a bet, which leaves the
question of what an author does with a requirement that honestly has none.
The answer is a declaration, and what keeps it honest is that it costs a
sentence: a reason somebody wrote is a reason somebody can disagree with, and
a blank one is a silencer wearing the shape of a record.

The asymmetry is the point and is worth stating so it is not optimised away.
Inventing a bet means inventing a falsifiable claim with an owner and a term
that somebody will ask about in a quarter. Declaring costs one line. Nobody
made declaring cheap; what was made expensive is lying.

### FR-BEL-100 — A declaration that stopped being true is reported

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [INV-BEL-030]
refines: []
conflicts_with: []
code: []
tests: []
```

Where a requirement declared as resting on no belief is named by a bet, the
belief checker **shall** report the declaration as superfluous.

**Rationale.** An exemption nobody retires is an exemption that outlives its
reason, and the register would fill with declarations describing a state that
ended months ago. The pattern is borrowed from linters, where a suppression
must carry a description and the tool removes it once the rule it suppressed
stops firing: the machine retires the exemption, not the person who has
forgotten it exists.

### FR-BEL-110 — What a belief rule costs is the project's to set

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [IF-BEL-030]
refines: []
conflicts_with: []
code: []
tests: []
```

The belief checker **shall** let a project lower a rule to a report or
silence it altogether in the register's configuration.

**Rationale.** The same lever `FR-CHK-160` gives the specification checker,
and the layer needs it more, not less. A project adopting the register
mid-flight has requirements older than any belief anyone will write for them,
and a rule firing on every one of them is a wall rather than a queue.

Only the project-wide lever, not a per-record one. The exemption a
requirement carries in its own block exists because a requirement can be a
legitimate exception to a rule about requirements; here the analogous case —
a requirement resting on nothing — already has its own affordance in
`FR-BEL-090`, and a second way to silence it would be a way to skip the
reason.

### FR-BEL-120 — Strict mode

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-BEL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

Where `--strict` is given, the belief checker **shall** exit non-zero when
warnings were reported even if no error was.

**Rationale.** Most of what this checker says is a warning by design — an
expired belief, a bet on a cancelled requirement, a superfluous declaration
are all conditions somebody must decide about rather than defects. A gate
that only failed on errors would therefore never fail, and the register would
drift with nothing to notice.

Stated separately from `IF-BEL-020` for the reason the specification checker
keeps `FR-CHK-120` beside `IF-CI-020`: one says what the run does, the other
publishes the numbers a caller binds to.

### FR-BEL-130 — The debt is on the dashboard

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [CON-BEL-020]
refines: []
conflicts_with: []
code: []
tests: []
```

The dashboard **shall** state what proportion of the requirements carrying a
bet rest on beliefs that are `refuted`, `expired` or `assumed`.

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
