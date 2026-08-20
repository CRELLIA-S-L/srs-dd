# The grounds register

<!-- SRS-DD-VERSION — installed by the framework; --force overwrites local edits -->

A specification records what the system must do. It does not record why
anyone thought those were the right things to build. That reasoning lives in
rationale prose, which is asked for only where a decision is not obvious and
which no rule checks: delete a requirement's rationale and a strict run
reports nothing at all.

This register is where that reasoning goes. Most of it is claims about the
world — who needs the thing, what they will pay for, what they do today
instead. Such a claim can be false, and that is the point of writing it in
this shape: its falsification becomes visible where the code is, instead of
being noticed years later by whoever wonders what a feature was for.

The rest is the ground no measurement touches: what the product is for, and
what it will not do whatever anyone measures. Three kinds of ground, one
register, and the sections below say which is which.

The register is optional. It is a sibling of `specs/`, never a part of it,
and nothing here is ever written into a requirement file.

## When not to have this

Do not install the register where the basis of the work is fixed outside the
project and does not move: avionics, a protocol implementation, a compliance
obligation, a component whose contract is somebody else's specification.
There the requirement tree already carries everything, the hypotheses would be
invented to fill the file, and a register of invented entries teaches every
reader that the register is decoration.

The question worth asking before installing is not "could we write hypotheses
down" but "will anybody measure them". Where the answer is no, decline the
layer and lose nothing.

## The core and the fog

The register describes a project as two things, and every reading on the
dashboard is about the boundary between them.

**The core** is what the project holds and is willing to build on: its
ideologies, and the hypotheses that have been confirmed *and* admitted. Both
words are load-bearing. A measurement answers whether a hypothesis is true;
admission answers whether being true makes it this project's business, and
only the first of those has a number. A hypothesis that was confirmed and
deliberately turned down is `declined`, and it stays in the register saying
so — that record is what stops the same argument from being had again every
six months.

Nothing sits in the core permanently. A confirmation has a term, and when the
term runs out the hypothesis leaves the core until somebody measures again.
This is why the confirmation classes are written down at all: a core assembled
from hypotheses nobody can afford to re-measure has an expiry date it does not
admit to.

**The fog** is everything else — every hypothesis `untested`, `assumed`,
`expired` or `refuted`. Most of a young project is fog, and should be. The
register does not exist to clear the fog. It exists so that nobody mistakes
it for the core, and so that when a hypothesis is refuted, the requirements
standing on it can be found.

Ideologies live in the core and are never measured; they are what the
hypotheses are measured *for*, and what settles which arguments count as
weighty enough to reopen anything. Frames are not in the core. They are the
boundary it may not cross whatever the core comes to hold, which is why no
evidence can retire one.

## Map

```
grounds/
  README.md              this standard
  grounds-config.json    what each rule costs in this project
  00-ideology.md         I-NNN — what the system is for
  01-frames.md           F-NNN — the boundaries it will not cross
  02-unclaimed.md        U-NNN — requirements declared to rest on nothing
  03-bets.md             B-NNN — which requirement rests on which hypotheses
  10-h-<topic>.md        H-NNN — the hypotheses themselves, grouped by topic
  90-dashboard.md        generated; never edited by hand
```

## Identifier

`<KIND>-<NNN>`, three digits, numbered in tens so there is room to insert:
`H-010`, `B-020`, `I-010`. The kinds are `I`, `F`, `H`, `B` and `U`, and the
sections below say what each holds.

An identifier is permanent. A cancelled entry keeps its number and says in
its status that it was cancelled; the number is never given to anything else.
References outlive what they refer to — a refuted hypothesis is cited by the
decision that removed the feature standing on it, and a hypothesis that was
confirmed and turned down exists precisely so that the same argument
returning in six months is answered from the record rather than from memory.

## The record

Every record in this register, of every kind, is written the same way:

````markdown
### H-010 — Studios lose time to manual roll-up

