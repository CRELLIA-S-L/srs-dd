# ADR-0016 — The bet is a record of its own, not fields on a hypothesis

- **Status:** accepted
- **Date:** 2026-08-19
- **Related requirements:** INV-GND-020, INV-GND-030, IF-VIEW-010

## Context and problem statement

ADR-0015 puts hypotheses in a register beside `specs/` and forbids the subsystem from writing into requirement files.
The join therefore has to live on the hypothesis side: a requirement never says what it rests on, so the register says what rests on it.

The join is not a plain list.
A requirement can rest on several hypotheses at once, all of them necessary — if any is refuted the ground is gone.
It can also rest on one of several alternatives, where any one suffices and the strongest carries it.
Both readings are needed, because the reduction that produces "how much of the system stands on refuted ground" is a minimum over the necessary and a maximum over the alternatives, and collapsing them yields a number that is wrong in the optimistic direction.

The cheap encoding is three fields on the hypothesis: the requirements that need it together with others, the requirements it is an alternative for, and the requirements that are competing solutions to it.

## Considered options

1. Three list fields on each hypothesis record.
2. A group label appended to each identifier in the alternative list, so that `FR-CORE-030/g1` and `FR-CORE-030/g2` are two independent alternative sets.
3. A separate flat record — the bet — naming one requirement and the hypotheses it rests on, with the quantifier expressed by which field they sit in.

## Decision outcome

Option 3.

**What kills option 1 is not expressiveness but the exit.** Three fields cover the common case, and this repository's own specification suggests the uncovered case is rare: of 107 requirements, 75 rest on exactly one thing, 20 on nothing, 12 on exactly two, and none on three or more — and two independent alternative sets need at least three grounds to arise.
Nor is the failure silent: a second alternative set cannot be written down at all, so the author meets a missing field rather than a wrong answer.

The problem is what happens if it does arise.
Moving from three fields to a record is a *merge* of keys, and `CONTRIBUTING.md:79-86` is explicit about that case: renaming or withdrawing a key is not compatible, the projects that break are not ours to fix, and "a merge or a split of keys cannot be expressed as a replacement name, so there the note is all the reader gets."
The escape hatch from option 1 is the one migration this framework has no mechanism for.
Choosing it means betting that the case never arrives, with no affordable way to be wrong.

**Option 2 buys correctness by making every edge value a compound.** The identifier stops being an identifier, parsing grows a case, and the standard grows a concept most authors will never use — which is what ART-040 rules out by default, and there is no ADR-worthy gain to set against it.

**Option 3 needs no new concept to express the uncovered case.** Two independent alternative sets are two bet records naming the same requirement.
The reduction is a minimum across the records of a requirement and, within each record, a minimum over the necessary hypotheses and a maximum over the alternatives.
Nesting is not required; group labels are not required; the record *is* the group.

It also gives the join something the field encoding cannot: a name.
A bet has an identifier that survives the hypotheses coming and going underneath it, which is what makes it citable in a review, in a decision, and — the reason this matters most — in a place a developer already looks.

**The one failure mode it introduces, and how it is closed.** Two bet records for the same requirement that were meant to be one silently change a maximum into a minimum.
Nothing about the encoding prevents it, so a rule reports two records naming the same requirement and asks whether it is deliberate.
That turns the only silent case into a loud one and leaves the record with no failure mode the field encoding lacked.

## Consequences

The register gains a third kind of entry, and the hypothesis record loses the three list fields it would otherwise have carried.
A hypothesis says what it claims and how it is measured; a bet says who is standing on it.

The reduction has one input the subsystem cannot see: whether a requirement still exists.
Bets name requirements read through `srs_view.py --json`, so a bet pointing at a withdrawn or absent requirement is detectable and is reported — the register knows the model it points into, which is the whole reason ADR-0015 chose a published interface over parsing `specs/` directly.

Storing the join in one direction only and computing the other is the same rule `INV-SPEC-020` states for requirements.
Nothing in the register records what a requirement rests on; that is derived by reading the bets.
