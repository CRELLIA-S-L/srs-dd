---
name: srs-release
description: Cut a release of the SRS-DD framework — choose the version with the maintainer, draft the changelog section, then run tools/srs_release.py, which dates the section, bumps the checker, logs the baseline, commits and tags. Invoke when the user asks to cut, publish or tag a framework release. Available only in a clone of the framework repository; a target project releases nothing of ours.
---

# Cutting a release

The mechanics are one command. What this procedure is for is the two things
the command will not decide: which number this release carries, and what its
notes say.

## Procedure

1. **Read what changed since the last release.**

   ```
   git log --oneline $(git describe --tags --abbrev=0 --match 'v*')..HEAD
   python3 tools/srs_view.py --diff \
       $(git describe --tags --abbrev=0 --match 'spec/v*')
   ```

   The first says what was done since the last release, the second what it
   did to the specification — requirements added, removed, or reworded.
   Both filter the tag namespace: releases are `v*` and baselines are
   `spec/v*`, and an unfiltered `git describe` answers with whichever came
   last.

2. **Propose the version, and let the maintainer settle it.** The scheme
   is in the Version schemes section of `CONTRIBUTING.md`; read what you
   found in step 1 against it and say which reading you used, out loud —
   "MINOR, because `srs_view.py` gained a flag a project can call".

   Do not settle it yourself. The number is a claim about compatibility,
   and the person who owns the project owns that claim.

3. **Draft the `## [X.Y.Z]` section** in `CHANGELOG.md`, under `### Added`,
   `### Changed`, `### Fixed` and `### Upgrade notes` as they apply. Leave
   the heading **undated** — the command dates it.

   The shape of that section is a contract the installer parses: it is
   stated in the comment at the top of `CHANGELOG.md`, and the ground
   rules in `CONTRIBUTING.md` say what an upgrade note owes its reader.
   Read both before writing — an entry that ignores them still passes the
   checker and reaches the reader in pieces, because an upgrade prints one
   sentence per entry and the notes section alone.

   Name the requirement identifiers the release implements. Show the draft
   to the maintainer before committing it.

4. **Commit everything.** The command refuses on a dirty tree, and rightly:
   a release describes a state, and an uncommitted state is not one.

5. **Cut it.**

   ```
   python3 tools/srs_release.py X.Y.Z --dry-run
   python3 tools/srs_release.py X.Y.Z
   ```

   The dry run prints the row it will log, the date, the version bump and
   the tags. Read the row: it is the specification's own record of this
   release, and it is the last chance to notice that the diff says
   something you did not expect.

6. **Report what it did, and stop.** It does not push — say so, and let the
   maintainer decide when this leaves the machine.

## When it refuses

Exit code 2, always before writing anything: a dirty tree, no section for
that version, a tag that already exists, or a checker that does not pass.
Fix the cause and run it again; there is nothing to clean up.

If it fails *after* writing — a hook rejecting the commit, most likely — it
says what it left in the working tree and how to undo it. Read that message
to the maintainer rather than improvising a recovery.

## What this procedure does not do

Push. Choose the version. Write the notes without showing them. Each of
those is somebody's judgement, and the command is deliberately silent about
all three.
