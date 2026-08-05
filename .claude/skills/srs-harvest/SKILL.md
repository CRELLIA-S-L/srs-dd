---
name: srs-harvest
description: Mine (extract) a specification from an existing codebase — for projects that have code but no requirements yet, or areas of the spec that lag behind the code. Reads the code area by area and proposes draft requirements in approved batches. Invoke when the user wants to build, extract, or backfill a spec from existing code. For authoring a single new requirement use srs-new; for checking existing spec against code use srs-audit.
---

# Mining a specification from existing code

The project is initialized (there is a `specs/srs-config.json`) but the
code holds behavior the specification does not describe. This skill turns
that behavior into requirements — always as proposals, never as decisions.

Read `specs/README.md` first if you have not in this session. Read
`specs/srs-config.json`: the `areas` partition the work, `code_roots`
say where to look, and the lexicon defines the modal verbs and the
**language the requirements must be written in**.

## Procedure

1. **Survey.** Walk the code roots; sketch which parts of the codebase
   map to which areas. Show the user the map and the order you propose to
   work in.
2. **One batch per area.** Read the area's code. For each observable
   behavior, draft a requirement: EARS phrasing in the specification
   language, one bolded modal verb from the lexicon, `status: draft`,
   `verification` chosen honestly, `code` listing the real paths
   (`tests` only when matching tests actually exist — never invent
   them), numbers in steps of 10.
3. **Show the batch to the user BEFORE writing it.** Batching is the
   sanctioned exception to the one-at-a-time rule of `srs-new` — the
   approval-before-write step is what makes it safe.
4. After writing an approved batch, run `python3 tools/srs_check.py` and
   show the result.
5. Repeat per area. Track what remains uncovered; finish with a summary
   of areas done, requirements proposed, and gaps.

## What the draft status means here

Each harvested requirement is `draft` with a filled `code` field, so the
checker warns "implementation ahead of approval" for every one of them —
**that warning list is the approval queue**, by design. Approving, the
maintainer flips the requirement straight to `implemented` (or
`partial`) — the behavior already exists; `deferred` is not part of this
path. Warn the user: a CI gate running `--strict` stays red until the
batches are approved — approve before pushing, or expect a red pipeline.

## Boundaries

- Describe only behavior that is actually in the code — do not invent,
  extrapolate, or "improve" while harvesting.
- Behavior you cannot make sense of goes to `specs/91-open-issues.md`
  (with the user's confirmation), not into a guessed requirement.
- Do not flip statuses yourself — approval is the maintainer's act.
- Do not run builds or tests (ART-030 of the constitution); harvesting
  is reading.
