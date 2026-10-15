# ADR-0042 — A designed part is a status of the element, and ownership is of files

- **Status:** accepted
- **Date:** 2026-10-04
- **Related requirements:** FR-ARCH-310, FR-ARCH-320, FR-ARCH-330, FR-ARCH-340, IF-ARCH-010

## Context and problem statement

The layer recorded the cut a system has, and `ADR-0023` built it as a reflexion model: a person writes the parts, the checker computes the disagreement with the code.
Designing a cut had nowhere to live.
`srs-dd/arch.md` said in so many words not to describe a part that does not exist yet and sent a plan for a different cut to an ADR, while `proposed` sat in the format reading exactly like `built` — every rule treated the two alike, so a designed part's absent files were reported as a stale record and its claim on a file silenced the rule that says no part owns it.

Designing is also where the specification is read from the end the layer never read: a requirement that is approved and unbuilt is precisely what a cut is designed against, and `FR-ARCH-070` looked only at what was realized.

## Considered options

1. A layer of its own beside `arch/` — a target cut and the moves to it, with its own standard, configuration and checker.
2. A key on the element — `designed: true`, or a second list of carriers for where the files will go.
3. Give `proposed` its meaning in the layer that exists, and define what a part owns.
4. Leave designing in ADR prose, as the standard did, and add nothing.

## Decision outcome

Option 3.

**Option 1 buys a second description of one system.**
It is the cost `ADR-0023` already refused for an external model: two files claiming to say what the system is made of, with no rule saying which is right when they differ, and a project would carry the layer twice to design once.
The difference between a designed part and a built one is one word in a record, which is not a register's worth of structure.

**Option 2 adds a key to say what a value already says.**
`status` is the field that says how far along a record is, and `IF-ARCH-010` promises keys are added and never renamed — a `designed` flag beside `status: proposed` would make two fields answer one question, and the first project to set them inconsistently would be right to ask which wins.

**Option 4 is what was there.**
Prose in a decision is not read by any rule, so the completeness of a design — the one thing worth checking before code exists — stayed a matter of somebody remembering.

### How it works

`proposed` is read three ways, and the third is the one that took a rewrite to get right.

Its carriers need not exist (`FR-ARCH-310`): a design names where the files will be, so `carrier-missing` is silent for it, and the exemption's price is `element-built` (`FR-ARCH-330`), which reports a design whose files are all present and whose obligations are all realized — a built part with the wrong status on it.

It owns none of those files (`FR-ARCH-340`), so `carrier-unclaimed` still names a file no built part owns, and the difference between what designs claim and what built parts own is what `--plan` is computed from.

It does answer for the obligations it names.
This is where the first pass was wrong: a statement that a designed part owns neither its files nor its requirements made `requirement-unassigned` (`FR-ARCH-320`) unsilenceable — a design could never be completed, which is the one thing the rule exists to measure.
So ownership is of files, and answering for an obligation is what designing is.
A realized requirement only a design names is then not reported as uncarried; that state is a part built and not yet declared built, and `element-built` is where a reader meets it.

### Consequences

A project that never writes a `proposed` element sees no change at all: every rule reads as it did.
A project that designs gets one list to empty — the approved requirements no part answers for — and one to watch for — the designs that have quietly shipped.

`draft` stays outside the design: it is recorded and not approved, and a part designed to carry it answers for an obligation that may still be reworded or dropped.
The cost is that a project which designs against drafts gets no help here, which is the same line `SRS-DD-ART-020` draws for code.

What a part owns is now a published distinction rather than an implementation detail: files, not obligations.
It is written in the standard, because the three ownership rules read it and a reader who guesses the other way will misread all three.
