---
name: srs-build
description: Build over as many passes as it takes — the list of what has to exist written before the first pass, one requirement's worth of change per pass with its tests, the whole set of checks read rather than glanced at, every failure classified before it is touched, and the loop closed in the same set of edits. Invoke when a change will not be finished in one pass, or when a build has begun to go round in circles. One pass through the loop is the `srs` procedure.
---
<!-- Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License -->

# Building over several passes

One pass is `.claude/skills/srs/SKILL.md`: the requirements the change belongs to, the code, the decisions it settled, the loop closed, the checker.
This procedure is what repeating that pass needs, and it begins with the thing a repeated pass loses first — what the work was for.

## Before the first pass

**Write the list of what has to exist when this is over.**
One line per behaviour, each naming a requirement and what it obliges, taken from the requirements in scope and not from the files you expect to touch: a list of files is a plan, and a plan cannot be finished.
A behaviour the task implies and no requirement states is authored first (`.claude/skills/srs-new/SKILL.md`) or declared out of scope on the list itself; building it unwritten is the one thing this procedure will not do.

This list is half the stop condition.
The checks are the other half, and a green set certifies what it covers, which may be a third of the work.

**Say what the work is worth in passes** before the first one, so that running out is a decision and not a surprise.

## Each pass

One requirement's worth of change, with its tests in the same pass: bundled changes hide which one worked.

1. **Build it** — `.claude/skills/srs/SKILL.md`, whole, including the step that closes the loop: the status, the `code` and `tests` fields and the annotations in the same set of edits as the code. A pass that leaves the loop open is a pass somebody does twice.
2. **Run the whole set, not what you touched** — `.claude/skills/srs-check/SKILL.md` derives it from the requirements the change touched and offers exactly that; nothing runs unasked, which is SRS-DD-ART-030 of `srs-dd/method.md`. Fixes break neighbours, which is the reason this repeats at all.
3. **Classify every failure before touching it**: caused by this pass, standing before it, could not run at all — a missing dependency, no network, a tool that is not there — or unsteady, which means it passed and failed against files nobody changed, confirmed by running it alone two or three times. A check that never ran is never reported as passing, and an unsteady one is never quieted by loosening it.
4. **Read the green as a claim too.** A suite that collected nothing, a filter that matched nothing, an assertion in a branch nothing reaches, a test that still passes when the behaviour it covers is deleted. That last one is the check on the test itself, and `.claude/skills/srs-audit/SKILL.md` says what makes it worth running.
5. **Read the documentation on a failure and on a success alike.** On a failure the error says what broke and the document says what was supposed to happen; editing until the message disappears produces something wrong more quietly. On a success read the contract anyway, at the version installed rather than the newest one. Where the change touched the specification, that document is `srs-dd/standard.md` and the standard of whichever layer it touched.
6. **One line of log per pass**: what changed, what the run said, what the document settled, what is still open. At the twelfth pass that line is what stands between you and doing the fourth again.

**Never weaken a check to get past it.** No deleted or skipped test, no broadened exception, no loosened assertion, no rule priced down to quiet it. A check that is genuinely wrong stays red and the report says why.

## When to stop

**Stable is stricter than green**: every line of the list is there and reached by a check, the whole set passes twice running against files nobody touched between the runs — the second time from a clean state, with whatever the checks cached or built thrown away first — and every status, `code` and `tests` field says what is true now.
Stable is the condition for review and not a finished build: every line of it was judged by whoever wrote the code.

**Stop early and report** where the same check fails three times after genuinely different attempts, where a fix brings back something already fixed, where two passes running do not reduce what is open, or where what is left is the maintainer's decision. No further pass clears any of those.

Then hand the work on rather than calling it done: `.claude/skills/srs-check/SKILL.md` for what the requirements themselves ask, and the inspections it names are not finished by a green suite.
What makes it done is the pass somebody else's means reaches — `.claude/skills/srs-review/SKILL.md`, which closes on two consecutive passes that found nothing by different means.

## Report

Against the list, not against the checks: what is there and what is not; what was built, naming each requirement as `AGENTS.md` asks at its first mention; what the checks said, with anything skipped and why; what the documentation settled; what is open, each with where it was seen; and how many passes it took of how many the work was worth.

## What this procedure does not do

Commit — that is `.claude/skills/srs-commit/SKILL.md`.
Author a requirement — that is `srs-new`, and a build that needs one has stopped being a build.
Run anything the maintainer did not approve.
Decide that a red check is acceptable.
