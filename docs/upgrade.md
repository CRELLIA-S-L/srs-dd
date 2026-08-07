# Upgrading an initialized project

One command, run inside the project:

```
python3 tools/srs_upgrade.py
```

It fetches the framework this project was installed from, prints the version
transition, the upgrade notes for the versions being crossed and the exact
created / refreshed / skipped list — and only then asks. Nothing is written
before you answer. There is no framework clone to keep around and no address
to look up: the one the project was installed from is recorded in
`specs/srs-config.json` as `framework_url`.

An agent working in the project follows
`.claude/skills/srs-upgrade/SKILL.md`, which is the same procedure written
for it.

```
python3 tools/srs_upgrade.py --yes            apply without the prompt
python3 tools/srs_upgrade.py --ref v1.2.0     fetch a specific release
python3 tools/srs_upgrade.py --from ../srs-dd use a clone already on disk
python3 tools/srs_upgrade.py --force          also refresh the precious files
```

Without a terminal to confirm at — a script, an agent session — the command
refuses unless `--yes` is given, and says so. Exit codes match the
installer: 0 installed, 1 checker errors, 2 refused before changing
anything, 3 rolled back.

## What moves and what does not

Refreshed without a flag: the checker, the viewer, the upgrader and the
skills. Tooling has to move with the framework or a project drifts away from
the standard it says it follows.

Left alone: CI configuration, `CLAUDE.md`/`AGENTS.md`, `.gitattributes` and
the pre-commit hook — files a project commonly edits. `--force` refreshes
those too, and only when the existing file carries the `SRS-DD` marker, so a
file you wrote is never clobbered.

The specification is never touched. Requirements are the project's own.

Commit the refreshed tooling together with the regenerated
`specs/90-traceability.md`: a new checker may generate a matrix that differs
from the committed one, and the gate compares them byte-for-byte.

## The long way

The command above is a wrapper around what the framework's installer has
always done, and that path still works when you keep a clone yourself:

```
git -C path/to/srs-dd pull
python3 path/to/srs-dd/tools/srs_init.py path/to/your-project
```

## A gentler path for the agent guides

`CLAUDE.md` and `AGENTS.md` usually carry project-specific content by the
time you upgrade, and `--force` would overwrite it. Run the guided upgrade
instead — the `srs-init` skill, from a framework clone — and the agent
proposes a merge that folds the framework changes in while preserving what
you wrote.

## Version schemes

Three independent numbers exist by design:

| Scheme | Versions what |
|---|---|
| `vX.Y.Z` tags + `CHANGELOG.md` in the framework repository | the framework: checker, viewer, installer, skills, skeleton |
| `spec/vX.Y.Z` tags + `specs/92-baselines.md` in your repository | baselines of your specification |
| The version field in `specs/constitution.md` | your constitution, amended per ART-090 |

Every checker run ends with the framework version your copy shipped with —
`Files scanned: 7. Requirements: 1. No errors. (srs_check X.Y.Z)` — the
first thing to establish when something behaves unexpectedly.
