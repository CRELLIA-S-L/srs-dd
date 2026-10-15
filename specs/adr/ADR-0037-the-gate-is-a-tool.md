# ADR-0037 — The gate is a tool of ours, and the hook and the pipelines that call it are the project's

- **Status:** accepted
- **Date:** 2026-09-30
- **Related requirements:** FR-CI-180, FR-CI-020, FR-CI-050, FR-INIT-080, FR-INIT-280, FR-INIT-290, FR-INIT-300, FR-INIT-310, FR-SKILL-410, FR-SKILL-420, FR-CI-010, FR-GND-310, FR-GND-370, FR-GND-570, FR-ARCH-170, FR-ARCH-300, FR-CI-150, FR-INIT-060, FR-INIT-270

## Context and problem statement

The gate — run the checker and, where the project keeps them, the register's and the layer's; regenerate what each writes; refuse while a generated file differs from what git holds — was written three times: in the pre-commit hook and in each CI template.
Those files were copied into a project with the framework's marker and refreshed with `--force` (`FR-INIT-060`), so every change to the gate reached a project as an upgrade note asking somebody to edit a file by hand, as 0.21.0's did for the hook.

They are also not ours to refresh.
A project runs every pre-commit check it has through one hook, and in GitLab every job through one `.gitlab-ci.yml`; once the project has added its own lines, a refresh rewrites them, and the notice of whose a file is (`FR-INIT-280`) cannot stand in a file that is the project's.

## Considered options

1. Keep the steps in the hook and the templates, owned by the framework and refreshed with `--force`.
2. Move the steps into a tool, and keep the hook and the templates as the framework's, reduced to a call.
3. Move the steps into a tool; treat the hook and every pipeline file as the project's — written once as a starter where there is none, never written again — and have the installer report whether they call the tool, and the installing procedures wire it in.

## Decision outcome

Option 3.
Option 1 is the problem.
Option 2 still claims the one file through which a project runs all its hooks, and the one through which GitLab runs all its jobs; a notice of ours in either would claim the project's file.
Under option 3 all that is ours in a project's hook or pipeline is a call, and a call needs no refresh: the gate moves with the tooling (`FR-INIT-270`), and the tool carries the notice.

The tool is Python, like the checkers it runs, rather than a shell script beside them — a second language gains no reach the checkers do not already need — and it is a tool of its own rather than a flag of the specification's checker, which today knows nothing of the two optional layers.

### How it works

`srs-dd/tools/srs_gate.py` holds one list: each checker, the file it writes, and the configuration that says the project keeps it — none for the specification, which every project keeps.
For each entry whose configuration is there it runs the checker, `--strict` passed on when given; a checker that fails stops the gate with its own exit code.
Only when every checker has run does it compare: a generated file is stale when git does not hold it, or when the copy on disk differs from the one in the index.
In a pipeline's fresh checkout the index is the commit, and before a commit it is what is staged, so one comparison serves both; every stale file is named in one refusal, and the gate exits 1.
Without `--staged` it also prints each stale file's difference, for a pipeline's log read after the fact; with it, and only once the comparison has passed, it asks the register what the staged files' requirements are staked on — a report that never fails the commit.
The list is also what the shipped `.gitattributes` has to pin to LF (`FR-CI-150`), and the suite that checks the pinning reads it from the tool.
It stops working outside a git repository, and says so with exit 2.

The installer writes `.githooks/pre-commit`, `.github/workflows/srs.yml` or `.gitlab-ci.yml` as a starter only where the file is absent, and where something else already runs on commit it writes no hook at all (`FR-INIT-080`).
After every install and upgrade it reports whether git runs a pre-commit hook, whether that hook or the configuration of the manager running it calls the gate, and whether any GitHub workflow or the GitLab file does, saying what to add where not (`FR-INIT-300`, `FR-INIT-310`).
The installing procedures take it from there: they tell the agent how to add the call for each way a project runs its hooks and each service it runs pipelines on, and to confirm it from the report or, for a service the installer does not recognise, by reading the pipeline (`FR-SKILL-410`, `FR-SKILL-420`).

### Consequences

A change to the gate reaches every project with the next upgrade, without `--force` and without a note.
The installer never rewrites what a project added to its hook or its pipeline.
A project installed before keeps its hook, its pipelines and any `.githooks/pre-commit.srs-dd`, which still work — they call the checkers the tool calls — and are no longer refreshed even with `--force`; the report names them as not calling the gate, and replacing their steps with the call is the agent's, through the procedure.
Whether the gate runs now rests on a line the project keeps, which is why the report is made on every install and upgrade rather than once.
