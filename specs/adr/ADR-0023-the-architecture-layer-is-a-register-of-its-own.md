# ADR-0023 — The architecture layer is a register of its own, and its model is written rather than derived

- **Status:** accepted
- **Date:** 2026-09-02
- **Related requirements:** FR-ARCH-010, IF-ARCH-010, INV-ARCH-010, CON-ARCH-010, FR-ARCH-200, IF-VIEW-010

## Context and problem statement

The specification says what the system must do and the register says what that rests on.
What the system is made of is said nowhere a machine can check: `specs/02-overview.md` describes this framework as "three scripts and a directory of markdown" and hands out roles, and nothing compares that sentence to the repository.

Two questions have to be settled before anything is built.
Where does a description of the parts physically live, and where does the declared dependency between two parts come from — is it written by a person or computed from what is already recorded?

## Considered options

1. A sixth requirement type — `ARC-<AREA>-<NNN>` beside `FR`, `NFR`, `IF`, `INV`, `CON`, parsed by `tools/srs_check.py`.
2. A field on the requirement — every requirement names the part it belongs to.
3. A register of its own beside `specs/`, with its own format, its own checker, and the requirement model read through the published JSON.
4. An external model — C4 through the Structurizr DSL, or an equivalent architecture-as-code tool.

For the model itself:

5. Derive the declared dependencies from the requirement graph: two parts depend on each other where their requirements link.
6. Have a person declare them, and compute only the disagreement with the code.

## Decision outcome

Option 3 and option 6.

**Option 1 breaks every installed checker, for the reason ADR-0015 gives at length for hypotheses.**
`TYPES` is a Python constant in `tools/srs_check.py`, the identifier grammar `RE_ID` is built from it, and a heading that does not match is an error rather than a tunable rule.
A new type is a framework release that older checkers reject outright, and this time for a layer a project may decline.

**Option 2 puts the link on the wrong end.**
A requirement would then name a part, so removing the layer would mean editing every requirement, and the specification would carry a field that means nothing where the layer is not installed.
`INV-ARCH-010` records the opposite direction for the reason the register records bets one way: a link written twice diverges, and only one copy is ever updated.

**Option 4 buys a second model of the same system.**
It is an external tool against ART-040, which keeps the tooling standard-library only, and it leaves two descriptions to hold in agreement — the requirement fields and the DSL — with no rule saying which is right when they differ.

**Option 5 was measured, not argued.**
Taking this repository's nine Python modules as parts and deriving an edge wherever requirements of two parts link produced twenty-five edges against the seven the imports actually have: three agreed, twenty-two existed only in the specification graph, four only in the code.
Links between requirements are conceptual — one obligation resting on another — and no transformation turns them into call edges.
So the declared model is authored, and the checker's job is the disagreement, which is the shape Murphy and Notkin's reflexion models have had since 1995: the engineer supplies the high-level model, the tool computes convergence, divergence and absence.

## Consequences

The layer is optional in the way the register is: its own directory, its own standard, its own configuration, its own checker, and `CON-ARCH-010` keeps every command inside it, so declining or deleting the layer costs nothing and leaves no trace.
The specification checker and the viewer learn nothing about it.

The element is not a code module.
Every requirement in this repository has its `code` field filled, and those fields name seven kinds of carrier — tools, procedures, CI templates, standards, payload, specification artefacts — so a layer that could only describe source files would describe less than half of what exists.

Conformance between the declared dependencies and the real ones needs the language of a file read, which is why `FR-ARCH-200` is separate and why it starts with Python only: `ast` is in the standard library, and no other language has a requirement here yet.
The ownership and coverage rules need no language at all, and they are what the first version ships.
