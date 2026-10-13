---
name: srs-commit
description: Prepare a commit of finished work — hand it to the check procedure, establish what the message covers, put the generated files in the index, read the diff including untracked files, and write the message with the requirement identifiers the change implements. Invoke when a change is finished and a commit is the next step. It commits nothing itself: the commit is made with whatever git client the project is driven by.
---
<!-- Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License -->

# Preparing a commit

The commit is the maintainer's act.
This procedure is everything that has to be true before it: that the work was checked, that the message covers what is actually being committed, and that what the gate compares is in the index.

## Procedure

1. **Check it first.**
   `.claude/skills/srs-check/SKILL.md` derives what the change calls for from the requirements it touched and offers exactly that; it runs nothing unasked, which is SRS-DD-ART-030 of `srs-dd/method.md`.
   A commit is the moment after which a red check stops being yours.
   Where that procedure already ran in this session and nothing has changed since, say so rather than running it again; where anything was edited after it finished, it runs again.

2. **Establish what is being committed.**

   ```
   git status --short
   git diff --cached --stat
   git diff --stat
   ```

   `git status --short` is the only one of the three that shows an untracked file, and a change that is mostly new files is invisible in a diff: take the new files from its `??` lines and read them directly.
   Where anything is staged, ask whether the message covers the staged set alone or everything uncommitted, show both sides with their file counts, and wait — a message describing the wrong set is found out only after the commit exists.
   Where a merge, rebase or cherry-pick is in progress, stop and say so: that commit needs a different message.

3. **Put the generated files in the index.**

   ```
   python3 srs-dd/tools/srs_gate.py
   ```

   It runs what the hook runs, and it compares every generated file with what git holds rather than with the working tree: `specs/90-traceability.md`, and `arch/90-map.md` and `grounds/90-dashboard.md` where the project carries those layers.
   A file regenerated and left unstaged is the commonest refusal there is — `git add` the path it named, then run the gate again.
   Never reach for `--no-verify`, and never pipe the commit into anything: the exit code of a pipeline belongs to its last command, so a hook's refusal read through `grep` looks exactly like a commit that was made.

4. **Read the diff, not your memory of the work.**
   `git diff --cached`, or `git diff HEAD` where the message covers everything, plus the untracked files in full.
   Writing from intent is how these go wrong: the message says what was meant to happen, the diff is the only witness anyone consults later.
   Take out of it what the message owes its reader — the behaviour that changed, a contract broken for its callers, a migration, a new configuration key, anything deliberately left out or hardcoded.
   Flag, rather than describe, what should not be committed at all: a credential or anything else SRS-DD-ART-100 keeps out of a repository, a scratch file, a debug print, an edit that landed in the wrong file.

5. **Write the message.**
   An imperative title; a body of plain sentences where there is something to say and none where there is not; and the requirement identifiers the change implements, bare, in a trailing parenthesis.
   SRS-DD-ART-060 asks the commit or the pull request for them, and this is the one place a record is named by its number alone: everywhere else `AGENTS.md` asks for the title, the file and the status, and here a citation would break the line, because a tool that prints a changelog or a log prints such a line whole.
   The identifiers are the ones the change was planned from, not the ones a search turns up afterwards.
   Write it in English whatever the language of the conversation, and name no tool, agent or session in it.

6. **Hand it back.**
   Say which files are waiting, what the checks reported, and anything flagged in step 4; then give the message and stop.
   Nothing is committed, pushed or tagged here, and the maintainer takes it from there with the client they use — which may not be a console at all.

## What this procedure does not do

Commit.
Push.
Tag.
Stage anything but the generated files the gate compares.
Decide that a red check is acceptable, or weaken one to get past it.
