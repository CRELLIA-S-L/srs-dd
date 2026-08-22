---
name: srs-bet
description: Working with the grounds register — writing a hypothesis, staking a requirement on it with a bet, recording a measurement, and settling what happens when one is refuted. Invoke when the user wants to record why the product does something, when a measurement comes in, or when a hypothesis expires. For requirements themselves use srs and srs-new.
---

# Working with the grounds register

**The format lives in `grounds/README.md`.** It is deliberately not
restated here: two descriptions of the same rules would eventually
diverge. Read it if you have not in this session.

The register answers a question the specification does not: not what the
system must do, but on what ground anyone decided it should. That ground
is of three kinds — an ideology says who the product is for, a frame says
what it will not do for anyone, and a hypothesis says something about the
world that could turn out to be false.

Only the last one is measured, and most of the work here is about it.

## Writing a hypothesis

1. **What is claimed, and about whom?** The population is bounded or the
   claim is not falsifiable: "studios of five to fifty already tracking
   time", not "users".
2. **What action would show it?** Attitudes do not measure. "Studios need
   time roll-up" cannot be false. What can is an action somebody takes:
   exports, returns, pays, invites a colleague.
3. **What magnitude?** A claim with no size is a claim that survives any
   result. Say what proportion, what mean, what count.
4. **The threshold, before the first measurement.** `refuted_if` in the
   grammar the format defines. Declared afterwards it turns every outcome
   into an encouraging one.
5. **What it is worth if true.** `impact` in the size of a business
   outcome, not a score out of five. True and unimportant is an ordinary
   combination, and this is the field that tells them apart.
6. **Its term and its owner.** A date, and a person rather than a team.

Then judge what no checker reaches, and say what you found before the
text is recorded. Four things, and two of them are where hypotheses
usually go wrong.

**The population has an edge.** Whoever is not in it is what makes a
measurement possible.

**The claim is about an action, not an attitude.** See step 2, and
distrust the word "need".

**The magnitude is there and it is not the threshold.** Those are two
numbers: what the thing is being built for, and the line below which the
claim is false. A result between them refutes nothing — it says the claim
survived and its size was wrong, which is a fact about the plan rather
than about the world.

**No solution is smuggled into the need.** "We need a comparison screen"
is already an answer, and a hypothesis written that way measures whether
the idea was popular instead of whether the problem was real. Write the
claim from the person's side — "buyers cannot compare offers across
suppliers" — and the solutions become alternatives to each other, which
is what the bet's `served_by_any` is for.

Where the statement is sound, say that too, in a clause.

## Choosing the class

Ask how the number will actually be obtained, then check that the class
says the same thing:

| Class | What it is | What it costs each time |
|---|---|---|
| I | an instrument already running produces the number | nothing |
| II | somebody runs an experiment | a piece of work |
| III | interviews, observation, judgement | a person's time |

**Check that the declared measurement can produce a number the threshold
compares against, and say where it cannot.** Class I claims the
measurement is passive and automatic; declared over a quantity nothing
instruments, it produces a hypothesis that will sit unconfirmed until its
term runs out with nothing saying why. This costs nothing to ask now and
surfaces late otherwise — when somebody has to take a measurement that
cannot be taken.

Only class I is affordable to re-confirm continuously. For the other two,
the honest status between measurements is `assumed` with a named owner,
never `supported`.

## Staking a requirement on it

A bet names one requirement and the hypotheses it rests on. Which list a
hypothesis goes in is the whole content of the record:

- `all_of` — needed together. Refute any one and the ground is gone.
- `any_of` — alternatives. The strongest carries the requirement.
- `served_by_any` — competing solutions to the same need.

Two independent sets of alternatives are two bets naming the same
requirement. The checker will ask whether that was deliberate, because
the same shape is what a duplicate looks like.

**Before recording the bet, read the hypothesis back against its own
numbers, and say what you found.** Three of them, together:

- the magnitude the statement claims — "at least three studios in ten";
- the threshold that would refute it — `proportion < 0.25 at n >= 200`;
- the sample that threshold names — 200.

They are meant to differ: the first is what the thing is being built for,
the second is the line below which the claim is false. What they must not do
is disagree by an order of magnitude. "Three in ten" beside
`proportion < 0.025` is a decimal point that moved, and it will pass every
check this layer has, because a record that lost a digit is still consistent
with itself.

