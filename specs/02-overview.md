# 2. Overall description

## Product perspective

Three scripts and a directory of markdown. The checker validates the
specification and generates the traceability matrix; the viewer projects the
same data for reading; the installer moves the payload from this repository
into somebody else's. The agent procedures are instructions, not code, and
the CI templates are what makes the rules binding in a project that adopts
them.

The framework repository is itself an SRS-DD project: this specification
describes the tooling in the same form the tooling enforces.

## User classes

- **Maintainer of a target project** — installs, upgrades, and owns the two
  decisions the tooling refuses to make alone: the requirement areas and the
  lexicon.
- **Contributor working through an agent** — reads `AGENTS.md` and the
  skills, and is held to the loop by the checker rather than by review.
- **Reader** — a reviewer, an auditor, or a newcomer, who reads the rendered
  page and never runs anything.
- **Maintainer of the framework** — bound by this specification and by
  `constitution.md`.

## Environment

Python 3.9 or newer, git, and a POSIX shell for the test suites. The CI
templates target GitHub Actions and GitLab CI. The rendered page opens from
`file://` with no network access.

## Assumptions and dependencies

- The specification lives in the same repository as the code it describes;
  traceability is expressed as repository-relative paths.
- The traceability matrix is committed, and the working tree is a git
  repository whenever freshness or baselines are checked.
- Agents read `AGENTS.md` at the repository root, and a project that uses a
  different rules file points that file at it rather than duplicating it.
