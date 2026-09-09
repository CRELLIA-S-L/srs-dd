# ADR-0024 — Frames are a gate, not a field on a requirement

- **Status:** accepted
- **Date:** 2026-08-25 (recorded here on 2026-09-08, from the open-issues entry it replaces)
- **Related requirements:** FR-GND-250, FR-GND-530

## Context and problem statement

The concept this layer is built from gives a requirement a `bounded_by` field — the frames it falls under — and the layer as built has no equivalent.
A frame is what the product will not do whatever the evidence says, so the question the field answers is real: which frames bound this, and what would a frame have refused.

Leaving it out is a decision, and an undocumented decision is indistinguishable from an oversight.
A reader comparing the concept with the record format finds the gap and, finding no note, closes it — adding a key that can afterwards be added to but never renamed or removed (`IF-GND-010`).
That is why this file exists rather than nothing: the reasoning was carried in `specs/91-open-issues.md` until the decision was settled, and an entry with no decision left in it does not belong in a list of open ones.

## Considered options

1. Copy `bounded_by` onto the requirement, as the concept has it.
2. Move it onto the bet, the way `bets_on` and the instrument marker were displaced.
3. No stored link at all: the frames act at admission, and a refusal is a row in the frame's journal.

## Decision outcome

Option 3.

**Option 1 cannot be built here at any price.** Nothing in this layer writes into a requirement file — that is `ADR-0015`, and it is what lets the register be installed beside a specification it does not own.
The field would have had to move to the bet, which is option 2.

**Option 2 buys a field nobody reads.** The dashboard states what each frame has refused from the frame's own journal, and a field with no reader is what the constitution declines by default (`ART-040`).

**Option 3 puts the frames where refusing is cheapest.** `FR-GND-530` puts a hypothesis against the frames before it is admitted, and a frame that refuses one takes a row in its own journal.
That is also the first procedure in the layer that writes into a journal at all, which is what finally lets `FR-GND-250`'s reading of an empty journal tell a frame nobody tested from a frame nobody has.
It binds a person, deliberately: whether a claim falls under a frame is a judgement about meaning, and a frame a checker could match has stopped being a frame.

Until 2026-08-25 this half was worse than manual — it was missing.
`srs-bet` named a frame once, in the list of what the register holds, and asked nothing about frames at any step; `FR-GND-250` was the only requirement mentioning them, and it describes the dashboard.
A hypothesis a frame forbids could be recorded, staked on and built against while the register said nothing.

## Consequences

There is no `bounded_by`, on a requirement or on a bet, and nothing to keep in step with the frames as they are redrawn.
The gate needs no stored link to do its work, and the journal is the record of what it did.

If a reading is ever wanted — which requirements a frame would have refused, or what a frame now touches that it did not when it was drawn — the field goes on the bet and not on the requirement, for the reason above.
It is an addition rather than a rename, so `IF-GND-010` allows it whenever the reader arrives.
