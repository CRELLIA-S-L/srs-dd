# ADR-0040 — What is not the framework's in its directory is named, not removed

- **Status:** accepted
- **Date:** 2026-10-02
- **Related requirements:** FR-INIT-380, FR-INIT-320, FR-INIT-330, FR-INIT-340

## Context and problem statement

`ADR-0039` made ownership a place: what is under `srs-dd/` is the framework's, what is outside is the project's.
The installer refreshes the files it owns there and leaves anything else, so the place was a rule with no instrument.
Driven through a sandbox on 2026-10-01, `srs-dd/notes-of-mine.md` and `srs-dd/tools/mytool.py` were written into an installed target by hand and survived three upgrades unmentioned, while eight places — the standard among them — told the reader the directory holds nothing of the project's.
`FR-INIT-330` does not reach them: it reads the marker in `srs-dd/README.md` alone, so a stranger's file beside a marked README never makes the directory somebody else's.

## Considered options

1. Report every path under the directory the installer does not own, and soften the eight sentences to what is then true.
2. Delete what it does not own there and say so in the run, which makes "rewritten whole" exact.
3. Leave the border a rule of text and strike "rewritten whole" from the places that read as a claim about the contents.

## Decision outcome

Option 1.
Option 2 makes the sentences exact and buys it with the one thing `ART-SRS-030` reserves for the user's explicit confirmation — deleting a file the tool did not create.
A path under `srs-dd/` is both at once: in a place declared ours, and somebody else's work, and `FR-INIT-340` already draws that line by deleting only copies that carry the marker.
Option 3 leaves the maintainer to discover the file, which is how the sandbox found it rather than how a project would.
So the installer names what it does not own and leaves the choice where it belongs, and the sentences say that instead of promising the directory is empty of everything else.

### How it works

The installer keeps every path it handled in its own lists — created, refreshed, skipped, moved.
After the run it walks `srs-dd/` in the target and reports every file whose path is in none of those lists, each on its own line.
A directory whose name begins with a dot is skipped: it holds a tool's working state rather than anybody's text, and naming it would be noise on every run. A hidden file is named like any other.
The invariant is that the report is derived from what this run did rather than from a list of what the framework ships: a file added to the directory in a later release is accounted for without touching the walk.
It stops working where a run fails before the lists are filled — the partial-completion path reports the summary and not this, deliberately, since a half-finished run has not yet written what it owns.
A dry run reports what it would find, because the walk reads the disk and writes nothing.

### Consequences

A project that puts a file under `srs-dd/` learns so at its next upgrade and decides what to do with it.
The word "whole" leaves the sentences that described the directory's contents; the standard, `srs-dd/README.md`, `docs/install.md` and the rationale of `FR-INIT-320` now say that the framework's files are rewritten and any other path is named.
The directory is still not policed: a file put there stays until somebody moves it, and nothing fails over it.
That is accepted — the alternative is a tool that deletes a stranger's work on its own, and the framework does not have that permission.
