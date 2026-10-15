# ADR-0053 — The layer describes what a part is made of inside, as a third kind of record

- **Status:** accepted
- **Date:** 2026-10-13
- **Related requirements:** IF-ARCH-110, FR-ARCH-780, FR-ARCH-790, FR-ARCH-800, FR-ARCH-810, FR-ARCH-820, FR-ARCH-830, FR-ARCH-840, FR-ARCH-850, FR-ARCH-860, INV-ARCH-030

## Context and problem statement

The finest grain the layer had was a path: `carries` names files and directories, and `INV-ARCH-020` resolves a file to a part by the specificity of its path.
Every question about encapsulation inside a part — which types it holds, what they have in common, which of them owns a piece of state, what is composed of what — is below a path, and no key could reach it.

Measured on 2026-10-13 against a project that uses the framework: a maintainer asked what the architecture said about the form inside one part, and the layer reported no error and no warning about that part while the form in question was demonstrably wrong.
The silence was structural rather than accidental, which is the shape of a rule that is green forever.

A second force settled the direction: the chain the framework describes runs from the grounds to the requirements to the architecture to the code, and architecture is designed from the current requirements rather than recovered from what was built.
So the grain had to be usable with no code in existence at all.

## Considered options

1. A nested element — express the form as an element inside an element.
2. A block of keys inside the element record.
3. A third kind of record in the layer, with its own identifier.
4. Nothing: declare the inside of a part out of the layer's scope and say so in the standard.

## Decision outcome

Option 3.

Option 1 does not reach the grain at all: an element's carriers are paths, so a nested element describes a smaller directory rather than a type.
Option 2 puts two kinds of claim in one record and makes the inside of a part impossible to design independently — a form could not be `proposed` while its part is `built`, which is exactly the state the grain exists to describe.
Option 4 was the recommendation until the maintainer settled the question: it is cheap and it leaves the original problem unsolved.

The move record set the precedent for a second kind in this layer, and this follows it: one reading requirement that reports a malformed identifier, a missing key and a bad status "as it reports an element's", and one `IF` for the format.

### How it works

A form is `S-<NNN>` in `arch/`, with `status`, `inside` and `requirements` required, and `names`, `shape`, `owns` and `holds` optional.
`inside` names exactly one element — two would make one form answer to both, and the closure of each would read as satisfied.
`requirements` is the join the design is built from.

What closes the design is the same thing that closes the cut one grain up: where a part holds at least one form, every obligation that part carries is answered by one of them.
A built obligation no form answers for is a warning; an approved one no form is designed for is a note, because that is the backlog of the design and every project has one.
Both are conditional on the part holding a form, because the grain is adopted a part at a time: a layer of thirteen parts and no forms would otherwise report every obligation it carries at once, and a rule that fires on every project that has not adopted it is a rule somebody prices to `off`.

Five rules compute from the records alone — the closure in its two prices, a form answering for nothing, one state with two owners, and forms holding each other in a circle — and none of them reads a line of code.
`names` and `shape` are declarations nothing reads yet, which is the position `interface` held before `FR-ARCH-490`: what gives them teeth is a file of facts about the project's symbols, and that is deliberately a later pass.

### Consequences

The layer can now be designed down to the form inside a part before that form exists, and the map groups a part's obligations by the form that answers for each — which is what a part carrying eighty-one of them needed.

Harder: the grain invites a record for every class, which would make the layer a retelling of the code. The standard states the guard — write a form where there is a boundary somebody could cross without noticing, not where there is a class — and `shape-empty` catches the commonest version of the mistake.

Accepted knowingly: `proposed → built` is a person's claim for a form, with nothing able to confirm that its symbols exist, until the facts about symbols land.
