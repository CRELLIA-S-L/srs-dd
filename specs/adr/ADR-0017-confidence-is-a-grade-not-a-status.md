# ADR-0017 — Confidence is a grade tied to permitted actions, not a status

- **Status:** accepted
- **Date:** 2026-08-19
- **Related requirements:** FR-BEL-170, FR-BEL-180, IF-BEL-010, IF-SPEC-010

## Context and problem statement

A belief needs to record two different things about itself, and the source
concept does not separate them.

The first is where it stands in its own life: nobody has looked at it yet, it
was accepted on faith, a measurement supported it, a measurement refuted it,
its term ran out, or it was confirmed and deliberately refused admission.
That is a lifecycle, and it is the same kind of thing a requirement's
`status` is.

The second is how much the evidence is worth. Forty thousand users in a
cohort and a dozen conversations both end in the word "supported", and they
do not weigh the same. Worse, the word invites the same decisions from both:
nothing in a binary status stops a pricing change from resting on twelve
interviews.

The concept says both and reconciles neither — one section gives six
statuses including `supported`, another says the binary `supported` is
replaced by a grade. Building either reading alone loses something real.

## Considered options

1. Status only. Six values, confidence carried in prose.
2. Grade only, replacing `supported` and `refuted` with degrees of certainty.
3. Both, orthogonally: `status` for the lifecycle, `grade` for the strength
   of the evidence, with a rule that keys off the grade.
4. Both, plus a numeric confidence score.

## Decision outcome

Option 3, with the rule that makes the grade do work rather than decorate.

**A grade with nothing attached is a label.** The move that makes this worth
building is not the scale but the binding: `beliefs/beliefs-config.json`
carries a map from grade to the actions permitted on it, and an entry whose
declared action is not permitted at its grade is reported. This is taken from
evidence-based medicine, where certainty is rated high, moderate, low or very
low and the guidance is explicit that a strong recommendation should not rest
on low certainty, with the exceptions named rather than left to judgement. A
scale that permits every decision at every level would tell a reader
something and change nothing.

**Option 1 is what the layer exists to improve on.** Confidence in prose is
exactly the rationale problem one level up: present, unchecked, and invisible
to any rule.

**Option 2 loses the lifecycle.** `untested`, `assumed`, `expired` and
`declined` are not points on a confidence scale — they say what happened to
the entry, not how good the evidence is. Collapsing them into a grade means
an untested belief and a well-measured weak one become indistinguishable.

**Option 4 is the version to avoid, and it is the one already in
circulation.** Opportunity solution trees carry a numeric confidence score
per opportunity. A number invites arithmetic it cannot support — averaging
two scores from a cohort and an interview produces a third number that means
nothing — and it does not constrain anything, because 3-out-of-5 permits
whatever the reader wants it to permit. A small ordered set with permitted
actions attached is weaker as a measurement and stronger as a rule, which is
the right trade here.

**Why this is an ADR and not a quiet implementation choice.** ART-040 gives
the boring solution the default win and says a clever one must earn its place
in writing. Two orthogonal axes where the source offers one, and a
configuration-driven map from grade to permitted action, are not the boring
solution. The concept itself flags the transfer as untested. It is being
built because the alternative — a single word that treats a cohort and a
conversation alike — is a known way for a specification to lie quietly, and
this framework already refuses that trade elsewhere.

## Consequences

Two fields where the source concept has one, and a configuration key that
projects will tune. The map is per project because what a low-certainty
belief may be used for is a matter of appetite, not of fact.

The grade is assigned, not computed. Nothing in the register derives it from
sample size or method, and it should not: a large cohort measuring the wrong
thing is not strong evidence. What the checker enforces is the consequence of
the grade, not its correctness.

This is the first candidate for revision once the layer has been used in
anger. The scale is borrowed from a field with centuries of methodology and
a very different relationship to its evidence, and the borrowing is
deliberate but unproven here.
