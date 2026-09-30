---
name: srs-upgrade
description: Upgrade the SRS-DD framework installed in this project — the checker, the viewer, the gate, the skills and, on request, the agent guides. Invoke when the user asks to update or upgrade SRS-DD, to pick up a new framework version, or when the checker reports a version older than the one they expect. Runs tools/srs_upgrade.py, which fetches the framework this project was installed from.
---
<!-- Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License -->

# Upgrading the framework in this project

Everything needed is already here: `tools/srs_upgrade.py` fetches the framework this project was installed from, runs its installer against this repository, and removes what it fetched.
There is no clone to keep around and no address to look up.

## Procedure

1. **Show the change first.**
   Run it without arguments:

   ```
   python3 tools/srs_upgrade.py
   ```

   It prints the version transition, the upgrade notes for the versions being crossed, and the exact created / refreshed / set aside / skipped list — then asks.
   Nothing has been written at that point.

2. **Read the upgrade notes to the user, not just the file list.**
   They are the only place that says what a new version expects of this project.
   Where a note calls for an action here, say so plainly.
   The identifiers in a note are the framework's, not this project's: relay them as written, never through `--cite`, which would find this project's requirement under the same number.

3. **Apply on their word.**
   In a terminal, answer the prompt.
   Without one — an agent session, a script — pass `--yes`, and only after the user has seen step 1:

   ```
   python3 tools/srs_upgrade.py --yes
   ```

4. **Commit the result** together with the regenerated `specs/90-traceability.md`: the refreshed checker may write a matrix that differs from the committed one, and the CI gate compares it.

## What it does and does not touch

Refreshed without asking: the checker and its parser, the viewer, the upgrader itself, the commands that freeze a baseline and date requirements from the history, the checker of any optional layer the project keeps, and the skills.
Left alone: `AGENTS.md`/`CLAUDE.md`, `.gitattributes`, and the standards — `specs/README.md`, plus the standard of any optional layer the project keeps.
All of them are files that may already be the project's own, which is why none is replaced without being asked for.
To refresh those too, add `--force`; it only replaces files that carry the `SRS-DD` marker, so anything hand-written stays.
The pre-commit hook and the pipelines are never rewritten, `--force` or not: they are the project's files, and all they hold of the framework is a call to `tools/srs_gate.py`.

The specification is never touched.
Requirements are the project's own.

## Wiring the gate

The hook and the pipelines are this project's files, never rewritten by an upgrade, and the installer's report — *Pre-commit gate*, *Pipeline gate* — says whether git runs a hook, whether that hook calls `tools/srs_gate.py`, whether any pipeline does, and prints what to add where not.
Read it after every run and add what it prints where the project runs its hooks: a line in a hook of the project's own, a `repo: local` hook in `.pre-commit-config.yaml`, the line in `.husky/pre-commit`, a command in `lefthook.yml` — with `pre-commit install` or `lefthook install` where git runs nothing yet — and a step in a workflow under `.github/workflows/` or a job in `.gitlab-ci.yml`.
Where nothing runs at all, `git config core.hooksPath .githooks` switches the starter on, and only then: the switch turns off whatever ran before.
On a service the installer does not know, read its pipeline and add the step in that service's form.
Done is the report, run again, saying the hook and a pipeline call the gate — or your reading of the step on a service it does not know; a hook git does not run is a gate that looks installed.

## Options worth knowing

- `--ref v1.2.0` — fetch a specific release instead of the default branch, for a project that pins its framework version.
- `--from ../srs-dd` — use a clone already on disk; nothing goes over the network.

## When it refuses

Exit code 2 means nothing was written: no `specs/` beside `tools/`, the framework repository itself, `--ref` given with `--from`, a `--from` path that is no framework clone, no `git`, an unreachable address, or no terminal to confirm at and no `--yes`. Any other code is the installer's own — 1 where the project's checker rejects the result.
Exit 3 means the installer rolled back and the project is untouched.
Both are safe to retry once the cause is fixed.
