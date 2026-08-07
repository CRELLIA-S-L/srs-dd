# Installing SRS-DD into a project

The short version lives in the [README](../README.md). This page covers the
modes, the edge cases, and the manual path.

## What the installer does

```
git clone https://github.com/CRELLIA-S-L/srs-dd.git
python3 srs-dd/tools/srs_init.py path/to/your-project
```

It asks for the project name, requirement areas, code and test roots, source
extensions, a CI template, and the lexicon — then copies the specification
skeleton, writes `specs/srs-config.json`, generates a placeholder
requirement, and runs the checker inside your repository.

Non-interactive: add `--defaults`, or pass the answers as flags (`--help`
lists them). `--dry-run` writes nothing at all and prints the exact
created / refreshed / skipped list the real run would produce.

Afterwards: replace the placeholder requirement and commit everything —
including `specs/90-traceability.md`, which is version-controlled on
purpose. CI regenerates it and fails if the committed copy is stale. The
same gate runs locally once you activate the installed hook:

```
git config core.hooksPath .githooks
```

## Modes

The installer detects the mode itself.

**fresh** — no specification in the target: the full skeleton is laid out,
including one placeholder requirement.

**adopt** — an SRS-shaped specification exists but `specs/srs-config.json`
does not. Your spec is validated against the proposed configuration (areas,
lexicon) **before anything is touched**; on failure the target is left
byte-identical (exit 3). Then only the tooling and the missing service files
are installed. Existing specification files are never modified.

**upgrade** — `specs/srs-config.json` exists: see [upgrade.md](upgrade.md).

`--dry-run` in adopt mode skips that validation — it needs the checker
running inside the target, which is a write. The real run always validates
first, so the rollback guarantee is unaffected.

`--mode fresh|adopt` overrides the fresh/adopt detection; upgrade is always
config-driven.

Exit codes:

```
0  installed
1  checker errors in the target, or partial completion past adopt's
   point of no return
2  refused before changing anything (usage, ambiguous target, bad config)
3  adopt rolled back, target untouched
```

## Already running a pre-commit hook?

It is never displaced. The installer looks at what the repository actually
does on commit — `core.hooksPath`, an existing `.git/hooks/pre-commit`,
husky, the pre-commit framework — and when something is already there it
says so instead of advising the `core.hooksPath` switch, which would
silently disable it.

Your hook then calls the gate itself:

```
sh .githooks/pre-commit || exit 1
```

If `.githooks/pre-commit` is itself yours, the gate is installed beside it
as `.githooks/pre-commit.srs-dd`.

## Precious files

CI config, `CLAUDE.md`/`AGENTS.md`, `.gitattributes` and the hook are
"precious": they are refreshed only with `--force`, and only when the
existing file carries the `SRS-DD` marker. A file the installer did not
write is never overwritten.

## Manual fallback

Copy into your repository, by hand:

- `skeleton/specs/` → `specs/` (the starter files), plus `specs/README.md`
  from this repository — the standard itself;
- `tools/srs_check.py`, `tools/srs_view.py` and `tools/srs_upgrade.py`
  (not `srs_init.py`, which stays in the framework repository);
- from `.claude/skills/`: `srs`, `srs-new`, `srs-audit`, `srs-harvest`,
  `srs-upgrade` (not `srs-init` — framework-only);
- `skeleton/AGENTS.md`, `skeleton/CLAUDE.md` → repository root;
- `.gitattributes`, and a CI template from `ci/`.

Then write `specs/srs-config.json` by hand — the keys are documented in the
Configuration section of `specs/README.md`. Add `framework_url` pointing at
the repository you copied from, so `tools/srs_upgrade.py` knows where to go
back to.
