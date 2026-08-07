# Contributing

## Local gate (one-time setup)

After cloning, point git at the repository's hooks:

```
git config core.hooksPath .githooks
```

The pre-commit hook runs `tools/ci_selftest.sh`: a YAML parse of the
pipeline and of the templates shipped to target projects, then every
suite in `tests/` — the specification gate, the installer smoke, the
adopt smoke, the viewer smoke. The parse goes first because a suite
fails routinely on a matrix that has been regenerated but not staged,
and that must not hide a broken template.

These are the same scripts `.github/workflows/srs.yml` runs, so the local
gate and CI cannot drift apart, and any suite can also be run on its own:
`tests/adopt-smoke.sh`.

Two things the pipeline does are deliberately not run locally: rendering
the page, which would leave a site in the working tree on every commit,
and the advisory check against the example project, which reaches the
network. Neither verifies anything about this repository.

It takes a few seconds and can be run manually at any time:
`tools/ci_selftest.sh`. The YAML parse needs `ruby` (present on macOS by
default); without it that one check is skipped with a warning while the
suites still run — and CI performs it regardless.

## Framework or payload

Two directories are easy to confuse, and the difference is the one rule
ART-070 of `specs/constitution.md` makes non-negotiable:

- `specs/` — **this repository's own specification.** Requirements here
  describe the checker, the viewer, the installer, the skills and the CI
  templates. Nothing in it is copied into target projects, with one
  deliberate exception: `specs/README.md`, the standard itself, which is
  identical everywhere and therefore kept as a single canonical copy.
- `skeleton/` — **the payload.** Starter specification files and the
  target-facing `AGENTS.md`/`CLAUDE.md`, copied into projects by
  `tools/srs_init.py`. A requirement identifier of ours landing here would
  reach every project installed afterwards and fail its checker on the
  first run.

For the same reason `tools/srs_check.py` and `tools/srs_view.py` — the two
files that travel — never carry `implements:`/`verifies:` annotations:
in a target our requirement areas are unknown, the annotation check warns,
and `--strict` turns that warning into a failed pipeline. Link them from the
requirement's `code` field instead. `tools/srs_init.py`, `tests/` and `ci/`
stay here and may be annotated freely.

## Kinds of change

- **Standard change** — anything that alters `specs/README.md` (the rules,
  the identifier grammar, statuses, annotation syntax) or the checker's
  enforcement of it. Standard changes ship as framework releases: an entry
  in `CHANGELOG.md`, a `vX.Y.Z` tag.
- **Constitution amendment** — follows ART-090 of
  `specs/constitution.md`: a dedicated commit, a version bump, the reason
  in the commit message.
- **Tooling and documentation** — everything else.

## Published entry points

Two things outside this repository point back into it, and both break
silently:

- `.claude/skills/srs-init/SKILL.md` — the raw URL of this file is the
  documented way to hand the framework to a coding agent. Do not rename or
  move it.
- The clone URL and that raw URL live in `README.md`, each marked with an
  HTML comment: `grep -n canonical-url README.md`. They belong on the
  landing page, not in `docs/` — an agent given the repository URL reads the
  README. Changing hosts is a three-line edit; make it in one commit.

## Ground rules

- `python3 tools/srs_check.py --strict` must pass on your branch.
- If your change affects the generated matrix, commit the regenerated
  `specs/90-traceability.md` in the same change set — CI compares it
  byte-for-byte.
- No two sources of truth: if a rule is stated in `specs/README.md`, other
  documents may point at it but must not restate it.
- The tooling stays standard-library-only Python ≥ 3.9 (ART-040).
- A tool that imports another tool sets `sys.dont_write_bytecode = True`
  **before** the import. The loader writes `__pycache__` before a
  module's body runs, so the flag only works in the importer — and a
  cached module is validated by modification time and size alone, which
  a version-string change does not alter. Stale bytecode has already
  made the installer report a version it was not installing.

## Version schemes

Three independent version numbers exist by design; do not mix them.

| Scheme | Lives in | Versions what |
|---|---|---|
| `vX.Y.Z` tags + `CHANGELOG.md` | this repository | the framework: checker, installer, skills, skeleton |
| `spec/vX.Y.Z` tags + `specs/92-baselines.md` | each project, this one included | baselines of that project's specification |
| Version field in `specs/constitution.md` | each project | its constitution, amended per ART-090 |

`tools/srs_check.py` prints the framework version it shipped with — the
first thing to ask for when debugging a target project.
