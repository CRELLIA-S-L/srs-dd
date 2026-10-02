# Upgrading an initialized project

One command, run inside the project:

```
python3 srs-dd/tools/srs_upgrade.py
```

It fetches the framework this project was installed from, prints the version transition, the upgrade notes for the versions being crossed and the exact created / refreshed / skipped list — and only then asks.
Nothing is written before you answer.
There is no framework clone to keep around and no address to look up: the one the project was installed from is recorded in `specs/srs-config.json` as `framework_url`.

An agent working in the project follows `.claude/skills/srs-upgrade/SKILL.md`, which is the same procedure written for it.

```
python3 srs-dd/tools/srs_upgrade.py --yes            apply without the prompt
python3 srs-dd/tools/srs_upgrade.py --ref v1.2.0     fetch a specific release
python3 srs-dd/tools/srs_upgrade.py --from ../srs-dd use a clone already on disk
```

Without a terminal to confirm at — a script, an agent session — the command refuses unless `--yes` is given, and says so.
Exit codes match the installer: 0 installed, 1 checker errors, 2 refused before changing anything, 3 rolled back.

## What moves and what does not

Rewritten whole, without a flag: `srs-dd/` — the tools, the standard of the specification and of each layer the project keeps, the method's articles, the framework's guide — and the procedures under `.claude/skills/srs-*`.
Tooling has to move with the framework or a project drifts away from the standard it says it follows.
Inside `AGENTS.md`, only the region between `<!-- srs-dd -->` and `<!-- /srs-dd -->` is rewritten, with the current `srs-dd/guide.md`; everything around it stays as you wrote it.

Left alone: `AGENTS.md` outside the region, `CLAUDE.md`, `.gitattributes`, the pre-commit hook, the pipelines — the project's files, written once as starters; what they hold of the framework is a call to `srs-dd/tools/srs_gate.py` or the region.

A project installed before 0.22.0 is moved into the directory: the tools leave `tools/`, the standards leave `specs/`, `grounds/` and `arch/`, the copies are deleted, and the report after the upgrade says what the hook, the pipelines and the guide now have to call.
The articles of the method that the shipped constitution carried until then — ART-010 to ART-060 and ART-100 — are `SRS-DD-ART-*` in `srs-dd/method.md` now; the copies in your `specs/constitution.md` may be deleted.

Your requirements are never touched: they are the project's own, whatever flag you pass.
Commit the refreshed tooling together with the regenerated `specs/90-traceability.md`: a new checker may generate a matrix that differs from the committed one, and the gate compares them byte-for-byte.

## The grounds register

An upgrade refreshes the register's checker and procedure where the project already keeps one — its standard with it, like the specification's — and installs none of it where it does not.
Nothing arrives through an upgrade that was never asked for — a project that never heard of the layer is not a project that declined it.

To add one to a project that has none:

```
python3 path/to/srs-dd/tools/srs_init.py path/to/your-project --grounds yes \
    --period month
```

`--period` is the calendar unit the register's dashboard counts arrivals in — `month`, `quarter` or `year`.
It is written into `grounds/grounds-config.json` when the register is created and never touched again; omit the flag and it is `quarter`.
To change it afterwards, edit the file.

To be rid of it, delete `grounds/`, `srs-dd/tools/srs_grounds.py` and the `srs-bet` skill.
Nothing else refers to them.

## The architecture layer

The same promise, kept the same way: an upgrade refreshes the layer's checker and procedure where the project already keeps one — its standard with it — and installs none of it where it does not.

To add one to a project that has none:

```
python3 path/to/srs-dd/tools/srs_init.py path/to/your-project --arch yes
```

The layer has two settings in `arch/arch-config.json`, `rules` and `requirements`, and the install asks about neither: every rule starts at its default and the requirements start written, and a project lowers a rule or switches to derived requirements while it is still describing its parts.

To be rid of it, delete `arch/`, `srs-dd/tools/srs_arch.py` and the `srs-arch` skill.
Nothing else refers to them.

## The long way

The command above is a wrapper around what the framework's installer has always done, and that path still works when you keep a clone yourself:

```
git -C path/to/srs-dd pull
python3 path/to/srs-dd/tools/srs_init.py path/to/your-project
```

## The agent guides

`CLAUDE.md` and `AGENTS.md` are yours: an upgrade never rewrites them.
What it rewrites is the region of `AGENTS.md` between `<!-- srs-dd -->` and `<!-- /srs-dd -->`, so the framework's rules stay current while everything you wrote around them stays yours; a guide without the region is reported, with the two lines to add.

## Version schemes

Three independent numbers exist by design:

| Scheme | Versions what |
|---|---|
| `vX.Y.Z` tags + `CHANGELOG.md` in the framework repository | the framework: checker, viewer, installer, skills, skeleton |
| rows in `specs/92-baselines.md` in your repository | baselines of your specification; a `spec/vX.Y.Z` tag on the row's commit is optional |
| The version field in `specs/constitution.md` | your constitution, amended per its own amendment procedure |

Every checker run that reads the specification reports the framework version your copy shipped with — on the summary line, or on the strict failure line — `Files scanned: 7. Requirements: 1. No errors. (srs_check X.Y.Z)` — the first thing to establish when something behaves unexpectedly.
