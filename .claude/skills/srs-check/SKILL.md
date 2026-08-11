---
name: srs-check
description: Name and run the checks a finished change calls for — the specification checker, the tests the requirements it touched list in their own fields, and what a person has to look at where the method is not a test. Invoke when the user asks to check, verify or review work before committing, or when a change is finished and nothing has been run yet. Offers; never runs a suite unasked.
---

# Checking a finished change

The specification already knows which checks a change calls for. Every
requirement carries a `verification` method and the paths that verify it,
and nobody reads them for this purpose — so the answer is derived, not
remembered (FR-SKILL-100).

## Procedure

1. **Name what the change touched.** The requirements it names, or, from
   the files it edited:

   ```
   python3 tools/srs_view.py --code <path>
   ```

2. **Read what each of them asks for.** `python3 tools/srs_view.py <ID>`
   prints the method and the `tests` field. Sort them into three lists:

   - **the checker** — always, for every change to `specs/`:
     `python3 tools/srs_check.py`;
   - **the suites** those requirements name in `tests`, and nothing else:
     a change to the viewer does not call for the installer's suite;
   - **what a person has to look at**, where the method is `I` or `D`.
     Say it in words: "FR-VIEW-130 is verified by inspection — open the
     page, follow a link from the dashboard, and see that it lands on the
     card".

   A requirement whose method is `T` with an empty `tests` field is a gap,
   not a check: say so rather than inventing something to run.

3. **Offer, and wait.** Builds and test runs need the user's word each
   time — that is ART-030 of `specs/constitution.md`, not politeness. List
   the commands and ask. Where the project has checks of its own that the
   specification does not name, ask rather than guess.

4. **Run what was approved, all of it,** and report per check: passed,
   failed with the output, or not run and why.

5. **Say what is left to eyes.** The inspection list from step 2 does not
   disappear because the suites are green. A change verified by inspection
   and never inspected is unverified.

## What this procedure does not do

Commit. Decide that a red check is acceptable. Run anything the user did
not approve. Replace the project's own habits — where a project has a gate
of its own, this names what the specification asks for on top of it.
