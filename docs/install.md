# Installing SRS-DD into a project

The short version lives in the [README](../README.md).
This page covers the modes, the edge cases, and the manual path.

## What the installer does

```
git clone https://github.com/CRELLIA-S-L/srs-dd.git
python3 srs-dd/tools/srs_init.py path/to/your-project
```

It asks for the project name, requirement areas, code and test roots, source extensions, a CI template, the lexicon, and whether to keep the grounds register — with its period — and the architecture layer — then copies the specification skeleton, writes `specs/srs-config.json`, generates a placeholder requirement, and runs the checker inside your repository.

Non-interactive: add `--defaults`, or pass the answers as flags (`--help` lists them).
`--dry-run` writes nothing at all and prints the exact created / refreshed / skipped list the real run would produce.

Afterwards: replace the placeholder requirement and commit everything — including `specs/90-traceability.md`, which is version-controlled on purpose.
CI regenerates it and fails if the committed copy is stale — and, where a project keeps the layers, the register's dashboard and the architecture map the same way.
The same gate runs locally once you activate the installed hook:

```
git config core.hooksPath .githooks
```

## Modes

The installer detects the mode itself.

**fresh** — no specification in the target: the full skeleton is laid out, including one placeholder requirement.

**adopt** — an SRS-shaped specification exists but `specs/srs-config.json` does not.
Your spec is validated against the proposed configuration (areas, lexicon) **before anything is touched**; on failure the target is left byte-identical, but for a crashed earlier run's temporary copy of the checker, which is removed (exit 3).
Then only the tooling and the missing service files are installed.
Existing requirements are never modified, and a README of the project's own under `specs/` stays where it is: the standard lives in `srs-dd/`.

**upgrade** — `specs/srs-config.json` exists: see [upgrade.md](upgrade.md).

`--dry-run` in adopt mode skips that validation — it needs the checker running inside the target, which is a write.
The real run always validates first, so the rollback guarantee is unaffected.

`--mode fresh|adopt` overrides the fresh/adopt detection; upgrade is always config-driven.

Exit codes:

```
0  installed
1  checker errors in the target, or partial completion past adopt's
   point of no return
2  refused before changing anything (usage, ambiguous target, bad config)
3  adopt refused or rolled back, target untouched
```

## Already running a pre-commit hook?

It is never displaced.
The installer looks at what the repository actually does on commit — `core.hooksPath`, an existing `.git/hooks/pre-commit`, husky, lefthook, the pre-commit framework — and when something is already there it says so instead of advising the `core.hooksPath` switch, which would silently disable it.

No hook is written then — not beside yours either — and your hook calls the gate itself:

```
python3 srs-dd/tools/srs_gate.py --staged
```

The same holds for a hook manager: the line goes into the pre-commit framework's, husky's or lefthook's configuration, and the installer's report says whether it is there.

## The framework's directory

Everything the framework owns in your project is under `srs-dd/`: the tools, the standard of the specification and of each layer you keep, the articles of the method (`srs-dd/method.md`), the framework's guide (`srs-dd/guide.md`) and the licence.
The installer rewrites the files it owns there on every upgrade and refuses to install where a `srs-dd/` of somebody else's already stands.
Nothing of yours goes there, and a path of yours it finds under the directory is named in its report and left alone — it deletes nothing it did not write.
Everything else is yours: the hook, the pipelines, `CLAUDE.md`, `.gitattributes` and `AGENTS.md` are written once as starters and never again — except the region of `AGENTS.md` between `<!-- srs-dd -->` and `<!-- /srs-dd -->`, which holds the framework's rules and is rewritten in place by every upgrade so that every agent reading the file has them.
The procedures under `.claude/skills/srs-*` are the framework's as well, refreshed with the tooling; a procedure of your own takes another name.
A constitution is yours to write: the framework ships none, and `specs/constitution.md` holds your own articles under numbers you allocate, changed as `SRS-DD-ART-130` says. The articles of the method are `SRS-DD-ART-*` in `srs-dd/method.md` and arrive with every upgrade. One to copy if you want a start:

```markdown
# Constitution

Standing engineering principles of this project. Every plan and every diff is checked against them.

- **Version:** 1.0.0
- **Ratified:** <the day you adopt it>

## ART-010 — <your first principle>

<what it obliges, in a sentence or two.>
```

## Manual fallback

Copy into your repository, by hand:

- `skeleton/specs/` → `specs/` (the starter files), plus `specs/adr/template.md` from this repository — the decision template, kept in one copy;
- `srs-dd/` whole — `README.md`, `LICENSE`, `standard.md`, `method.md`, `guide.md` and the tools below;
- `srs-dd/tools/srs_check.py`, `srs-dd/tools/srs_parse.py`, `srs-dd/tools/srs_view.py`, `srs-dd/tools/srs_view_model.py`, `srs-dd/tools/srs_view_page.py`, `srs-dd/tools/srs_upgrade.py`, `srs-dd/tools/srs_baseline.py`, `srs-dd/tools/srs_dates.py` and `srs-dd/tools/srs_gate.py` — the checker imports the parser from beside itself, so the two travel together, and the gate is what the hook and the pipeline call (not the framework-only tools — the installer, the release command, the two measurements and the local gate — which stay in the framework repository);
- from `.claude/skills/`: `srs`, `srs-new`, `srs-audit`, `srs-harvest`, `srs-upgrade`, `srs-baseline`, `srs-check`, `srs-page`, `srs-commit`, `srs-build`, `srs-review` (not `srs-init` or `srs-release`, which are framework-only);
- to keep an architecture layer as well — what the parts are and what each carries — also `skeleton/arch/` → `arch/`, plus `srs-dd/arch.md` from this repository, `srs-dd/tools/srs_arch.py`, `srs-dd/tools/srs_arch_doc.py` and the `srs-arch` skill.
  The skeleton carries no `arch/arch-config.json` either: write it as `{"rules": {}}`.
- to keep a grounds register as well — the hypotheses the requirements rest on — also `skeleton/grounds/` → `grounds/`, plus `srs-dd/grounds.md` from this repository, `srs-dd/tools/srs_grounds.py` and the `srs-bet` skill.
  All of it or none of it: the checker, the standard and the procedure only make sense together.
  Declining costs nothing and leaves no trace.
  The skeleton carries no `grounds/grounds-config.json` and there is none to copy: write it yourself as `{"rules": {}, "period": "quarter"}`, where `period` is the calendar unit the dashboard counts arrivals in — `month`, `quarter` or `year`, a choice about your project's rhythm rather than a default worth inheriting;
- `skeleton/AGENTS.md`, `skeleton/CLAUDE.md` → repository root;
- `.gitattributes`, and a CI template from `ci/`.

Copied by hand, the tooling arrives as it is written here: with this framework's `implements:`/`verifies:` annotations and `srs-end:` markers still in it, and with `SRS-DD-VERSION` in each header where the installer would have put the version.
Neither breaks anything while your `code_roots` leave `tools/` out, which the default does.
Where you do put `tools/` on your code roots, either run the installer instead — it removes them — or take those lines out yourself.

Then write `specs/srs-config.json` by hand — the keys are documented in the Configuration section of `srs-dd/standard.md`.
Add `framework_url` pointing at the repository you copied from, so `srs-dd/tools/srs_upgrade.py` knows where to go back to.
