# ADR-0020 — A widening does not say what it admitted

- **Status:** accepted
- **Date:** 2026-08-23
- **Related requirements:** FR-GND-510, FR-GND-520

## Context and problem statement

The concept the grounds layer is built from gives four mechanisms for a rule that governs the conditions of its own revision.
Two are built: widening the set of admissible arguments is reported (FR-GND-510), and a widening that names no territory is reported as undisclosed (FR-GND-520).
The other two are not, and both stop at the same place.

**Decoupling from the prompt** — an amendment takes effect only after the decision that provoked it closes — needs the register to know what decision was in progress.
It holds records and no decisions.

**The Lakatos check** — a quarter later, somebody looks at whether anyone went to the territory the widening named — needs the register to know that a later record entered that territory.
Nothing connects the two: a bet, a hypothesis or a requirement arrives with no trace of the argument that admitted it.

One missing link, not two.
Both mechanisms want a widening to be able to say what it went on to admit, and no record can say it.

## Considered options

1. Add a key to records naming the amendment that admitted them.
2. Add a column to the amendment table listing what later entered.
3. Report a widening as due for its reading once a period has passed.
4. Build neither mechanism, and say so here.

## Decision outcome

Option 4.

**Option 1 puts the cost on every record to serve one kind.** The key would be optional and therefore mostly absent, and an optional link that is usually missing answers "did anyone go there" with silence in both cases — nobody went, and nobody wrote it down.
What makes the unclaimed list in this layer worth reading is that absence means something (INV-GND-030); a key like this has the opposite property, and adding it teaches the reader to distrust the one place absence already carries information.

**Option 2 is not an addition to the format but a break in it.** The amendment table is declared as four columns and read by position, and a fifth is refused outright — `grounds/00-ideology.md:3 — I-010 carries a table headed
| date | what changed | why | territory it opens | who went there |, and the
format declares | date | what changed | why | territory it opens | for that one`.
`IF-GND-010` promises that a later version may add a key, not that it may widen a table; every amendment written before the change would be refused by the checker until somebody went and added the column to it.
It also asks for a row to be edited long after it was written, which is the habit the evidence table exists to forbid.

**Option 3 ships a warning nobody can clear.** The date and the territory are both in the row, so the timing is computable, and `hypothesis-expired` is precedent for a finding that depends on today.
But an expiry clears when a measurement is recorded; this one would have nothing to clear it, because recording the reading is exactly what the register cannot represent.
A permanent warning is worse than none: it trains the reader to pass over the whole class, and the other findings in that class are the ones that matter.

**So the criterion keeps its human half, and the register supplies the two things a person needs to apply it.** The date the widening happened and the territory it named are both on the record, and FR-GND-520 is what makes sure the territory is there at all.
What the register does not do is notice the quarter passing.
That is a smaller promise than the concept makes, and it is the whole of what a file-based register can keep without inventing a link whose absence would mean nothing.

Phase 4 therefore delivers two mechanisms of four, and the unbuilt two are not waiting for the same thing.
Decoupling from the prompt waits for what this decision is about: a way to say what a widening admitted, which nobody has.
The unchangeable minimum waits for something else entirely — a file no procedure may amend, which a repository cannot offer at all, and which `specs/91-open-issues.md` already records under its own heading.
*Settled 2026-09-21:* it is not waited for. The register makes an edit to a minimum visible, attributable and diffable and never prevents it; preventing it is the forge's and the team's, and the *`I` — ideology* section of `grounds/README.md` says so.
Neither is deferred work waiting for time, and they are not one backlog item.
