# ADR-0009 — The framework never rewrites a specification

- **Status:** accepted
- **Date:** 2026-08-10
- **Related requirements:** FR-CHK-180, IF-SPEC-010, FR-INIT-120

## Context and problem statement

The metadata block is a published contract (IF-SPEC-010), and contracts move: a key gets renamed, two are merged, one is split.
It should not happen, and over enough versions it will.
A project that upgrades into such a version holds a specification the new checker cannot read, with no instruction anywhere about what to change.

Every other artefact the framework ships is replaced on upgrade — the checker, the viewer, the skills.
The specification is the one thing the upgrader deliberately leaves alone.
The question is whether a format change is the exception that earns it the right to edit `specs/`.

## Considered options

1. A migration engine: the framework carries per-version steps, the upgrade offers to run those the transition crosses, with a dry run first.
2. Retired keys known to the checker: the old key is an error naming its replacement and the version that introduced it; the edit is the project's to make.
3. Both: names always, the engine only where a rename cannot express the change.

## Decision outcome

Option 2. The framework reports, and never edits `specs/`.

The specification is the one artefact in an installed project that is entirely the project's own — every requirement in it was written by that team, and nothing the framework ships has ever modified it.
An upgrade that rewrites two hundred requirement blocks, however carefully and with whatever dry run, converts the framework from a tool the project runs into a party that edits its documents; the trust that costs is worth more than the afternoon it saves.

Option 1 also has to be carried forever: a migration step written in 0.14.0 must keep working for a project that upgrades from 0.13.0 three years later, which is a compatibility surface larger than the format it protects.

Against option 3 the argument is weaker but holds: the boundary between "a rename" and "not a rename" would be drawn case by case by whoever writes the change, which is exactly the judgement that erodes.

### Consequences

- A merge or a split of keys cannot be expressed as a replacement name, so it needs an upgrade note that says what to do in words.
  The checker still reports the retired key; the instruction lives in the changelog section, which the installer prints in full on upgrade.
- The work of a rename falls on the project — mechanical, and exactly what an agent or `sed` does well, but on a specification of two hundred requirements it is still a commit somebody has to review.
- The framework keeps a table of retired keys forever, and it only grows.
  That is cheap: a name, a replacement, a version.
- Should a format change one day prove genuinely unrewritable by hand, this decision is what has to be revisited — the option was rejected on cost and boundary, not on feasibility.
