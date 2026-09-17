# 2. Overall description

## Product perspective

A directory of markdown, and the commands that hold it to the code.
The checker validates the specification and generates the traceability matrix; the viewer projects the same data for reading and publishes it as JSON; the installer moves the payload from this repository into somebody else's, and the upgrader fetches a newer framework for a project already carrying one.
Freezing a baseline, dating requirements from the history and preparing a release are three more commands, and each stops before the commit.
They are named rather than counted: a number here is one more thing to keep true, and the count of scripts this sentence used to open with stayed in it long after it stopped being right.

Two layers are optional, and a project that declines one is byte-for-byte a project that was never asked: the grounds register, which records what the requirements rest on, and the architecture layer, which records what the system is made of.
Each has its own standard, its own configuration and its own checker, and a requirement never points into either: the join is written on the layer's side alone, so deleting a layer leaves the specification exactly as it was.

The agent procedures are instructions, not code, and the CI templates are what makes the rules binding in a project that adopts them.

The framework repository is itself an SRS-DD project: this specification describes the tooling in the same form the tooling enforces.

## User classes

- **Maintainer of a target project** — installs, upgrades, and owns the two decisions the tooling refuses to make alone: the requirement areas and the lexicon.
- **Contributor working through an agent** — reads `AGENTS.md` and the skills, and is held to the loop by the checker rather than by review.
- **Reader** — a reviewer, an auditor, or a newcomer, who reads the rendered page and never runs anything.
- **Maintainer of the framework** — bound by this specification and by `constitution.md`.

## Environment

Python 3.9 or newer, git, and a POSIX shell for the test suites.
The CI templates target GitHub Actions and GitLab CI.
The rendered page opens from `file://` with no network access.

## Assumptions and dependencies

- The specification lives in the same repository as the code it describes;
  traceability is expressed as repository-relative paths.
- The traceability matrix is committed, and the working tree is a git repository whenever freshness or baselines are checked.
- Agents read `AGENTS.md` at the repository root, and a project that uses a different rules file points that file at it rather than duplicating it.
- There is no installed base beyond this repository and the example project (2026-08-10).
  A change to the metadata format therefore needs no migration path, and the only pipeline it can break is the example's, which is advisory by design.
  Requirements that exist for the sake of a future installed base — FR-CHK-180 among them — are insurance until this ceases to hold, and the day it ceases is the day they stop being optional.
