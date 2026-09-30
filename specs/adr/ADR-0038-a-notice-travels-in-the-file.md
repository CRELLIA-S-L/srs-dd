# ADR-0038 — A notice of whose a file is travels in its first lines, in one form for every kind of file

- **Status:** accepted
- **Date:** 2026-09-30
- **Related requirements:** FR-INIT-280, FR-CI-170, FR-INIT-290, FR-INIT-060, FR-INIT-240, FR-CI-100, NFR-SKILL-020

## Context and problem statement

The licence asks that its notice travel with every copy, and the installer copies files one at a time: a tool lifted from an installed project carried the framework's name and version and nothing about whose it was or on what terms (`FR-INIT-280`).
This repository's own code had the same gap once a file left it, and a rule stated for contributors holds until the first file somebody forgets (`FR-CI-170`).
The notice has to be in the file, and it has to be the same thing in a Python tool, a shell suite, a YAML pipeline, a skill with a YAML front matter and a markdown standard that a project may edit into its own.

## Considered options

1. A `LICENSE` copied beside the tools into every target, and nothing in the files.
2. A full licence header — the MIT text — in every file.
3. One line naming the holder, the framework and the licence, placed in the file's first lines in the comment form the file's kind has: `#` in Python and shell, `<!-- -->` in markdown after the front matter or the marker.

## Decision outcome

Option 3.
Option 1 says nothing about a file copied on alone, which is the case the licence's clause is about.
Option 2 puts twenty lines above every tool and, in a skill, into what every session reads and the word budget counts (`NFR-SKILL-020`); the licence's own text is one `git clone` away and the line names it.
One line, one wording, and a gate that reads the first lines: a notice past line twelve is one nobody sees.

### How it works

The line is `Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License`, as a `#` comment after the shebang and the coding line in Python and shell, and as an HTML comment in markdown — after the front matter in a skill, after the marker line in a standard.
`tests/notice.sh` walks the same files as the width gate (`FR-CI-100`) less the starters under `ci/`, reads the first twelve lines of each and refuses any where no line carries both the holder and the licence; it negates itself first on a lab of three files.
The installer copies the line as part of the file, so what a target gets is what this repository keeps; the standards are compared without their marker's version (`FR-INIT-240`), and the notice is not a marker, so it neither makes a file ours nor stops one from being the project's.
Where the notice would claim somebody else's file — the hook and the pipeline starters (`FR-INIT-290`), the agent guides, the skeleton specification, the decision template — there is none, and the installer's suite asserts the absence as it asserts the presence.

### Consequences

Every tool, skill and standard says whose it is wherever it ends up, and a file added here without saying so is refused before it is committed.
A skill costs twelve more words of its budget, and the register's standard pushed `srs-bet` past the transitive ceiling by fourteen; the ceiling moved, with the reason beside it.
The year in the line is the year the notice was written; nothing updates it, and nothing has to.
