# ADR-0031 — A counterpart is held to its shipped file by two instruments

- **Status:** accepted
- **Date:** 2026-09-24
- **Related requirements:** INV-SKILL-010, FR-SKILL-300, NFR-SKILL-020

## Context and problem statement

`INV-SKILL-010` requires this repository's `AGENTS.md`, `CLAUDE.md` and `.githooks/pre-commit` to hold every rule their shipped counterparts state.
The two files of a pair are written for different readers and in different words, so neither equality nor a diff can check them.
A rule reaches a guide by two roads: a requirement whose `code` field names the guide, or a sentence the constitution or the standard put there with no requirement behind it — two of the rules the root guide lacked on 2026-09-23, the generated matrix and ART-030, were of the second kind.

## Considered options

1. A list of literal tokens per pair, each found in both files, on the pattern of `tests/skill-instructions/`.
2. A check over the specification: a requirement naming the shipped file in its `code` field names the counterpart too.
3. Both.

## Decision outcome

Option 3.
Option 2 alone misses every rule no requirement carries, which is how the two missing rules went unnoticed.
Option 1 alone catches a rule only once somebody adds its token, and the author of a new requirement adds a line to the shipped guide, not to a list in `tests/`; option 2 catches that rule on the day the requirement is written, with no list to remember.

### How it works

`tests/guide-parity.sh` takes the pairs from a table at its top — counterpart, shipped file, token list.
For each pair it reads the list in `tests/guide-parity/`, one literal per line, and reports every token either file does not contain as written; an empty list is itself reported.
It then reads every `### ID — title` section under `specs/`, takes the `code` field inside that section only — so a heading without one never borrows the next block's — and reports a requirement naming a shipped file but not its counterpart, unless the requirement is in the test's table of exceptions (ADR-0032).
Last, it asks the installer which files it ships and reports the decision template if it is not shipped from `specs/adr/`, or if a copy of it stands in `skeleton/`.
Before any of that it builds a lab with each kind of failure and asserts that each one is reported, so that a green run over the repository means something.

What it keeps: a token is a substring, so a token is found inside a longer phrase and a sentence reworded around it still passes — the list proves the rule is still named, and a person reads whether the sentence still asks for it.
Where it stops working: a rule that is neither in a requirement's `code` field nor in a list is invisible to it.

### Consequences

- A list to maintain, as `tests/skill-instructions/` already is; a rule added to a shipped guide without a requirement needs its token added by hand.
- A new pair — a third file the framework ships and this repository keeps its own of — is a row in the table and a list.
