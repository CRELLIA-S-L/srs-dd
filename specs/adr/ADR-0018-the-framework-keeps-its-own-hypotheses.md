# ADR-0018 — The framework keeps its own hypotheses, against its own advice

- **Status:** accepted
- **Date:** 2026-08-19
- **Related requirements:** CON-SPEC-020

## Context and problem statement

The grounds layer's own scope note says it is not worth having where the basis is externally fixed and stable — avionics, a protocol implementation, regulatory compliance — because there the requirement tree suffices and the grounds register becomes empty bookkeeping.

This framework is close to that description.
Its requirements answer to ISO 29148, EARS and MADR, and to engineering judgement about what a specification tool should do.
They are obligations chosen deliberately, not bets on a market.
Read strictly, the layer excludes this repository.

It is being adopted here anyway, and the reason has to be written down or the decision will be reopened every few months by whoever reads the scope note next — which is precisely the failure the register's own `declined` status was invented to prevent.

## Considered options

1. Ship the layer, do not use it here.
2. Use it here, with hypotheses invented to exercise the machinery.
3. Use it here with only the hypotheses that are honestly held, and accept that most will sit at `assumed`.

## Decision outcome

Option 3.

**Option 1 leaves the format untested by its author.** This repository is the only place where the layer can be exercised before strangers receive it, and `IF-GND-010` will promise that a key may be added later but not renamed.
A format that has never held a real entry is a format whose first real entry will want a rename.

**Option 2 is the failure the scope note names**, performed on purpose.
An invented hypothesis has no owner who cares, no measurement anyone will take, and no consequence when it expires.
A register full of those teaches every reader that the register is decoration.

**Option 3 accepts a smaller claim.** The framework does hold hypotheses about people — that an agent handed the specification will follow the procedures rather than improvise, that a maintainer will run the checker without being prompted, that the two-way annotations are worth what they cost.
These are real, they are load-bearing, and almost none of them can be measured from here: the framework has no telemetry over installed projects, and acquiring some would reverse a principle this project holds elsewhere.
What is observable is thin — traffic to the repository, whether the example project stays green — and it is a weak proxy for what matters.

So the honest prediction is that this repository's register comes out mostly `assumed`, class III, with named owners and no instruments.
That is a real test of the record format, of the bet reduction, and of the empty-field protection, and it is **no test at all** of the judgement machinery — the sequential criterion, the grade-to-action map, the reconfirmation rules.
Those are verified by fixtures, which prove their arithmetic, and are accepted only against a project with real users, which proves the prescription fits.

**What the register here is really for.** It is the worked example that anyone cloning the repository sees, and it is the place where an honest `assumed` is demonstrated rather than described.
If, a year from now, this repository's hypotheses are still entirely `assumed` and nobody has missed a measurement, that is not an implementation defect — it is the scope note being right, recorded in a form that can be pointed at.

## Consequences

The framework's grounds register is small and heavy on `assumed`, and that is the intended state, not a backlog.
Nobody should close the gap by inventing measurable-looking hypotheses.

Acceptance of the judgement machinery does not depend on this repository.
It depends on one instrumented pilot with real users, and until that exists the machinery ships as arithmetic that is verified and prescriptions that are unvalidated — stated that way rather than implied.

The layer stays optional here as everywhere else.
This repository enabling it is a decision about this repository, and nothing in the installer treats it as a default.
