# ADR-0030 — An agent guide has a word budget of its own

- **Status:** accepted
- **Date:** 2026-09-24
- **Related requirements:** NFR-SKILL-020, INV-SKILL-010, FR-SKILL-350

## Context and problem statement

`tests/skill-budget.sh` held every shipped procedure and both agent guides to one number of words of their own, 1 300 — where the longest procedure stood after the five longest were rewritten on 2026-09-20.
On 2026-09-23 this repository's `AGENTS.md` stood at exactly 1 300.
The same day `FR-SKILL-350` added a line to it, and `INV-SKILL-010` then required it to carry every rule the shipped guide states — the constitution, the generated files, ART-030, three procedures and more — which took it to 1 497.
The guide had been tuned over many measured runs, so what it already said could not be cut to make room without measuring it again.

## Considered options

1. Raise the one number to about 1 500 for procedures and guides alike.
2. Cut the new lines, or old ones, until the guide fits 1 300.
3. Give the two guides a number of their own, 1 500, and keep 1 300 for the procedures.

## Decision outcome

Option 3.
The number exists to stop a procedure from growing back into an essay, and it does that only while it sits where the procedures stand; raising it for the guide's sake would have given every procedure two hundred words of room nobody asked for, which is option 1's whole cost.
Option 2 trades rules the guide is required to carry, or rules that were measured into it, for a number — the budget would be deciding content instead of guarding it.
A guide is not a procedure in the respect that matters here: every session reads it whatever it was asked, and since `INV-SKILL-010` it must hold everything the shipped guide holds and whatever this repository adds.

### Consequences

- The guide's number stands beside its reason in the test, and raising it is the same visible act as raising the procedures'.
- 1 500 leaves three words of room; the next rule the shipped guide gains is a decision about the number again, not a silent overrun.
- The two guides share the number, and the shipped one stands at about 1 070, so the number is set by this repository's guide, which says more.
