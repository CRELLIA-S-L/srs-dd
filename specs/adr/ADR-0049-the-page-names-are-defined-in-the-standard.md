# ADR-0049 — The published page names are defined in the standard and copied by each renderer

- **Status:** accepted
- **Date:** 2026-10-06
- **Related requirements:** IF-SPEC-050, INV-SPEC-130, FR-CI-190

## Context and problem statement

Three renderers and three pipeline files need the same three file names: the viewer's page writes links by them, the architecture document's page and the dashboard's page do the same, and a pipeline writes the files themselves.
A name that moved would break all of them at once, so the set has to have one home.

None of the obvious homes is natural. The renderers share two modules — the parser and the checker — and neither has anything to do with where a reader's page lands: the parser is the shape of a requirement, the checker is the judgement over it.
The alternative of a module existing only to hold three rows is a shipped file for a table.

## Considered options

1. A constant in a module all three already import — the parser or the checker.
2. A new shipped module whose only content is the set.
3. The standard defines the set; each renderer carries its own copy; a suite holds the copies to the standard.
4. No canonical home: each renderer names the pages it links and the pipelines name what they write.

## Decision outcome

Option 3.

The set is normative text about what a project publishes, which is what the standard is for, and the first reader of it is a person deciding whether to publish at all — not a reader of code.
Each renderer then carries the two or three names it needs, and `tests/standard-vocabulary.sh` holds those copies to the standard's table, which is the mechanism `INV-SPEC-110` exists for and which this repository already uses for the rule tables of all three standards.

Option 1 was refused because it would put a reader's URL inside the parser or the checker, where nobody looking for it would think to read, and would make every tool that parses a specification carry a fact about HTML pages.
Option 2 buys a canonical import at the price of a file in every target that holds three rows and will never hold more.
Option 4 was refused because a name is then defined nowhere and agreed by accident: the first disagreement is a published page linking a file no pipeline writes, and nothing would report it.

### Consequences

A fourth page is added to the standard first and to the renderers second, in that order, or the suite fails — which is the intended direction.
The check exists only once a renderer carries a copy, so `IF-SPEC-050` stays `deferred` while the standard alone defines the set: a table is what the behaviour will copy, not the behaviour. It becomes `implemented` when the renderers carry the names and the suite holds them to the table.
The names travel to every project with the standard, including projects that keep neither layer and publish one page: the table is a ceiling, and the standard says so.
