# Contributing

## Local gate (one-time setup)

After cloning, point git at the repository's hooks:

```
git config core.hooksPath .githooks
```

The pre-commit hook runs `tools/ci_selftest.sh`: it validates the YAML
of `.gitlab-ci.yml` and `ci/*.yml`, then executes **every**
`.gitlab-ci.yml` job script locally under the runner's shell semantics
(bash, `set -eo pipefail`) — the specification gate, the installer
smoke, the adopt smoke, and the viewer smoke included. It takes a few
seconds and can also be run manually at any time:
`tools/ci_selftest.sh`. Requires `ruby` (present on macOS by default)
for YAML parsing; without it the YAML checks are skipped with a warning.

## Kinds of change

- **Standard change** — anything that alters `specs/README.md` (the rules,
  the identifier grammar, statuses, annotation syntax) or the checker's
  enforcement of it. Standard changes ship as framework releases: an entry
  in `CHANGELOG.md`, a `vX.Y.Z` tag.
- **Constitution amendment** — follows ART-090 of
  `specs/constitution.md`: a dedicated commit, a version bump, the reason
  in the commit message.
- **Tooling and documentation** — everything else.

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
| `spec/vX.Y.Z` tags + `specs/92-baselines.md` | each target project | baselines of that project's specification |
| Version field in `specs/constitution.md` | each project | its constitution, amended per ART-090 |

`tools/srs_check.py` prints the framework version it shipped with — the
first thing to ask for when debugging a target project.
