# ADR-0007 — Two more skills: checking, and the page

- **Status:** accepted
- **Date:** 2026-08-10
- **Related requirements:** FR-SKILL-100, FR-SKILL-110, FR-VIEW-140

## Context and problem statement

ADR-0006 refused a `srs-build` skill a day earlier, so adding two skills now needs a reason that does not contradict it.

Two things a reader does around a change have no home.
Checking: which checks does this change call for, and who runs them — the specification records a `verification` method and verifying paths per requirement, and nothing reads them for that purpose.
Reading: the rendered page is two commands and a platform-specific path apart, which is exactly what the audience for it will not remember.

## Considered options

1. Sections inside `srs`, as with implementation.
2. Two skills, `srs-check` and `srs-page`.
3. Skills for both, plus the browser command written into `srs-page` rather than into the viewer.

## Decision outcome

Option 2, with the viewer gaining `--open` (FR-VIEW-140).

The reason ADR-0006 refused `srs-build` does not apply here.
That refusal rested on overlap: `srs` has to fire on *any* change of behaviour (FR-SKILL-010), so a second procedure for the same act would compete with it.
Checking a finished change and reading the specification are not that act — they are separate intents, asked for in their own words, and a procedure reached only by opening `srs` in the middle of work is not reached when somebody says "check this before I commit".

The browser command goes into the viewer rather than the skill because the skill is read by an agent and the flag is used by anyone: three platform-specific invocations in markdown help only the reader who already has an agent, while `webbrowser` from the standard library is one line and serves both (ART-040 is satisfied — nothing is added to the dependency list).

Names: `srs-check` takes the framework's own word, next to `srs_check.py`.
`srs-page` takes the word the requirements and the standard already use for the rendered artifact; `srs-gen-spec` was rejected as redundant after `srs` and out of shape with every other skill, and `srs-verify` as promising a certification procedure this is not.

### Consequences

- Two more files in every installed project, and two more names in the first-steps list an install prints.
- The distinction this rests on — one act, one procedure; separate intents, separate procedures — is the test to apply the next time a skill is proposed.
  A proposal that cannot say which intent is its own belongs in `srs`.
- `srs-check` derives what to run from the specification, so a project that fills `verification` and `tests` honestly gets a better answer than one that does not.
  That is a mild incentive in the right direction and a silent failure in the wrong one: a requirement with an empty `tests` field will be reported as having nothing to run.
