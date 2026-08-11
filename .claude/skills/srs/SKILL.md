---
name: srs
description: Working with the project specification (SRS in specs/). Invoke ALWAYS before any code change that alters behavior; when planning any task — including planning a feature, breaking a task into steps, or sequencing work across several requirements; when asked what the system should do; when investigating why something is built the way it is; when changing or cancelling a requirement. For a guided dialog that authors a brand-new requirement, prefer the srs-new skill. Not needed only for changes that do not touch behavior — typos, formatting, comments.
---

# Working with the specification

The project is driven by its specification. System behavior is described in
`specs/` as numbered requirements with links between them and references to
code.

**The markup rules live in `specs/README.md`.** They are deliberately not
restated here: two descriptions of the same rules would eventually diverge.
Read `specs/README.md` if you have not read it in this session.

The specification language follows the lexicon in
`specs/srs-config.json` — statements, titles, and rationales are written
in that language, whatever language this skill is written in.

## First things first

Before changing code, find out which requirements describe the affected
behavior:

```
python3 tools/srs_view.py --code <path/to/file>
```

It answers from the `code` and `tests` fields and from the file's own
`implements:`/`verifies:` annotations; a directory works too. Where that
tool is absent, `grep -rn "<path/to/file>" specs/*.md` and the
“Requirement → code → verification” table in `specs/90-traceability.md`
give the same answer by hand.

Found some — read them in full, together with their `derives_from` and
`depends_on`; `python3 tools/srs_view.py <ID>` prints one requirement
with every link resolved in both directions. When changing a
requirement, the incoming links are the blast radius.

Found nothing — that is not permission to write code silently. It means the
behavior is not described, and a requirement must be created first.

## Two acts, and they are not the same one

Writing a requirement and building it are separate acts (FR-SKILL-090).
Authoring ends at the written requirement and at whatever architecture
decision the discussion settled; building it is a task started
deliberately, later, and often by somebody else. Sliding from one into the
other is how a specification ends up recording only what already shipped —
`deferred` never happens, and a baseline has nothing to freeze but the
past.

This procedure is the second act. For the first, use `srs-new`.

## Building a requirement

There are two ways in, and they meet at step 2.

**From a file you are about to change.** Find what describes it — see
*First things first* above. Nothing found is not permission to write code:
it means the behavior is not described, and authoring comes first.

**From an approved requirement nobody has built yet.** `deferred` is the
status that says so:

```
python3 tools/srs_view.py --coverage
grep -n "status: deferred" specs/*.md
```

Read it in full with its `derives_from` and `depends_on`, and read what
links back to it — `python3 tools/srs_view.py <ID>` resolves both
directions. Incoming links are the blast radius.

Then:

1. **Check the requirement still says what you are about to build.** If it
   does not, you are authoring, not building — stop and go to `srs-new`.
2. **Plans reference numbers.** The work plan says `FR-CORE-050`, not "fix
   the storage layer". The plan must not conflict with
   `specs/constitution.md`; cite its articles (`ART-*`) the same way.
3. **Code.**
4. **Close the loop.** Re-read the statement of every requirement this
   change names: does it describe what you actually built? Whatever it
   does not describe is written down or taken out — not left as a
   surprise for the next reader. A statement you reword here goes through
   the same judgement `srs-new` gives a new one, against the qualities
   `specs/README.md` requires of a statement, and what you find is said
   before the edit is recorded (FR-SKILL-120). This is the easiest place
   to skip it: the requirement already exists, so nothing feels like
   authoring, and a sentence quietly grows a second capability while
   somebody is repairing the first. Then status per Lifecycle,
   `code` and `tests` filled with real paths, and optionally the files
   themselves annotated (`implements:` / `verifies:` — see Annotations in
   `specs/README.md`).
5. **Check:** `python3 tools/srs_check.py`.

Changing behavior — change the requirement in the same set of edits as the
code. They diverge exactly when one moves without the other.

A change that begins as a fix is where this goes wrong most often: repairing
an existing requirement needs no new one, and that exemption quietly covers
whatever else gets added while you are in there. If step 4 finds the
statement silent about something you built, the statement is what is wrong.
And a change that names no requirement at all is its own signal — either
nothing about the system's behavior moved, or the requirement is missing.

## Planning multi-requirement work

For a task that spans several requirements, build the plan from the
specification, not from the code:

1. Resolve the requirements in scope (grep, the matrix), then expand the
   closure: read everything they list in `depends_on`, `derives_from`,
   and `refines`, and check “Incoming links” for the blast radius.
2. Behavior in scope with no covering requirement — the plan's first
   steps author the missing requirements (see `srs-new`); no step may
   change behavior silently.
3. Order the steps so a requirement is implemented only after everything
   in its `depends_on`. Every step cites IDs — and the constitution
   articles that constrain it (“per ART-040”) — and notes the
   requirement's verification method.
4. A `draft` in scope is a blocker, marked so in the plan — code against
   it waits for approval (ART-020). A `superseded` requirement in scope
   is an error; surface it instead of planning around it.
5. Every plan ends with the same two steps: close the loop (status,
   `code`, `tests` in the same edit set) and run the checker. Steps that
   run builds or tests are marked “requires the user's explicit
   confirmation each time” (ART-030).

The plan lives in the conversation. Do not write it into `specs/` or
anywhere else — the specification records what the system does, not the
work queue; and a plan is not approval: statuses are (ART-020).

## Template

The file is chosen by area — see the map in `specs/README.md`. The statuses
and the verbs come from `specs/README.md` and the project lexicon in
`specs/srs-config.json`; the template below shows the default English
lexicon.

````markdown
### FR-CORE-050 — Short one-line title

```yaml
status: deferred
verification: T
derives_from: [FR-CORE-010]
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
```

When `<event>`, the system **shall** `<action>`.

**Rationale.** Why this way and not the obvious alternative.
````

The number is the next free one in steps of 10 within the area. Occupied
numbers are visible in the same file.

## Prohibitions

The list lives in the What-not-to-do section of `specs/README.md` — it is
deliberately not restated here. On top of it, for agents: **do not run
builds or tests without the user's explicit confirmation** (ART-030 of the
constitution).

## Architecture decisions

Choosing a storage engine, rejecting an approach, working around a platform
limitation — that is not a requirement but a decision. It belongs in
`specs/adr/`, following the neighboring files. A requirement answers “what”;
a decision answers “why this path and not the neighboring one”.

## Discrepancies

Found a mismatch between code and a requirement — do not silently fix either
side. Record it in `specs/91-open-issues.md` and tell the user: it is unknown
whether the bug is in the code or in the description, and that is theirs to
decide.
