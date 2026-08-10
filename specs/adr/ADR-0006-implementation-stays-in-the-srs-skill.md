# ADR-0006 — Implementation stays in the `srs` skill

- **Status:** accepted
- **Date:** 2026-08-09
- **Related requirements:** FR-SKILL-090, FR-SKILL-010

## Context and problem statement

Authoring a requirement and building it are separate acts (FR-SKILL-090).
Authoring has a procedure of its own — `srs-new` — and the symmetry invites
a second one for building. The question is whether implementation deserves
its own skill, or belongs where it already lives.

It already lives in `srs`, whose *Order of work* section is the
implementation loop; `srs` also holds three other jobs: orienting from a
file to the requirements describing it, planning work that spans several
requirements, and the standing prohibitions. Separating the acts forces
that section to be rewritten either way.

There is a real gap underneath the question. Both entries into `srs` start
from code: a file about to change. Nothing serves the other direction —
here is an approved requirement nobody has built yet, start from it — which
is exactly the entry the separation of acts creates.

## Considered options

1. Keep implementation in `srs`, and give it a second entry that starts
   from an approved requirement rather than from a file.
2. A new `srs-build` skill, symmetric with `srs-new`, leaving `srs` as
   orientation, planning and rules.
3. Split `srs` fully: orientation and prohibitions stay, implementation and
   planning each become their own skill.

## Decision outcome

Option 1. `srs` says plainly that it is the procedure for building, with
two ways in — from a file, or from a requirement — and hands authoring to
`srs-new`.

Option 2 was rejected because `srs` cannot stop being the general case.
FR-SKILL-010 requires it to fire on *any* change of behaviour, including
one whose requirement does not exist yet; a separate build procedure would
overlap it, and an agent choosing between two procedures for one act picks
wrong half the time. Option 3 multiplies that problem and puts three files
into every installed project where one was enough.

### Consequences

- Nothing new ships. A project that upgrades gets a rewritten `srs`, not
  another skill to learn.
- `srs` stays the largest of the skills, and its four jobs have to be
  visibly separated inside one file — the risk this decision accepts.
- The requirement-side entry is what makes `deferred` a working status
  rather than a label: a specification can now be read for what is approved
  and unbuilt, which is also what gives a baseline something to freeze.
- If the two entries drift far enough apart to read as different
  procedures, that is the signal to revisit this and split after all.
