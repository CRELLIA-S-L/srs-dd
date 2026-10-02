# ADR-0039 — Everything the framework owns in a project lives in one directory, and ownership is a place

- **Status:** accepted
- **Date:** 2026-10-01
- **Related requirements:** FR-INIT-320, FR-INIT-330, FR-INIT-340, FR-INIT-350, FR-INIT-360, FR-INIT-370, FR-SKILL-430, FR-SKILL-440, FR-SKILL-450, FR-CHK-300, FR-INIT-060, FR-INIT-230, FR-INIT-240, FR-INIT-250, FR-INIT-270, FR-INIT-280, FR-INIT-290, FR-SKILL-390, CON-SPEC-020

## Context and problem statement

After an install, two authors wrote into the same places and the border between them was only implied — a marker in a file, a prefix in a name, a row in a table.
Articles of the constitution were numbered by both, each taking the next free number after the shipped set: on 2026-09-25 the framework wrote ART-100 into the shipped constitution and on 2026-09-29 a project wrote its own ART-100, and the shipped guide's rule 11 then named, in that project, the wrong article.
The guide itself held the framework's numbered rules and the project's additions in one file that `--force` replaced whole, so the upgrade notes of 0.21.0 had to tell a project whose guide was its own which lines to add by hand.
`tools/` and `.claude/skills/` held files of both with nothing saying which an upgrade rewrites, and an area named `ADR` or `ARCHIVE`, grouped into its folder, was skipped by the checker without a word.
The precious-file mechanism — refreshed only with `--force` and only where the marker survived — was the border for seven kinds of file, and it was the thing that rewrote whatever a project had added beside the framework's text.

## Considered options

1. Keep the layout and separate only the numbers: a band of article numbers reserved for the framework, the project's own above it.
2. Separate the spaces by owner but keep the files where they were: the method's articles in a document of their own, the guide's rules in a region, `tools/` and `.claude/skills/` still shared by prefix.
3. One directory for everything the framework owns, `srs-dd/`, rewritten whole by every upgrade; everything outside it the project's, written once as a starter or never; the two things that cannot move — the procedures and the rules an agent reads — the only exceptions, named in the standard.

## Decision outcome

Option 3.
Option 1 fixes the collision and leaves the cause: the method's articles stayed the project's after install, and the procedures stood on them as on the framework's own — a project that reversed ART-020 left eight references in the procedures pointing at nothing.
Option 2 separates ownership but leaves it implied by prefix in two shared directories, which is the shape that failed.
Under option 3 ownership is a place: what is under `srs-dd/` is the framework's, what is outside is the project's, and the marker is needed only to tell whether a `srs-dd/` already in a target is ours and whether a file an earlier version wrote elsewhere is ours to move.
Nothing is precious any more, and `--force` has nothing left to do.

### How it works

The directory holds `tools/` with the nine shipped tools, `standard.md`, `grounds.md` and `arch.md` for the layers the project keeps, `method.md` with the articles `SRS-DD-ART-010` to `SRS-DD-ART-060` and `SRS-DD-ART-100`, `guide.md`, `LICENSE` and a `README.md` that carries the marker and the version.
The installer copies it from this repository's own `srs-dd/`, which is the source and not a copy — this repository being the first project of its own method — stripping the annotations and the decision numbers on the way as before; `tools/` here keeps what never ships.
Where `srs-dd/` already exists in a target and its `README.md` carries no marker, the installer refuses with exit 2 before writing anything.
On upgrade it rewrites the directory whole and, for a target installed before, deletes the copies an earlier version left under `tools/`, `specs/README.md`, `grounds/README.md` and `arch/README.md` — only where the copy carries the marker, so a README of the project's own is never taken for the standard — and the report after the run names the path the hook, the pipelines and the guide have to call.
The guides, the hook, the pipelines and `.gitattributes` are starters: written where the file is absent, never again.
Inside `AGENTS.md` the region between `<!-- srs-dd -->` and `<!-- /srs-dd -->` is rewritten on every run with `srs-dd/guide.md`, nothing outside it touched; a guide without the region is reported with the two lines to add, because an import mechanism exists only in Claude Code's `CLAUDE.md` and every other client reads `AGENTS.md` as plain text.
This repository's own `AGENTS.md` carries the same region, compared byte for byte with `srs-dd/guide.md` by the parity suite, which is what INV-SKILL-010 now rests on.
An area whose lowercase name is a directory the checker skips is refused at the prompt and at the configuration.

### Consequences

A collision of numbers between the framework and a project cannot happen again: the method's articles have a space of their own, and the project's constitution is numbered by the project alone.
The procedures stand on articles that are the framework's and move with it, so a rule of the method tightened here reaches every project at its next upgrade, and a project that wants to depart from the method does so in its own files.
Paths changed everywhere — every call is `python3 srs-dd/tools/<tool>` — and the change is incompatible with earlier versions: the upgrade moves a project's files, and its hook, pipelines and guide have to be edited once, which the report says.
The references to ART-010 to ART-060 and ART-100 in this repository's records were rewritten to `SRS-DD-ART-*`, decisions included, by the maintainer's choice; the method's document says what the old numbers meant.

*Settled 2026-10-02:* the spelling is `SRS-DD-ART-NNN` and not `ART-SRS-NNN`, which this decision first chose.

*Settled 2026-10-02, the numbers:* the starter the installer ships numbers its two remaining articles ART-010 and ART-020, not ART-040 and ART-090. Those were the numbers they held while the method's six stood around them, and keeping them left a project's constitution opening at the fortieth number with the first three empty and nothing saying why — a layout inherited rather than chosen, which `tests/guide-parity.sh` had begun to pin. Nothing is reserved any more: the method's articles are a space apart, so every number is the project's. The amendment log keeps the old numbers where it records what happened under them and gains a line for the renumber, classified MAJOR because neither old number resolves there any more — the reading this log already took when the six moved out rather than were deleted; the lines about the six that moved now say the numbers became the project's again, so a reader meets no bare list that looks like a claim on ART-010 below it. A project installed before this keeps its own file untouched (`FR-INIT-360`), so the two numberings never meet. Both separate the spaces, and the second reads better — the kind first, the way the project's own `ART-NNN` reads — but it separates them by a segment in the middle, which is a convention a reader has to know. `SRS-DD-` first makes the separation a property of the shape: nothing a project writes begins with it, so no number of ours can be mistaken for one of theirs by anybody or anything, and the version marker cannot be confused with it either, since `RE_MARKER` wants three numbers after the prefix. Settled before 0.22.0 shipped, so no project had ever seen the first spelling and nothing published was renamed.
The procedures remain the one thing of the framework's that lives outside the directory, and a project that edits one loses the edit at the next upgrade — the standard says so, and says to take another name.