```yaml
status: assumed
class: III
population: studios of 5 to 50 people already tracking time
refuted_if: proportion < 0.30 at n >= 40
expires: 2027-03-01
owner: @kira
impact: about half the 2027 paid-subscription plan; nothing else drives it
```

At least three studios in ten spend more than an hour a week assembling
time reports by hand.

**Rationale.** Six of the eight discovery calls raised it unprompted, which
is why this is written down at all — and also why it is `class: III`: eight
calls are not a measurement.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-02-14 | 0.38 | 42 | supported | @kira |
````

A level-three heading with the identifier and a title; a fenced `yaml` block
of flat keys whose values are scalars or bracketed lists; a statement; and,
optionally, a rationale and a table.

The shape deliberately resembles a requirement block, so that whoever has
read `specs/README.md` already knows how to read this. It is not the same
format. Neither is obliged to follow the other's edge cases, and a later
reader who merges them would be inventing a coupling this register was
designed to avoid.

**Keys are added, never renamed.** Each kind below declares which of its keys
are required and which are optional. A key that is neither is not an error —
that tolerance is what lets a later version of this format add a key without
breaking a register written against an earlier one. A rename or a removal has
no such escape, so it does not happen.

## The kinds

### `I` — ideology

What the system is for, in one sentence somebody could disagree with. A
project has one or a few; a project with a dozen has a list of features.

| Key | | |
|---|---|---|
| `status` | required | `active`, `dissolved` |
| `admissible_arguments` | required | what counts as a reason to revise it |
| `adopted` | optional | date |

An ideology is not measured. It is part of the core without ever having been
confirmed, because it is what the hypotheses are confirmed *for*, and it
changes only when enough of the ground under it has moved — which is a
decision, taken deliberately, and recorded as one.

**`admissible_arguments` is what makes that decision governable.** An
ideology that any argument can move is a preference; one that no argument can
move is a slogan. The set is declared by the ideology itself rather than
fixed here, because what counts as weighty is the thing that describes an
organisation most exactly — and revenue installed as the universal currency
of persuasion is the mechanism that makes every organisation the same one.

An amendment is recorded as a row, and the last column is the one that
matters:

```markdown
| date | what changed | why | territory it opens |
|---|---|---|---|
| 2027-01-12 | studios of 5–30 becomes 5–80 | three refusals in a quarter | teams with a delivery manager |
```

A revision is legitimate when it opens ground that was out of bounds before
and names that ground in advance. A quarter later somebody looks at whether
anyone went there. Nobody did, and it was not a revision — it was a capture,
written up as learning.

### `F` — frame

A boundary the project will not cross whatever the evidence says: we do not
sell attention, we do not ship what we cannot support, we do not grow by
making the thing worse. A frame is not a hypothesis, because no measurement
can refute it — refusing it is the whole point.

| Key | | |
|---|---|---|
| `status` | required | `active`, `retired` |
| `adopted` | optional | date |

A frame carries the same amendment table an ideology does, and for a
sharper reason: a frame is amended by decision rather than by argument, and a
new boundary has to be applied backwards over everything already accepted.
That sweep is the real content of the word, and the row is where anyone finds
out it was owed.

A frame also carries a journal of what it has refused, as a table below the
statement:

```markdown
| date | what was refused | who asked |
|---|---|---|
| 2026-05-02 | selling aggregate timing data to tool vendors | growth |
```

A frame that has refused nothing in a long time is not proof of virtue. It
usually means either that nobody is testing the boundary or that the
boundary was drawn where nothing was ever going to happen, and both are
worth knowing.

### `H` — hypothesis

A claim about the world that could turn out to be false.

| Key | | |
|---|---|---|
| `status` | required | see below |
| `class` | required | `I`, `II`, `III` — how it is confirmed |
| `population` | required | who the claim is about, bounded |
| `refuted_if` | required | the threshold, in the grammar below |
| `expires` | required | date after which confirmation no longer counts |
| `owner` | required | who answers for measuring it |
| `impact` | required | what it is worth if true |
| `grade` | optional | how much the evidence is worth |

