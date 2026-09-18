# ADR-0026 — The checker reads the edges a project computed, not the project's language

- **Status:** accepted
- **Date:** 2026-09-17
- **Related requirements:** FR-ARCH-260, IF-ARCH-040, FR-ARCH-200, FR-ARCH-060, FR-ARCH-090, IF-ARCH-020, IF-ARCH-030, CON-ARCH-010

## Context and problem statement

`FR-ARCH-200` reports a dependency the code has and the declared model does not — where the language of a file can be read.
The checker reads one: `imports_of` parses Python with `ast` and resolves the names against the modules the elements carry.
For every other language the check is silent, and silent in the same way as a clean run.

The first project that installed the layer is a Swift application with ten elements and seventeen declared edges, every one checked against a call site before it was written.
On 2026-09-17 it ran an extractor of its own over its 134 files — a top-level type declared in one element's files and mentioned in another's, comments and strings stripped, names declared in more than one element ignored — and found forty-six edges, twenty-seven of them undeclared: a constants file under the shell that seven parts read, two composition roots that build every other part and declared none of it, and three cycles between the agent element and its neighbours.
None of that is findable by a person checking declared edges against the code, because that method only ever confirms what was written.

The project asked for a seam, not for Swift.
The comparison — the declared model against what the code has — knows no language and is worth the same for any; the extraction is the project's business.
Without a seam the project has to write the comparison as well, and a second copy of `check_conformance` drifts from the first.

## Considered options

1. A parser per language in the framework — Swift now, then whatever the next project is written in.
2. A dependency that parses many languages, such as tree-sitter, behind an ADR superseding ADR-0003.
3. A file in the layer, `arch/edges.json`, listing the edges the project computed however it computed them; the checker merges them with the imports it reads itself and runs the one comparison over both.

Under option 3, two shapes for an edge:

- 3a. Between elements — `{"from": "E-060", "to": "E-040"}` — as the project proposed.
- 3b. Between files — `{"from": "Crellian/Core/ToolRouter.swift", "to": "Crellian/Shell/CapsuleCore.swift"}` — resolved to elements by the checker.

And one further question the project raised: whether a complete list from the project makes the other direction — a declared edge no code walks — worth reporting.

## Decision outcome

Option 3, shape 3b, one direction.

**Option 1 cannot be finished.**
A parser per language is a parser per language forever, each one a poorer reading of a language than the project's own tools have, and the framework is installed into repositories written in any language precisely so that it does not have to know theirs (ADR-0001).

**Option 2 buys a dependency to do badly what the project can do well.**
Even a parser that reads every language does not know what counts as a dependency in a given codebase — which names are noise, which references cross a boundary that matters — and ADR-0003 is not superseded for a reading the project would still have to correct.

**Option 3 keeps the half the framework does and takes the half only the project can supply.**
The framework's half is the reflexion model itself: the comparison, the rule name, the pricing under `FR-ARCH-090`, the `seen` set that reports a pair once.
The project's half is a list of pairs, produced by an extractor in its own language, a build step, or a hand.

**3b over 3a because an edge in element terms needs the extractor to know the layer.**
The project's prototype had to decide which element owns which file — a second copy of the rule `owner_of` already applies under `FR-ARCH-060` — and a list written that way goes stale the day a file moves between elements although the code did not change.
An edge between files is what the code actually has; the checker resolves both ends by its own rule, and the finding names the file, which is where a reader has to look.
A value that is an element identifier is refused when the file is read, with the reason: a part depending on a part is the declared model, and `depends_on` is its field.

**One direction, as before.**
The project's list lacked one edge the author had declared, written on the strength of a constant that lives in another element's file; whether the model or the extractor was wrong about it took a person reading the file to settle.
A list is complete only as far as its extractor is, and reporting a declared edge the list lacks would set the checker against the author on the extractor's word.
The rationale of `FR-ARCH-200` holds unchanged.

## Consequences

The silence moves and does not disappear.
The checker cannot regenerate the file, so no gate of the kind `FR-ARCH-170` sets holds it fresh against the code; a stale list fails silent the way an absent one does.
The standard says so, and says the file is as fresh as the project keeps it — regenerated before the checker runs, in the project's own pipeline, or written by hand and treated as any hand-written record.

The file is the first thing in `arch/` the project generates and the checker only reads.
`CON-ARCH-010` covers it as it covers every path: the checker writes the map and nothing else, and the gate in `tests/arch-check.sh` already fails a run that modifies any `arch/*.json`.

`arch/edges.json` is an interface (`IF-ARCH-040`).
Keys may be added; none is renamed or removed once published, since the extractors written against it are in languages and repositories this framework will never see.

A project with no file and no Python is where it was: the check is silent, and the standard now says which languages it reads — one — rather than leaving `Warnings: 0` to be read as a verdict.
