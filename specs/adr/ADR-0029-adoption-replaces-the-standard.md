# ADR-0029 — Adoption sets the project's own standard aside and installs the framework's

- **Status:** accepted
- **Date:** 2026-09-21
- **Related requirements:** FR-INIT-030, FR-INIT-040, FR-INIT-060, FR-INIT-230, CON-SPEC-020
- **Reverses:** the reading of `FR-INIT-040` under which a project's own `specs/README.md` was among the files adoption never touches, recorded in its rationale on 2026-08-07 and in the open issue *A project that adopted the framework never receives the standard*, which this decision closes

## Context and problem statement

Adoption keeps a project's own `specs/README.md` where it finds one, and that file carries no marker, so no upgrade and no `--force` ever replaces it.
The procedures installed beside it cite the standard by section — *Lifecycle*, *How to phrase*, *Baselines* — on the ground that the standard is the same document in every project (`CON-SPEC-020`), and in an adopted project those citations resolve to nothing.

A local experiment on 2026-09-21 showed what the kept file is worth.
A project whose own document said that a cancelled requirement is deleted, that no `partial` status exists and that "this file wins" was adopted, and the checker then enforced the standard's rules from the first run: deleting a requirement another one linked to was an error, `partial` passed, and `--vocabulary` printed six statuses the document forbade.
The rules the project now lives under are the standard's whatever its document says, and the document claiming authority is the one that has none.

## Considered options

1. **Install the standard beside theirs under a name that cannot collide** — `specs/README.srs-dd.md`, with every shipped procedure rewritten to the new path.
   Tried by hand in the experiment: the checker read the second file as a requirements file (`Files scanned: 2`) because only the basename `README.md` is reserved, the viewer's prose search read it as project prose, two documents each called itself the single normative one, and the rewrite would have to reach five procedures, the guide and the constitution and remember the name at every upgrade.
2. **Drop the section citations from the shipped procedures** and let each procedure explain the rules itself — two descriptions of one format, which the procedures refuse on their first line for the reason that they diverge.
3. **Say once, at adopt time, that the standard is worth merging by hand** — what the installer did; the merge does not happen, and the file that claims to win stays.
4. **Set the project's document aside and install the standard in its place** — the former document goes to `specs/archive/`, which the standard's own map defines as absorbed documents, not normative, kept for history, and which neither the checker nor the viewer reads.

## Decision outcome

Option 4.
Adoption moves `specs/README.md` to `specs/archive/README-before-srs-dd.md` byte for byte, installs the standard with its marker, and names both paths in its output (`FR-INIT-230`).
A stale file already at the archive path stops the run before anything is written, so that nobody's archive is overwritten.
`FR-INIT-040` narrows to the files that carry requirements, which adoption still never touches.
`FR-INIT-060` is unchanged: the standard stays among the files an upgrade refreshes only with `--force`, because its marker promises a maintainer that local edits survive until asked for — and in an adopted project that promise now holds, since the file there is ours.

What the former document said is sorted by the `srs-init` procedure, not by the installer: a rule the standard already states needs nothing; a project's own rule the standard permits — a status never used, a numbering step of one — belongs in the project's constitution, since the framework gives the frame and enforces only that; a rule the checker refuses is a practice the maintainer has to change, and that is their decision.
What the document said about the system rather than about its rules goes to the introduction and the glossary.

## Consequences

An adopted project holds the same standard as a fresh one, with the marker, so the procedures' citations resolve and upgrades reach it.
Adoption writes one file more than before and moves one, both named in the output and in the `--dry-run` list.
A project adopted before this decision keeps its own document until somebody sets it aside by hand; the upgrade notes for this release say how.
The one thing a project loses is the front position of its own rules, and it loses it in exchange for a document that describes the rules it is actually held to.