`impact` is written as a business outcome and not as a score. "About half the
2027 paid-subscription plan, and nothing else in the plan drives it" is an
impact; "high" is a label that ranks against other labels and against nothing
real. It is declared apart from anything about confidence on purpose, because
true and unimportant is an ordinary combination and the two questions have
different answers — what a hypothesis is worth decides whether to measure it
at all, and how well it is measured decides what may be done once it holds.

Statuses, and they are a lifecycle rather than a scale of confidence:

| | |
|---|---|
| `untested` | written down, nothing measured, nobody relying on it yet |
| `assumed` | taken on faith and being built on — an honest state, not a defect |
| `supported` | a measurement met the threshold |
| `refuted` | a measurement did not |
| `expired` | its term ran out before anyone re-confirmed it |
| `declined` | true, and deliberately not ours to act on |

`declined` is the one worth explaining. A hypothesis can be confirmed and
still be refused: the thing is real, and this project is not going to be the
one to do it. Recording that is what stops the question from being argued from
scratch every six months, and a declined hypothesis keeps its reason and the
date the decision was taken.

### `B` — bet

Which requirement rests on which hypotheses. The join lives here and only
here: a requirement never says what it stands on, so the register says what
stands on it, and the other direction is computed.

| Key | | |
|---|---|---|
| `status` | required | `active`, `retired` |
| `requirement` | required | one requirement identifier |
| `all_of` | optional | hypotheses that are all needed |
| `any_of` | optional | hypotheses of which any one suffices |
| `served_by_any` | optional | competing solutions to the same need |
| `instrument` | optional | `yes` where the requirement exists to measure |

The two lists are not decoration. `all_of` is a chain — refute any one of
them and the ground is gone. `any_of` is a set of alternatives — the
strongest of them carries the requirement. Collapsing the two into a single
list produces a number that is wrong in the optimistic direction, which is
the direction that does no good.

`instrument` marks the requirement that exists so the measurement can be
taken at all — the event, the attribution, the cohort tag. It sits on the bet
rather than on the requirement because being an instrument is a fact about
the pair: the same requirement can measure one hypothesis and rest on
another. What it buys is an exemption. When the hypothesis is refuted, what
was built on it is put up for removal and the instrument is not, because the
instrument is what the next bet will be measured with, and a project that
tears down its measuring after every refutation ends up unable to ask
anything twice.

Where a requirement has two independent sets of alternatives, write two bets
naming it. The record *is* the group; there is no nesting and no group label.
Two bets on one requirement are also how the mistake looks, so the checker
asks whether it was deliberate.

### `U` — unclaimed by declaration

A requirement that rests on no hypothesis, said out loud, with the reason.

| Key | | |
|---|---|---|
| `status` | required | `active`, `retired` |
| `requirement` | required | one requirement identifier |

The reason is the statement of the record, and a declaration without one is
an error — an unexplained declaration is indistinguishable from a shrug.

## How a hypothesis is confirmed

Confirmation is not one thing. Three classes, differing in what they cost and
in what they are worth:

| Class | What it is | What it costs |
|---|---|---|
| I | passive: an instrument already running produces the number | nothing per re-confirmation |
| II | an intervention: somebody runs an experiment | a piece of work each time |
| III | outside the system: interviews, observation, judgement | a person's time and attention |

The class is a claim about the measurement, and it has to be true. Declaring
class I over a quantity nothing instruments produces a hypothesis that will
sit unconfirmed until its term runs out with nothing saying why.

Only class I is affordable to re-confirm continuously, and that is the whole
reason the classes are written down: a register that treats every hypothesis
as permanently confirmable is a register whose expiry dates are fiction.

### The threshold

`refuted_if` is declared before the first measurement, in this grammar:

```
proportion|mean|count   <  <=  >  >=   <number>  at n >= <integer>
```

