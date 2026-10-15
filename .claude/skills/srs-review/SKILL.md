---
name: srs-review
description: Review a finished change until two consecutive passes find nothing, each reached by a different means than the one before it — the checks the requirements call for, the work read for what no check reaches, every finding confirmed in the file it names before it is reported. Invoke when a change is finished and before a commit is prepared. Building it over passes is the `srs-build` procedure.
---
<!-- Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License -->

# Reviewing a finished change

This is the second judgement. The first was the builder's, and every line of it — the list, the green set, the closed loop — was assessed by whoever wrote the code, which is why `.claude/skills/srs-build/SKILL.md` ends at stable rather than at done.
A clean pass proves that the means you used found nothing. It does not prove there is nothing there, and only another means can tell the two apart.

## Scope

In this order: the change made in this session; what the maintainer named; the uncommitted work (`git status --short`, `git diff HEAD`, and the `??` lines, which no `git diff` shows); the branch (`git diff $(git merge-base HEAD <base>)...HEAD`, with the base confirmed rather than assumed).
Read the work itself, not your memory of writing it — memory misses exactly what you got wrong.

Then the other end, which a review of the diff alone never reaches: `python3 srs-dd/tools/srs_view.py --code <path> --statements` gives the requirements the change belongs to and what each obliges. Reviewing the diff asks whether the code is right; only the statements ask whether it is what was asked for.
A problem elsewhere is a note, not a fix.

## The checks

`.claude/skills/srs-check/SKILL.md` derives them from the requirements the change touched and offers exactly those; nothing runs unasked, which is SRS-DD-ART-030 of `srs-dd/method.md`.
Where a requirement's method is not `T` there is no suite to run and the recorded evidence is read instead: an inspection is a pass of this loop like any other, and a green suite does not finish one.
The first run is also the baseline — a failure in it may stand before the change, and finding out which costs less than a fix nobody asked for.

## Each pass

Announce it in one line — which pass of how many, and what it is about to run or read. The count is the only thing that shows a loop ran rather than a single pass narrated as several.

1. **Run the whole set**, all of it, past the first failure: partial results cost a pass. Then classify every failure before touching it — caused by this change, standing before it, could not run at all, or unsteady, which means it passed and failed against files nobody changed and is confirmed by running it alone two or three times. A check that never ran is never reported as passing.
2. **Read the work for what no check reaches**: a caller the change did not update, an inverted condition, a swallowed error, a path or flag in the documentation that the change moved, a status or a `code` or `tests` field that no longer says what is true, an annotation left behind by a file that moved, a scratch file, a debug print, a credential (SRS-DD-ART-100). And the half only the specification holds: a fix that adds what the statement is silent about means the statement is wrong.
3. **Confirm every finding in the work itself.** Open the file whole, since half of "nothing handles this" disappears once the guard three lines above it is in view; follow the claim through, so that a claim about callers is the output of looking for them; name the trigger — the input, the state or the order that produces it, and no trigger is no finding; run it where you can, because one narrow check costs less than the paragraph you were about to write; and settle whether it stood before the change, from the history, saying the origin is unestablished where there is no history to consult rather than letting it read as damage done here.
   **The wording is the tell.** A finding that holds together only on *could*, *may*, *potentially* or *it is unclear whether* is a suspicion in a finding's clothes. State it as a fact or cut it.
   Drop what did not survive. Do not downgrade it: the note is where an unconfirmed finding goes to survive, and a report that mixes the two is read no more carefully than one that invented everything.
4. **Sort what survived** — blocking, worth fixing, or a note. The first two continue the loop and nothing else does. Which side of a mismatch is wrong is not settled here: that is the maintainer's (SRS-DD-ART-010), and it is a note carrying the options, which reaches `specs/91-open-issues.md` only on their word.
5. **Fix the first two**, minimally, one cause per edit, with no refactoring taken along. **Never weaken a check to get past it** — no deleted or skipped test, no broadened exception, no loosened assertion, nothing priced down to quiet it. A check that is genuinely wrong stays red and the report says why.
6. **Carry the findings into the next pass**, so that nothing is found twice or argued twice.

## Confirming clean

Run one more full pass by a **different means** than the one that just came back clean. Re-reading is not a different means; it is the first one run twice, and it agrees with itself.

Vary the checks: the whole set instead of the narrowed one, the project's pipeline instead of the local commands, a clean state with whatever was cached or built thrown away first, another order or another seed.
Vary the reading, which is a direction and not a second look: from each statement forward into the work, asking whether it is met rather than plausibly met, instead of from the work outward; outward along everything the change touched — the callers, the annotations, every field that names the file; the behaviour run for real, on absent, empty and oversized input and on its failure path; the behaviour deleted to see a check go red; the surviving findings confirmed again against the state as it is now, by another route than the one that found them.
Where nothing else applies, the same means against a clean state. Two consecutive passes that found nothing is the floor either way, and if you cannot name the two means, you have one.

Confirmation is an ordinary pass: it costs budget, and anything blocking or worth fixing that it turns up goes back into the loop, after which the pair starts again. Notes reset nothing.

## Budget

From the measured size of what is under review: one part of up to five files, 4; the ordinary change, 6; twenty files or more, several areas or more than one language, 10. Keep one pass in reserve for the confirmation — spending the last one on a fix leaves the work clean and unconfirmed.

Progress beats the number. What is open strictly decreasing and named: carry on past the ceiling, up to twice it, saying at each extension that you are extending and why. Two passes running that do not reduce what is open: stop at whatever the count, because the rest of the budget will not change it. A number the maintainer set is theirs — at it the work stops and they decide whether it goes on.

## Report

The result and in how many passes of how many, the two means that reached it named; what the checks said, with anything skipped and why; what was fixed; what was not, each with the place and what was seen there; and what could not be checked, with what would answer it.
Every record named to a person is cited at its first mention as `AGENTS.md` asks.
An empty list of what was not fixed beats a padded one, and a problem left out is worse than either.

## What this procedure does not do

Commit — that is `.claude/skills/srs-commit/SKILL.md`.
Change the repository's state: no commit, no branch, no rebase, no reset, no tag; a stash taken to establish a baseline is popped in the same step.
Settle which side of a mismatch between code and statement is wrong.
Author or reword a requirement — that is `srs-new` — and judging whether the listed tests would prove a statement is `.claude/skills/srs-audit/SKILL.md`.
Run anything the maintainer did not approve.
