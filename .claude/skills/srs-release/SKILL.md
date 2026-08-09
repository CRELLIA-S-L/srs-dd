---
name: srs-release
description: Cut a release of the SRS-DD framework — choose the version with the maintainer, draft the changelog section, then run tools/srs_release.py, which dates the section, bumps the checker and stops — the commit and the tag are the maintainer's, made with whatever git client they use. Invoke when the user asks to cut, publish or tag a framework release. Freezing the specification is a separate act with its own command. Available only in a clone of the framework repository; a target project releases nothing of ours.
---

# Cutting a release

The mechanics are one command. What this procedure is for is the two things
the command will not decide: which number this release carries, and what its
notes say.

## Procedure

1. **Read what changed since the last release.**

   ```
   git log --oneline $(git describe --tags --abbrev=0 --match 'v*')..HEAD
   python3 tools/srs_view.py --diff <newest version in specs/92-baselines.md>
   ```

   The first says what was done since the last release, the second what it
   did to the specification — requirements added, removed, or reworded.
   Read the baseline out of the log rather than out of `git describe`: the
   log is what records a baseline, and a tag for it may never have been
   made (INV-SPEC-040). Where release tags exist, filter for them — `v*` —
   because an unfiltered `git describe` answers with whichever namespace
   came last.

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

4. **Prepare it.**

   ```
   python3 tools/srs_release.py X.Y.Z --dry-run
   python3 tools/srs_release.py X.Y.Z
   ```

   The dry run prints the date and the version bump — the last chance to
   notice that the version is not the one you meant.

5. **Hand the commit back.** The command edits `CHANGELOG.md`,
   `tools/srs_check.py` and the matrix, and stops: it commits nothing and
   tags nothing (CON-SPEC-030). Say which files are staged for the
   maintainer to commit, and that the `vX.Y.Z` tag is theirs to make or
   skip.

6. **Ask whether the specification should be frozen too**, if step 1 showed
   it moved, and follow the `srs-baseline` procedure if so.

   A separate act because the two are independent: a release ships what the
   system does, a baseline freezes what it must do, and neither number
   constrains the other (INV-SPEC-030). Do not assume they share a number
   just because both are being cut today.

7. **Report what is in the working tree, and stop.** Nothing has been
   committed, tagged or pushed — say so plainly, and let the maintainer
   take it from there with the client they use.

## When it refuses

Exit code 2, always before writing anything: no section for that version, a
section that already carries a date, or a checker that does not pass. The
baseline command refuses on the same terms, reading the log instead of the
changelog — a version already logged is one already frozen.

Fix the cause and run it again. There is nothing to clean up: neither
command has touched the history, and running either twice is safe.

## What this procedure does not do

Commit. Tag. Push. Choose the version. Write the notes without showing
them. The first three belong to the maintainer's git client, which may not
be a console at all; the last two are their judgement.
