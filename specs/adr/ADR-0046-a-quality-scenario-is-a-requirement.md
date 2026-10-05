# ADR-0046 — A quality scenario is a requirement, and a part points at the ones it was cut to keep

- **Status:** accepted
- **Date:** 2026-10-05
- **Related requirements:** FR-ARCH-500, FR-ARCH-510, FR-SKILL-510

## Context and problem statement

A cut is defended by what would be lost if a boundary moved, and the layer had no place for that.
`requirements` is flat — everything a part answers for, in one list that runs to fifty identifiers on the larger parts — so the property a part exists to keep was invisible among the behaviour it happens to hold, and "is this the right cut" had no recorded criterion.
The instrument the literature offers is the quality-attribute scenario of ATAM: a stimulus, the part it arrives at, the response required of it.
`ADR-0045` named its absence here as a gap and left the shape open.

## Considered options

1. A record kind of its own in the layer — `Q-<NNN>`, with a stimulus, a part and a response, beside the element and the move.
2. A free-text field on the element: the quality this part is for, in a sentence.
3. A field pointing at requirements the specification already states.
4. Nothing: the five readings of the design step are judgement enough.

## Decision outcome

Option 3, as `protects`.

**A scenario is a falsifiable property, and this framework already has one place for those.**
"The page stays readable at scale", "validation stays under a second at 500 requirements", "the layer writes nowhere else" are requirements with a verification method, tests and a lifecycle.
A record kind for the same thing would be a second model of one system — the cost `ADR-0023` refused for an external architecture model and `ADR-0045` refused again for a generated one — and the two would disagree the first time a property was reworded in one of them.

**Option 2 would have been prose nothing checks.**
The layer already learned that lesson with `interface`, which was a field nobody read until `FR-ARCH-490` held the code to it. A sentence about quality would have aged the same way, and worse: nothing could tell whether it was still true.

**Option 4 leaves the judgement unrecorded.**
The readings happen once, at design time, and the next person to consider merging two parts has no way to know what the first cut was protecting.

### How it works

`protects` is a subset of what the part carries: an identifier it does not carry is a claim about somebody else's boundary (`protects-uncarried`), and one the specification does not carry at all is an error.
Empty is ordinary and silent, and the procedure says so out loud — a part that holds behaviour and protects no property of its own is the common case, and a key demanded of every record would be answered with invented ones.
The document prints the short list before the long one, because a reader deciding whether a boundary may move needs the answer to what breaks, not the inventory.

### Consequences

Nine of this repository's ten parts named something; `E-100`, its own documentation, named nothing and is right to.
A property reworded in the specification needs no edit here, since the field holds identifiers and the checker resolves them.
What this does not give is the stimulus and the response as separate fields — a reader who wants them reads the requirement, which states them in one sentence, as this specification's own form asks.
