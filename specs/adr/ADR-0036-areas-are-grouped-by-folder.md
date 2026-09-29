# ADR-0036 — Areas are grouped by a folder, and an area's name joins its words with an underscore

- **Status:** accepted
- **Date:** 2026-09-29
- **Related requirements:** IF-SPEC-040, FR-CHK-260, FR-CHK-250, INV-SPEC-010

## Context and problem statement

A project with many subjects of one kind — maps of a game, each with requirements of its own beside the ones every map shares — wanted to find a map's requirements by walking down from the general to the particular: `FR-MAPS` for what all maps do, `FR-MAP_ILAND` and `FR-MAP_SPACE_SHIP` for each map.
Two things stood in the way.
An area's name was one run of uppercase letters and digits, so `MAP_ILAND` could not be declared; and nothing in the standard said how one area sits under another.
The hierarchy is for a person looking for a requirement; no tool was asked to compute anything from it.

## Considered options

1. Write the parent into the area's name — `MAP_ILAND` under `MAP` by its prefix — and let the tools group by prefix.
2. Declare the hierarchy in `srs-config.json`, an area naming its parent, and teach every tool that reads the areas to read the tree.
3. Let a folder of any name under `specs/` group areas' files, and let an area's name join words with an underscore, the name saying nothing of where the area is grouped.
4. Join an area's words with a hyphen — `FR-MAP-ILAND-010`.

## Decision outcome

Option 3.
Option 1 puts the grouping inside every identifier, and an identifier is never renamed (`INV-SPEC-010`): moving a map under another heading, or cutting one area in two, would be a regrouping nobody could make afterwards; the example that started this already had the parent `MAPS` over children named `MAP_`, a name the prefix rule would not have tied to it.
Option 2 changes the configuration's format in every installed project, needs a migration on upgrade, and every listing, the page and the graph would have to decide whether a parent's view takes in its children — work for a tree no tool had been asked to compute from.
Option 4 breaks what every tool relies on: the hyphen separates the segments, the heading net built on three of them would not take `FR-MAP-ILAND-010` at all, and every tool that splits an identifier at the hyphen would read `MAP` as its area.

### How it works

The checker has read every markdown file under `specs/` at any depth since it was written (`FR-CHK-250`), so a folder needed no new reading, only a statement and one rule extended: the area's single file holds the first thousand in a folder as it does directly under `specs/`, told apart from a range name and from a piece cut by subject by its name — two digits and a hyphen first, as the map's names begin (`FR-CHK-260`).
The folder's name means nothing to any tool; `adr` and `archive` are the two it cannot take, because nothing under them is read.
The area's grammar — `[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)*` — is defined once in `tools/srs_parse.py` and read by the configuration check, the annotation grammar, the installer and the viewer; the heading nets of the checker and the dates tool take an underscore in the area so that one nobody declared is refused by name (`IF-SPEC-040`).

### Consequences

A folder moves, is renamed or is dissolved without a requirement changing, and `--diff HEAD` names anything the move lost.
The grouping shows where files are shown — an editor, a forge — and not in the viewer's listings or its page, which group by area; the page's filter by file names a file without its folder.
Two areas under one folder are two areas to every tool: nothing counts, filters or checks by folder, and a project that later wants that asks for a new requirement, not for this one widened.