This is the cheapest moment there will be. Where the requirement is new,
nothing rests on the claim yet and what follows is requirements and then
code. Where it already exists — a bet recorded after the fact, explaining
why something was built — this is the first time anyone has asked whether it
should be standing there, which is worth more, not less.

Say what you found even when nothing is wrong. One clause is enough, and the
alternative is a step nobody can tell was taken.

**A requirement that exists so the measurement can be taken is marked
`instrument: yes` on its bet** — the event, the cohort tag, the
attribution. It is not a lesser requirement; it is the one that survives
the refutation, and the section below says why.

**Nothing obliges a requirement to be named by a bet, and nothing ever
will.** Where a link is mandatory it gets invented, and an invented link
is worse than an absent one because it looks like knowledge. What may be
asked is a declaration: one record saying this requirement rests on
nothing, and why. It retires itself the moment a real bet appears.

How often that is worth looking at is the dashboard's business: it counts
unclaimed arrivals by period, and **what a period is comes from `period` in
`grounds/grounds-config.json`** — `month`, `quarter` or `year`, and
`quarter` where nothing says otherwise. The dashboard names the unit it used
in that section, so the answer is in front of whoever is reading it.

## When a measurement lands

Append a row to the evidence table. Never edit one: a measurement that
turned out to be wrong gets a later row saying so, because a register
whose inconvenient rows disappear only ever agrees with the present.

The verdict is against `refuted_if`, not against the target magnitude —
see the third judgement above. It is `supported` or `refuted` and nothing
else; the four other words in a hypothesis's `status` are things that happen
to a hypothesis, not things a measurement found.

**Do not write `refuted` because the value crossed the threshold.** A
measurement is the truth plus however far a sample of that size can miss, so
crossing by less than that has refuted nothing. `proportion < 0.25 at n >= 200`
against a measurement of `0.24` on 200 is forty-eight people where fifty were
wanted — two the other way and the hypothesis lives. The checker works the
verdict out and reports the row where the two disagree, so the rule to follow
is simply to write what you believe and let it be checked, rather than
computing an interval by hand.

Where the threshold names a `mean`, nothing works it out: how far a mean can
miss needs the spread behind it and the row carries only the mean and the
sample size. Such a hypothesis cannot be class I, and the verdict is yours to
argue in the rationale.

**Confirmed is not the same as ours.** Admission to the core is a
separate decision and it belongs to the maintainer: absorb it, spin it
off as a second product, or refuse. Put it to them as its own question.
A register that admits whatever confirms has a core that cannot decline
anything, which is the one thing a core is for.

**A refusal is recorded, with its reason and its date.** Without that
record nobody can tell a hypothesis nobody tested from one tested,
confirmed and turned down, and the same argument returns every six
months to be had from scratch.

## When a hypothesis is refuted

The requirements standing on it do not evaporate. They are shipped,
people use them, their data is in the schema. What refutation takes away
is the ground, not the code — and the difference between those two is a
project with a date rather than a deletion.

1. **Read what stood on it.** The bets name the requirements; a
   requirement whose other grounds still hold is not affected.
2. **Settle each one with the maintainer, taking removal as the
   default.** The opposite default is how dead features survive for
   years.
3. **Somebody still uses it is not a reason to keep it.** It is a new
   fact: something other than the refuted hypothesis is holding it up.
   Naming that hypothesis is the price of keeping the code, and where
   nobody will name it, the code goes.
4. **Leave the instruments alone.** A requirement its bet marks as an
   instrument is not put up for removal. It exists to make the
   measurement possible, refutation is that measurement answering its
   question, and the funnel and the attribution are what the next bet
   will be measured with. A project that tears down its measuring after
   every refutation ends up unable to ask anything twice.
5. **Cancel the requirements through the usual procedure**, not by
   deleting them. The specification has one, and this changes nothing
   about it.

## What not to do

- **Do not invent a bet to make a number look better.** The list of
  requirements standing on nothing is the point, not the debt.
- **Do not edit a record to agree with a result.** Everything in the
  register is authored; the dashboard is the one file a machine writes.
- **Do not move a threshold once measurement has begun.** Write a new
  hypothesis and retire the old one, so both stay visible.
- **Do not let an expiry decide anything.** A term running out is not a
  verdict. It says the confirmation is old, and only a measurement can
  say what the status is now.
