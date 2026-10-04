# ADR-0043 — The plan is computed and the move is authored

- **Status:** accepted
- **Date:** 2026-10-04
- **Related requirements:** FR-ARCH-350, FR-ARCH-360, FR-ARCH-370, FR-ARCH-380, FR-ARCH-390, FR-ARCH-400, IF-ARCH-050

## Context and problem statement

Correcting a cut is two different acts that had one answer: nothing.
The first is reading what moving from the built parts to the designed ones would require — which files change hands, which obligations change part, which dependencies appear and fall away — and it was done by comparing two records in a text editor, where the files get moved and the obligations and the edges are discovered afterwards.
The second is recording what somebody agreed to do about it.
A redraw outlives the commit that starts it: it is agreed once, carried out over several changes, and read by whoever arrives in the middle of it, and the only trace it left was the elements changing shape commit by commit.

## Considered options

1. Compute the difference only — `--plan` — and let a decision record what was agreed.
2. Record the move only, and let a reader work out the difference themselves.
3. Both, split: the difference computed, the move authored as a record of its own.
4. A move as keys on the element — `moving_to`, `moving_from` on the two parts.

## Decision outcome

Option 3.

**Option 1 forgets.**
A computed difference is true of this minute, and a redraw that takes a fortnight has no memory of what was agreed on the first day; the decision says why the cut changes, which is not the same as which files are still to move.

**Option 2 is the editor again.**
A record of an agreed move cannot say what the move will cost, because that is a comparison across every element and every requirement field, which is exactly what a person does badly and a tool does for nothing.

**Option 4 writes one fact twice.**
The move would belong to the pair of parts, so each end would carry half of it, and `INV-ARCH-010` exists because a link written on both ends eventually disagrees with itself — here it would disagree about whether the move is finished.

So the split is the one the layer already lives by (`ADR-0023`): what a person knows is authored, what follows from the records is computed.

### How it works

`--plan` prints, for every designed part, the files it takes with the part losing each one named, the obligations it takes with their present holder, the dependencies it declares that the built parts do not have, and then the built parts the design empties, whose declared dependencies go with them.
It reports no finding and fails nothing, so the three exit codes of `IF-ARCH-020` stay the codes of a checking run: a designed cut differing from the built one is the normal state of designing, not a defect.

A move is a record with an identifier of its own — `M-<NNN>`, numbered and immutable as `E-<NNN>` is — and the kind is told by the prefix, so both kinds live in whatever files the project keeps them in.
It is held to the readings an element is held to, and to two findings of its own, both read off what the elements at its ends claim rather than off ownership: a move is carried out by editing records, and the receiving part may still be `proposed`.
Every path at the receiving end and none at the leaving one is `move-complete`, which is the state nobody notices; a path at neither end is `move-orphan`, which is a record that cannot be carried out as written.

The `adr` key is required, and only that the specification holds a document named after it is checked — resolved against the document list the viewer publishes, so the layer never learns where a project keeps its decisions. Whether the decision says what the move does is a reading a person makes.

### Consequences

The map grows a section, and only while something is moving: a system mid-redraw is not described by its parts alone, since a part may still carry files it is losing.
A project that records no move reads the map it always did, and the gate that compares the map holds the moves fresh with it.

Two records can now disagree about one redraw — a move saying a file goes to `E-110` and the elements saying it went to `E-120`. That is what `move-orphan` catches, and it is the accepted cost of a record that survives its own execution.

Nothing computes the move from the plan, and nothing closes a move when it is finished: the layer reports and a person edits, as `CON-ARCH-010` requires of everything here.
