# ADR-0028 — An area grows by widening its numbers and splitting its file by the thousand, and nothing is renamed

- **Status:** accepted
- **Date:** 2026-09-20
- **Related requirements:** INV-SPEC-010, INV-SPEC-080, INV-SPEC-090, FR-CHK-010, FR-CHK-250, FR-CHK-260, FR-CHK-160, FR-VIEW-050, FR-VIEW-320, NFR-CHK-010
- **Reverses:** the rejection of a wider identifier recorded on 2026-08-12 in the open issue *The standard never says how many numbers an area has*, which this decision closes; its reasoning is quoted below

## Context and problem statement

Two ceilings meet a growing area.
The file that holds it grows past what a person opens and an agent reads — the largest area here, GND, is 67 KB at 64 requirements — and the three-digit number runs out at 999, which at the convention of tens is the hundredth requirement.
Neither has been met yet: the highest number in any area is 540.
Both stand under one constraint, `INV-SPEC-010` — a published identifier never changes — which rules out every answer that renumbers.

On 2026-08-12 a wider identifier was weighed and rejected in both shapes: a fixed fourth digit with a leading zero renames every published identifier, and mixed widths "sort wrongly everywhere the tools order by identifier string".
The first reason stands.
The second was a property of the tools, not of the format, and the tools are where it is fixed.

The maintainer asked for one answer that serves any area, and the layers with it, rather than a limit written into the standard.

## Considered options

1. **Widen the number and split the file by the thousand.** Three digits or more, ordered by number; an area is a file until its numbers pass a thousand, then a directory of files named by their thousand, the existing file moved whole.
2. **Split the area by subject when it grows.** A new area name for new requirements, the old area frozen with its numbers.
3. **Write the ceiling into the standard** — 999 per area — and say the step of 10 is a convention.
4. **A directory with an index that maps files to number ranges**, on the model of a Python package with `__init__.py`.

## Decision outcome

Option 1, with the file split by the thousand as the default and a split by subject permitted.

**The number widens, and every tool orders by it.** An identifier's number has three digits or more, written without a leading zero beyond the third — `010`, `990`, `1000`, `1010` — and every tool that orders identifiers orders them by the number, not by the string, so that `1000` follows `990`.
One rule for the three grammars the framework reads: `FR-CORE-1000`, `B-1000`, `E-1000`.
Nothing already written changes width, which is what `INV-SPEC-010` demands and what a fixed fourth digit could not give.
A consumer of the published model that orders identifiers as strings will misplace a wider number; the model carries the identifier as written, and ordering by its number is that consumer's to do.

**An area is a file, then a directory of files by the thousand.** An area lives in `10-fr-<area>.md` while its numbers stay under 1000.
Its first number past a thousand makes it a directory: the file moves whole to `10-fr-<area>/000-999.md`, history with it, and `1000-1999.md` opens; the next thousand opens `2000-2999.md`.
A file named by a range holds only the numbers of that range, and `10-fr-<area>.md` holds `000-999`; the checker reports a number outside its file's range as a warning named `file-range`, with the move it asks for in the message, and a project may turn the rule off as it may any named rule (`FR-CHK-160`).
`README.md` inside an area directory is for people and the forge and is not a requirements file, like the reserved names at any depth.
Nothing else about the directory is prescribed: a project may cut a file by subject and name the pieces as it likes, and `srs_view.py --diff HEAD` after the cut names any requirement the move lost, because the comparison is by identifier and words and never by file (`FR-VIEW-050`).
This is about `specs/`: the register and the layer keep their records in files by kind and take from this decision only the width of the number.

**The sequence runs in tens and does not break.** New requirements take the next ten: after `990` comes `1000`, in the next file.
A number between tens — `025`, `995` — is for a requirement written beside an existing one, goes in the file of its thousand whenever it is written, and never continues the sequence.
So every file holds up to a hundred sequence numbers and any number of insertions, and the moment the next file opens is known in advance.

**Who moves the file, and when.** The author of the requirement that crosses a thousand — always inside `srs-new`, step 3, or a batch of `srs-harvest` — moves the file and opens the next before writing, and the step says so in its own text with the `git mv` line.
The checker is the guard for whoever did not come through the procedure: the `file-range` warning carries the instruction.
No tool moves a file in `specs/`; the tooling writes the matrix there and nothing else.

**Option 2 is kept as a right and not chosen as the answer.** An area that has outgrown its subject is cut into two areas, and nothing here forbids it; but a split by subject leaves the old area a mixture and the new one a remainder, and it does not answer the file's size at all — the old file stays as large as it was.
It is the answer to a different question.

**Option 3 writes down a limit that nobody has met and that the framework would then answer for.** The grammar `<NNN>` already says three digits; the number 999 adds nothing a reader can use, and the day it binds it would have to be unwritten.

**Option 4 keeps a second record of where a requirement lives.** A table of ranges in an index drifts the first time a block moves, and then either the checker verifies it — one more rule for a manifest — or it lies.
What it would answer is answered already: `srs_view.py FR-VIEW-240` finds a requirement in 0.09 s over the whole specification, because the tools parse everything and do not care how it is filed, and `grep -rln "^### FR-VIEW-240" specs/` in 0.01 s; a range in a *file name* answers the reader who opens the directory by eye, and can only be wrong in a way the matrix shows.
So there is no index of any kind, and no cache: at `NFR-CHK-010`'s bound of a second at 500 requirements the whole specification is read on every question, and that is fine.

## Consequences

Eight identifier patterns and some thirty sorts across `srs_check.py`, `srs_view.py`, `srs_grounds.py`, `srs_arch.py`, `srs_init.py` and `srs_cite_eval.py` change; one warning rule is added; the three standards gain a paragraph under *Identifier*; `srs-new` gains the move in its step 3 and `srs-harvest` a line.
The first thousand of every project, this one included, stays exactly as it is.
The open issue *The standard never says how many numbers an area has* closes.
