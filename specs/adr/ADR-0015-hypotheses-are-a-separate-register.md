# ADR-0015 — Hypotheses live in a register of their own, not in a sixth requirement type

- **Status:** accepted
- **Date:** 2026-08-19
- **Related requirements:** FR-GND-010, IF-GND-010, INV-GND-010, CON-GND-010, IF-VIEW-010, CON-SPEC-020

## Context and problem statement

A product's requirements rest on hypotheses about people — who needs the thing, what they will pay for, what they do today instead.
The specification records the obligations and says nothing about the ground under them.
That ground lives in rationale prose, which the standard asks for only "whenever the decision is not obvious" and which no rule checks: delete a requirement's rationale and a strict run reports nothing at all.

An optional subsystem is being added to record those hypotheses as first-class entries with a statement, a way to measure them, a threshold declared in advance, an expiry and a status — so that a hypothesis going stale becomes visible where the code is.

The question this decides is where such an entry physically lives.
It is not a requirement: nobody can build it true.
But it wants the same treatment a requirement gets — an identifier that outlives it, a status, links, a checker that reads it.
The obvious move is therefore to make it a sixth requirement type and let the existing machinery carry it.

## Considered options

1. A sixth `TYPE` — `HYP-<AREA>-<NNN>` beside `FR`, `NFR`, `IF`, `INV`, `CON`, parsed and checked by `tools/srs_check.py`.
2. Reuse an existing type — record hypotheses as `INV-*` or `CON-*` and let the rationale carry what the fields cannot.
3. A register of its own beside `specs/`, with its own format, its own checker, and the requirement model read through the published JSON.

## Decision outcome

Option 3.

**Option 1 breaks every installed checker, and the wall is not a matter of taste.** `TYPES` is a Python constant in `tools/srs_check.py`.
The identifier grammar `RE_ID` is built from it, and a heading that does not match it is appended to `errors` where the requirements are validated — an error, not a rule.
It is absent from `RULES`, so it cannot be lowered in `specs/srs-config.json` and cannot be excused with a requirement's `exempt` field.
Measured rather than reasoned: renaming one heading to `HYP-VIEW-230` in a copy of this repository, with `unknown-key` turned off in the configuration, still produces `error: specs/10-fr-view.md:572 — identifier does not match <TYPE>-<AREA>-<NNN>`.
Adding a type is therefore a framework release that older checkers reject outright, exactly as `withdrawn` was in 0.13.0 — and this time for a subsystem a project may not even want.

The area is the opposite case and worth stating so nobody confuses the two:
`areas` is a configuration key read in `tools/srs_check.py`, and adding one is a single line.
Types are baked; areas are not.

**The deeper objection survives even if the grammar were free.** Every field of the requirement block presumes that the truth of the entry is under the author's control.
`status` says how much of it is built.
`verification` says how conformance is checked.
`code` says where it is realized, and `implemented` without it is an error.
None of that means anything for a statement about the world: `implemented` is not a state a hypothesis can be in, `tests` is the wrong word for a cohort measurement, and there is no `code` because nobody implements a fact about buyers.
A sixth type would be a record that ignores most of the format and needs a parallel set of keys — two schemas in one file format, which `IF-SPEC-010` promises the opposite of.

**Option 2 is worse than either.** It keeps the grammar quiet by lying about what the entry is: an invariant is something the system must never violate, a constraint is something it must not do, and a hypothesis is neither.
The rationale would then carry the threshold, the expiry and the evidence as prose no rule can read, which is the condition this whole subsystem exists to end.

**What option 3 costs and what it buys.** It costs a second format and a second checker, and it means the two can drift.
It buys the thing that decides it: the framework does not change at all.
No new type, no release, no compatibility break, and a project that declines the layer carries nothing extra — the subsystem is removed by deleting a directory.
The requirement model is read through `srs_view.py --json`, whose shape `IF-VIEW-010` publishes: every requirement with the fields of its block, its location, and the reverse links computed for it.
Binding to that is binding to a promise;
binding to the rest of the object is not, and the register does not.

## Consequences

The grounds register is a sibling of `specs/`, not a part of it.
Requirement files are never modified by the subsystem, in any mode, for any reason.

Two formats now exist that look alike on purpose — a heading, a fenced block of flat keys, prose — because an agent that has read `specs/README.md` should recognise the shape without learning a second syntax.
They are not the same format and neither is obliged to track the other's edge cases; the hypothesis standard says so in as many words, so that a later reader does not "fix" the divergence by merging them.

The join between the two — which requirements rest on which hypotheses — cannot live in a requirement file and does not belong in a hypothesis either.
Where it goes is ADR-0016.

Reading the requirement model through a subprocess rather than an import is part of this decision: the register keeps working, and keeps saying something useful, when the specification it points at is broken.
An import would make the optional subsystem die on the mandatory one's configuration before it could report anything of its own.
