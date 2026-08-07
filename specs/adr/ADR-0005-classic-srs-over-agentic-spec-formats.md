# ADR-0005 — A classic SRS, not another agentic spec format

- **Status:** accepted
- **Date:** 2026-08-05
- **Related requirements:** IF-SPEC-010, INV-SPEC-010, NFR-SPEC-020

## Context and problem statement

The framework exists because an agent will change behavior nobody asked for,
and a week later nobody can say whether the code or the intent is wrong. That
problem has an established answer — requirements engineering — and a crowded
new one: a wave of tools that turn a prose "spec" into a prompt and generate
from it.

The two answers disagree about what a specification is *for*. In the second,
the specification is an input to generation, discarded once the code exists.
Here it has to survive the code and outlive the tool.

## Considered options

1. A prompt-shaped specification: prose plans consumed by an agent, in the
   style of the current spec-driven-development tools.
2. An existing requirements-management system — StrictDoc, Doorstop — with
   its own database, identifiers and export pipeline.
3. A classic SRS in plain markdown, following ISO/IEC/IEEE 29148 for the
   structure and attributes, EARS for the statement patterns, and MADR for
   the decision log.

## Decision outcome

Option 3. What the code does is described by numbered, linked requirements
with immutable identifiers and a lifecycle; a change that alters behavior
names the requirement it closes; a script proves the links hold.

Option 1 was rejected because a specification that is only a prompt cannot be
audited later: nothing in it is addressable, so nothing can be shown to have
drifted. Option 2 was rejected on weight — those tools bring a toolchain and
a storage format to projects that want two scripts and a directory of
markdown, and neither was built for a repository where an agent writes most
of the diffs.

### Consequences

- The form is boring and standards-based on purpose: a reader who knows an
  SRS knows this, and a team that already writes requirements can adopt the
  tooling without changing how they think.
- Requirements cost more to write than prose plans. The rules that make them
  worth the cost — singular, verifiable, unambiguous, about behavior — are
  the part no linter can check, which is why `srs-audit` exists.
- Identifiers being immutable and never reused is what makes references
  durable, and is also the constraint that makes areas hard to change later.
- Interoperability stays open: the metadata is a restricted YAML subset, so
  exporting to a tool like StrictDoc remains a parser away rather than a
  migration.
