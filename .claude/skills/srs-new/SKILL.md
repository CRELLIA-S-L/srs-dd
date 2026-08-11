---
name: srs-new
description: Guided interactive authoring of a single new requirement in specs/ — choosing type, area, number, phrasing, and metadata step by step in a dialog with the user. Invoke when the user wants to add a requirement. For the general specification workflow (finding affected requirements, closing the loop after code) use the srs skill; for mining a spec from existing code use srs-harvest.
---

# Authoring a new requirement

Read `specs/README.md` first if you have not in this session — the rules
live there, not here. Read `specs/srs-config.json` for the areas and the
lexicon.

## Dialog

1. **What behavior?** One capability per requirement. If the user
   describes two, say so and split.
2. **Type and area.** `FR`/`NFR`/`IF`/`INV`/`CON`; the area comes from the
   `areas` list in `specs/srs-config.json`. Propose both, let the user
   confirm.
3. **Number.** The next free one in steps of 10 within the area — check
   the target file (see the map in `specs/README.md`).
4. **Statement.** Pick the EARS pattern from the How-to-phrase table in
   `specs/README.md`; use a modal verb from the project lexicon
   (`modal_verbs`) and write in the lexicon's language — the lexicon in
   `specs/srs-config.json` defines the specification language, whatever
   language this skill is written in.

   Then judge what no checker reaches, and say what you found
   (FR-SKILL-120). The checker proves the form: one bolded verb, a
   resolvable link, a status that fits. It cannot tell whether the
   sentence describes **one** capability, whether a reader could
   **confirm** it holds, whether a word like "quickly", "as needed" or
   "where possible" has left it unfalsifiable, or whether it has slipped
   into describing **how** instead of what. No word list can: what
   reads as vague depends on the sentence, and a specification may be
   written in any language. So read it and say so — "this names two
   capabilities, I would split it", or "nothing here says how anyone would
   check it". Where it is sound, say that too, in a clause.
5. **Verification method.** Ask how conformance will be checked
   (`T`/`D`/`I`/`A`). No answer means it is not a requirement yet.

   Then read the statement back against the answer, and say where the
   method has nothing to confirm (FR-SKILL-140). `T` over a sentence no
   test could assert is the usual one, and left alone it surfaces much
   later — when the requirement is built and somebody has to write a test
   that cannot be written. Here the sentence and the method are on the
   table together, which is the one moment the question costs nothing.
6. **Links.** `derives_from` / `depends_on` / `refines` /
   `conflicts_with` — propose candidates from neighboring requirements.
7. **Initial status.** Per the Lifecycle section of `specs/README.md`.
8. **Rationale.** Ask why this way, if the answer is not obvious; write it
   down.

Then write the requirement into the file and run
`python3 tools/srs_check.py`; show the result.

Do not batch-create requirements silently — each one goes through the
dialog.

## Where this ends

At the written requirement, and at the architecture decision if the
discussion settled one — a choice with consequences goes to `specs/adr/`,
and a discussion that settled nothing goes nowhere (FR-SKILL-090).

**Not at the code.** Building it is a separate act, started deliberately;
the `srs` skill is the procedure for that. Authoring that slides into
implementing is why a requirement is born `implemented` in the same commit
as its code, `deferred` never happens, and a baseline can only ever record
what already shipped.

Say what was written, say that it is not built, and stop.
