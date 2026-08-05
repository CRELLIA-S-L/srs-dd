---
name: srs-new
description: Guided interactive authoring of a single new requirement in specs/ — choosing type, area, number, phrasing, and metadata step by step in a dialog with the user. Invoke when the user wants to add a requirement. For the general specification workflow (finding affected requirements, closing the loop after code) use the srs skill instead.
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
   (`modal_verbs`) and write in the language of the specification. No
   vague words — the statement must be verifiable.
5. **Verification method.** Ask how conformance will be checked
   (`T`/`D`/`I`/`A`). No answer means it is not a requirement yet.
6. **Links.** `derives_from` / `depends_on` / `refines` /
   `conflicts_with` — propose candidates from neighboring requirements.
7. **Initial status.** Per the Lifecycle section of `specs/README.md`.
8. **Rationale.** Ask why this way, if the answer is not obvious; write it
   down.

Then write the requirement into the file and run
`python3 tools/srs_check.py`; show the result.

Do not batch-create requirements silently — each one goes through the
dialog.
