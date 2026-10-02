# ADR-0041 — The region's border is a line of its own, and what is left is a reading

- **Status:** accepted
- **Date:** 2026-10-02
- **Related requirements:** FR-INIT-370, FR-SKILL-460, FR-SKILL-440, NFR-SKILL-020

## Context and problem statement

`FR-INIT-370` names one region of the project's `AGENTS.md`, between `<!-- srs-dd -->` and `<!-- /srs-dd -->`, and the installer took the first occurrence of each marker anywhere in the text.
A guide carrying the markers twice therefore had the first pair filled.
Measured on 2026-10-01: a guide that showed the two markers in a fenced example before its real region had the whole guide written inside the fence, the real region's opening marker standing at byte 7 839 of the 7 951 the file then held and the region keeping the text it had.
Every upgrade after that rewrites the fence and never the region an agent reads, and the run reports the region as refreshed either way.
The likelier shape is smaller and the same in kind: the note this run prints asks for "the two lines", and a project that pasted that sentence into its guide had the region found in the prose.

## Considered options

1. Take the last pair rather than the first, which puts the region after any example.
2. Refuse and report where the markers occur more than once, as a guide without them is reported.
3. Require the markers to stand alone on a line, say so in the statement, and leave the rest to the agent that ran the installer.

## Decision outcome

Option 3.
Option 1 trades one wrong guess for another: a guide that documents the markers *after* its region — a note at the foot of the file — would then lose it, and nothing about a position says which pair is meant.
Option 2 refuses a guide that is correct whenever the second pair is an example, and the installer cannot tell the two apart, which is the whole difficulty.
Option 3 settles by a rule what a rule can settle — a marker inside a sentence is not a border — and hands the rest to the one reader that can judge where the rules of a method belong in a document.
`FR-SKILL-460` is that half: both installing procedures say to read the guide after the run and see that the region stands where an agent meets the rules, not inside an example or a fenced block.

### How it works

The border finder walks the text line by line, keeping a running byte offset.
It opens the region at the first line whose content, whitespace aside, is exactly `<!-- srs-dd -->`, and closes it at the next such line holding exactly `<!-- /srs-dd -->`; with no such pair it returns nothing and the run reports the two lines to add.
The region's start is the offset just past the opening marker's text and its end is the start of the closing marker's line, so an indented border keeps its indentation.
The invariants: nothing outside those two offsets is read or written, the file's own line endings are kept and the region is written with them, and a closing marker before the opening one is no pair.
It stops working where both borders stand alone on their lines and one pair is an example — a fenced block of exactly those two lines reads to it like the region, which is what `FR-SKILL-460` exists to catch.
Whitespace is not content, so a region inside a list item or a quotation is found.

### Consequences

A project whose guide names the markers in prose keeps its region where it put it.
The cost is paid in words: both installing procedures gained a section, and the budget of `NFR-SKILL-020` rose to 1 550 own words with the reason recorded beside the number.
A validation an agent performs is weaker than a gate, and that is accepted knowingly: the judgement is about where rules belong in a document, which no search over lines makes.
