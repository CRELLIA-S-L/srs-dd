# Upgrading an initialized project

To pick up a new framework version:

```
git -C path/to/srs-dd pull
python3 path/to/srs-dd/tools/srs_init.py path/to/your-project
```

The installer prints the checker version transition and the relevant upgrade
notes from `CHANGELOG.md`, then refreshes `tools/srs_check.py`,
`tools/srs_view.py` and the skills. No flags needed.

Precious files — CI config, `CLAUDE.md`/`AGENTS.md`, `.gitattributes` — are
refreshed only with `--force`, and only when they carry the `SRS-DD` marker.
`--dry-run` shows the whole list without touching anything.

Commit the refreshed tooling together with the regenerated
`specs/90-traceability.md`.

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
