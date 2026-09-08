---
name: srs-new
description: Guided interactive authoring of a single new requirement in specs/ — choosing type, area, number, phrasing, and metadata step by step in a dialog with the user. Invoke when the user wants to add a requirement. For the general specification workflow (finding affected requirements, closing the loop after code) use the srs skill; for mining a spec from existing code use srs-harvest.
---

# Authoring a new requirement

Read `specs/README.md` first if you have not in this session — the rules live there, not here.
Read `specs/srs-config.json` for the areas and the lexicon.

## Dialog

1. **What behavior?**
   One capability per requirement.
   If the user describes two, say so and split.
2. **Type and area.**
   The area comes from the `areas` list in `specs/srs-config.json`.
   Propose both, let the user confirm.
3. **Number.**
   The next free one in the area — check the target file (see the map in `specs/README.md`).
4. **Statement.**
   Pick the EARS pattern from the How-to-phrase table in `specs/README.md`; use a modal verb from the project lexicon (`modal_verbs`) and write in the lexicon's language — the lexicon in `specs/srs-config.json` defines the specification language, whatever language this skill is written in.

   Then judge what no checker reaches, and say what you found.
   The checker proves the form: one bolded verb, a resolvable link, a status that fits.
   It cannot tell whether the sentence describes **one** capability, whether a reader could **confirm** it holds, whether a word like "quickly", "as needed" or "where possible" has left it unfalsifiable, or whether it has slipped into describing **how** instead of what.
   No word list can: what reads as vague depends on the sentence, and a specification may be written in any language.
   So read it and say so — "this names two capabilities, I would split it", or "nothing here says how anyone would check it".
   Where it is sound, say that too, in a clause.

   Two instruments make that judgement cheaper than reading alone.

   **Count the obligations, not the verbs.** One bolded verb passes the checker and says nothing about singularity: a verb carrying a list of objects is as compound as two verbs, and `specs/README.md` says what to do about it under *How to phrase*.
    Read the sentence and say how many things it obliges.
    More than one, and you are writing more than one requirement — say so before the number is chosen, because splitting afterwards spends identifiers that can never be reused.

   **Where conditions combine, draw the decision table.** Causes down the side, effects across, one row per combination that can occur.
    It answers two questions at once: whether the statement is singular — four rows usually mean more than one requirement — and what the tests will have to cover, which is the question step 5 is about to ask.
    Skip it for an unconditional statement; there is nothing to combine.
5. **Verification method.**
   Ask how conformance will be checked (`T`/`D`/`I`/`A`).
   No answer means it is not a requirement yet.

   Then read the statement back against the answer, and say where the method has nothing to confirm.
   `T` over a sentence no test could assert is the usual one, and left alone it surfaces much later — when the requirement is built and somebody has to write a test that cannot be written.
   Here the sentence and the method are on the table together, which is the one moment the question costs nothing.
6. **What is already written.**
   Before the links are chosen, resolve which requirements already speak to this behaviour and what points at those, and say what you found — including "nothing", which is an answer.
   Whatever it turns up is named as `AGENTS.md` asks the first time it appears, from `python3 tools/srs_view.py --cite <ID>…`: a requirement you are about to link to is one you had to open anyway, and the citation is what shows you did.

   ```
   python3 tools/srs_view.py --list --area <AREA>
   python3 tools/srs_view.py --grep <word from the statement>
   python3 tools/srs_view.py --code <path the behaviour touches>
   python3 tools/srs_view.py <ID>          # incoming links: the blast radius
   ```

   The area and the words come from steps 2 and 4; the paths come from wherever the behaviour will live, which the author knows before the `code` field does.
   Two questions are being answered and neither substitutes for the other: whether this is already said somewhere, and what a new obligation lands on top of.
   Filling the link fields from memory answers the first badly and the second not at all.

7. **Links.**
   Propose candidates from what step 6 turned up, for each link field.
8. **Initial status.**
   Per the Lifecycle section of `specs/README.md`.
9. **Rationale.**
   Ask why this way, if the answer is not obvious; write it down.

Then write the requirement into the file and run `python3 tools/srs_check.py`; show the result.

Do not batch-create requirements silently — each one goes through the dialog.

## What it stands on

Only where the project carries a grounds register — a `grounds/` directory beside `specs/`.
Where there is none, skip this and say nothing about it.

The requirement now exists and can be named, so ask once what it stands on.
Three answers, and all three are finished answers:

- **A hypothesis already in the register carries it.**
  Record a bet through `srs-bet`, which reads the hypothesis back against its own numbers first.
- **It rests on nothing anybody wrote down.**
  A `U` declaration says so with a reason, and retires itself the moment a real bet appears.
- **Neither.**
  The commonest answer and a complete one: nothing obliges a requirement to be named by a bet, and a link invented to fill the shape is worse than an absent one because it looks like knowledge.

**The third answer has a loud version, and it is still the third answer.** Where the claim looks worth measuring and no hypothesis carries it, say that and stop there — saying a thing is worth measuring is not recording it.
A hypothesis is written by the person who will answer for measuring it: it needs a bounded population, a threshold, a date and a named owner, and filling in that owner commits somebody who was never asked.
Offer the observation, not the record.

Say which of the three it was.
An unasked question and an answer of "neither" look identical afterwards, and only one of them was a decision.

## Where this ends

At the written requirement, and at the architecture decision if the discussion settled one — a choice with consequences goes to `specs/adr/`, and a discussion that settled nothing goes nowhere.

**Not at the code.** Building it is a separate act, started deliberately;
the `srs` skill is the procedure for that.
Authoring that slides into implementing is why a requirement is born `implemented` in the same commit as its code, `deferred` never happens, and a baseline can only ever record what already shipped.

Say what was written, say that it is not built, and stop.
