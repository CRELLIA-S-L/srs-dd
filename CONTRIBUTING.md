# Contributing

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

## Version schemes

Three independent version numbers exist by design; do not mix them.

| Scheme | Lives in | Versions what |
|---|---|---|
| `vX.Y.Z` tags + `CHANGELOG.md` | this repository | the framework: checker, installer, skills, skeleton |
| `spec/vX.Y.Z` tags + `specs/92-baselines.md` | each target project | baselines of that project's specification |
| Version field in `specs/constitution.md` | each project | its constitution, amended per ART-090 |

`tools/srs_check.py` prints the framework version it shipped with — the
first thing to ask for when debugging a target project.
