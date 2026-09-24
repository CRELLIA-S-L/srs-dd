# ADR-0034 — An annotation marks the place that carries a requirement, not only the file

- **Status:** accepted
- **Date:** 2026-09-24
- **Related requirements:** FR-SPEC-040, FR-CHK-080, FR-CHK-200, FR-VIEW-370, FR-VIEW-380
- **Revises:** ADR-0014, on where an annotation stands; what it decided about the two claims and the rules that compare them stands

## Context and problem statement

ADR-0014 made an annotation a checked mirror of the `code` and `tests` fields: the file's claim about why it exists, compared file by file with the specification's claim.
At that grain its place in the file meant nothing — one line anywhere closes `annotation-unpaired` — and this repository's suites carry their lists at the top, which at that grain is honest.

Since 0.19.0 the place is data.
`FR-VIEW-370` prints each annotation as `path:line`, and `FR-VIEW-380` prints the region under it — for a Python file the function or class it belongs to, for any other file the lines up to the next annotation or sixty of them — so a reader asking for the code behind a requirement is shown whatever the annotation happens to sit above.
An annotation parked at the top of a file answers that question with the imports.
Nothing said where an annotation goes, the standard still called annotations "an optional cross-check", and the first project to use the framework kept its own rule on placement in its own copy of the standard from 0.14 on, where nobody else could read it.

## Considered options

1. Keep the file grain: an annotation anywhere in the file, and `--where --source` reads what it reads.
2. The place grain everywhere: an annotation stands at the declaration that carries out the requirement, in every file.
3. The place grain, with one exception: a file that carries a requirement as a whole — a suite that verifies it, a tool every part of which serves it — carries the annotation at its top.

## Decision outcome

Option 3.
Option 1 leaves the viewer's most useful answer to chance.
Option 2 asks a suite to scatter `verifies:` over its fixtures when the suite as a whole is what verifies, and marks twenty-one of this repository's twenty-two suites as wrong for saying something true.
The exception is the case where the top of the file is the place: there the region under the annotation is the whole file, which is what carries the requirement.

### How it works

The rule is for whoever writes the annotation; the checker still counts per file and cannot tell a well-placed line from a parked one, and no check is added.
A reader applies one test to a line: delete the declaration under it — does the requirement it names break?
If yes, it stands where it should. If the file as a whole carries the requirement, the top is right. Otherwise it is in the wrong place, or in a file that should not carry it.
What it keeps: `--where --source` shows the code that carries a requirement, and a list of identifiers at the top of a file means the file carries each of them whole.
Where it stops working: a requirement carried by the absence of code has no declaration, and is excused from `annotation-unpaired` by `exempt` instead; and for a line above a branch in a Python file, `--where --source` prints the whole enclosing function, because that is the region `FR-VIEW-380` reads — the line is still where a reader looks first.

### Consequences

- The standard's *Annotations* section states the rule, and *What not to do* forbids a list at the top of a file that does not carry each identifier whole, and an annotation in a file that does not carry out the requirement.
- Nothing mechanical holds the rule; it is verified by inspection (`FR-SPEC-040`), as the language of a statement is.
- This repository's suites keep their lists; its tools keep the ones that name a property of the whole file, such as depending on nothing outside the standard library.
