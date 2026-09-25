# ADR-0035 — An annotation stands above what it marks, and its end is marked rather than parsed

- **Status:** accepted
- **Date:** 2026-09-25
- **Related requirements:** FR-SPEC-040, FR-VIEW-300, FR-VIEW-380, FR-VIEW-400, FR-CHK-270, FR-CHK-280, FR-INIT-180, CON-SPEC-040
- **Revises:** ADR-0034, on where inside a declaration an annotation stands and how its region is found; what it decided — an annotation marks a place, not only a file — stands

## Context and problem statement

ADR-0034 put a function's annotation at the top of its body, after the doc comment, and `FR-VIEW-380` found the region under an annotation by parsing: for a Python file the function the standard library's parser placed it in, for every other file a window running to the next annotation or sixty lines.
The tooling is Python and the projects are not — the first to adopt the framework is written in Swift — so the rule was precise where the tooling is and approximate everywhere it is used, which `CON-SPEC-040` and ART-080 now forbid.
The body-top placement has no room for what has no body: a one-line function, an expression-bodied property, a key in a configuration file.
And the window's end was a guess the reader could not see through.

## Considered options

1. Keep the body-top placement and the parser, and add parsers for more languages.
2. Place the annotation above what it marks, in every language, and let the viewer's window decide where the region ends.
3. Place the annotation above what it marks, and let the author mark the end with `srs-end:`, the window remaining as a fallback the viewer names as one.

## Decision outcome

Option 3.
Option 1 needs a parser per language, which the standard library does not carry and `NFR-SPEC-010` forbids fetching; every language without one stays approximate.
Option 2 was measured before it was chosen, and failed where it matters.

The measurement: 535 runs of `claude -p` with Opus, Sonnet and Haiku against a sandbox — a Swift file of 223 lines and a release script of 37 — through a prototype of the viewer printing each region in one of five forms.
Asked which lines carry a requirement out whose region a nested annotation had cut short, Opus named the right lines in every form; Sonnet and Haiku named only the window's lines in 98 runs of 100, whether the viewer said nothing, said "may be incomplete", or told them to read on in the file, and did so after reading the file, one of them writing that the code "logically extends through lines 29–31" and answering `21-23`.
With the end marked, all three named the right lines in 25 runs of 25, and read the file far less often.
No model, in 75 runs, copied the viewer's notice into code it was asked to quote; a notice after the lines was read as "what follows is not this requirement", and a notice in the header was not.

### How it works

A block is one or more consecutive lines carrying `implements:` or `verifies:` with nothing but the comment before the keyword.
It marks the lines down to the first `srs-end:` below it naming one of its requirements; a block inside it belongs to it, and its region is inside its parent's.
Without an `srs-end:`, the region runs to the next block or to a bound, and the viewer says so in the header of the region, never among the file's lines, which each carry their number.
An annotation with code before it on its line marks that line; `file` before the keyword marks the whole file.
The narrowest region holding a line is what that line realizes; failing any, the file's.
Nothing is parsed, so a file in any language is read the same way; the one cost is the marker, which the author writes.

### Consequences

- The checker reports an `srs-end:` that ends nothing as a warning (`FR-CHK-270`), and a block no `srs-end:` ends at the cost `report` (`FR-CHK-280`) — visible, never fatal, until a project raises it; this repository raises it to `warn` and ends every block.
- A rule has a default cost of its own for the first time: arriving at `warn`, the new rule would have failed `--strict` in every project on the upgrade that brought it.
- An annotation at the top of a function's body, or a list at the top of a file, is now a block over what follows it — with no `srs-end:`, down to the next annotation, sixty lines or the end of the file rather than the end of the function — and a list speaks for the file only with `file`; projects that placed them by ADR-0034 are told so in the upgrade note, and nothing fails.
- The installer strips `srs-end:` lines from the shipped tooling as it strips annotations, leaving the line in place.
- The measurement covered models of one family through one client; other agents were not measured.