for example `proportion < 0.25 at n >= 200`, `mean < 4.0 at n >= 50`,
`count < 3 at n >= 1`. Those four comparisons and no others: a threshold
written with `=` is a coincidence rather than a boundary, and one written in
prose is a threshold nobody can apply twice the same way.

The kind of quantity comes first because it decides what a fair test is: a
proportion, a mean and a count are not compared to a threshold the same way.
Where the kind is one this register cannot test sequentially, the hypothesis
cannot be class I, and re-confirmation becomes a human act performed on
purpose.

Moving a threshold after the first measurement is how a hypothesis stops being
falsifiable. The record keeps enough history to notice.

### Evidence

Evidence is a table under the record, one row per measurement:

```markdown
| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-02-14 | 0.38 | 42 | supported | @kira |
| 2026-08-01 | 0.19 | 210 | refuted | telemetry |
```

Rows are appended. A row is never edited and never removed — a measurement
that turned out to be wrong gets a later row saying so, because a register
whose inconvenient rows disappear is a register that only ever agrees with
the present.

## Requirements no hypothesis stands behind

The most useful thing this register produces is the list of requirements that
rest on nothing anybody wrote down. That list is a reading of the product,
not a defect report: it says the system acquired something nobody can now
say why it has.

**No rule of this layer requires a requirement to be named by a bet, and none
ever will.** Where a link is mandatory it gets invented, and an invented link
is worse than an absent one because it looks like knowledge. Every
traceability practice that has demanded completeness has destroyed exactly
this signal — once everything traces to something, the tracing confirms only
that somebody drew a line.

What may be asked of an author is the declaration: one `U` record naming the
requirement and saying why it stands alone. The declaration retires itself
the moment a real bet appears, and the checker says so.

The asymmetry is deliberate and is the reason the register works. Declaring
is a line and a sentence. Inventing a bet means inventing a hypothesis — a
bounded population, a quantity, a threshold, a date and a named owner — that
somebody will be asked about next quarter. It is cheaper to be honest, which
is the only arrangement that survives contact with a deadline.

## Configuration

`grounds/grounds-config.json` — its presence is what says this project
carries the register.

| Key | Default | |
|---|---|---|
| `rules` | `{}` | What a finding costs: `warn` (the default, and what `--strict` fails on), `report` (said, never fatal), `off` (not said at all). Keys are rule names |

Errors are not in this table and cannot be lowered: a malformed or repeated
identifier, a missing required key, a bet naming a requirement that does not
exist, and a declaration with no reason are all refusals to read the
register, not opinions about it.

## The dashboard

`grounds/90-dashboard.md` is generated from the records and committed, so
that a diff shows the readings move and a gate can compare what is committed
against what the records say now. It is never edited by hand — a summary
somebody can edit is a summary that will be edited into agreement with what
its author wishes were true.

## Checking

```
python3 tools/srs_grounds.py            check and rewrite the dashboard
python3 tools/srs_grounds.py --no-write check only
python3 tools/srs_grounds.py --strict   treat warnings as errors
```

Exit 0 where nothing was found and, under `--strict`, no warning either; 1 on
errors, or on warnings under `--strict`; 2 where it could not run at all.

The requirement model is read by running the viewer, not by parsing `specs/`.
Where the specification is unreadable the register says so and reports what it
still can, rather than dying on somebody else's configuration.

## What not to do

- **Do not invent a bet to make a number look better.** The unclaimed list is
  the point, not the debt.
- **Do not edit an evidence row.** Append a new one.
- **Do not move a threshold once measurement has begun.** Write a new
  hypothesis and retire the old one, so that both are visible.
- **Do not write a hypothesis that cannot be false.** "Studios need better
  reporting" is an attitude. "At least a quarter of them export to a
  spreadsheet weekly" is a hypothesis.
- **Do not write the solution into the hypothesis.** "We need a comparison
  screen" tests whether the idea was popular. The hypothesis is about the
  need.
- **Do not let a tool change a record.** Everything in here is authored. The
  dashboard is the one file written by a machine, and the only one.
