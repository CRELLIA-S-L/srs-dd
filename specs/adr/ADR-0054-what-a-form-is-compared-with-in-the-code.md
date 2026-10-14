# ADR-0054 — What a form is compared with in the code

- **Status:** accepted
- **Date:** 2026-10-14
- **Related requirements:** IF-ARCH-120, FR-ARCH-930, FR-ARCH-940, FR-ARCH-950, FR-ARCH-960, FR-ARCH-970, FR-ARCH-980, FR-ARCH-990

## Context and problem statement

`ADR-0053` gave the layer a third kind of record and left three of its keys reading as declarations nothing checked: `names`, `shape` and `owns`.
That is the position `interface` held before `FR-ARCH-490`, and the standard said so in as many words.
A record whose keys nothing reads drifts from the code it describes, and the drift is invisible — the state every rule in this layer exists to make visible.

So the layer needed facts of a kind it does not hold: which symbols exist, where each is declared, what a type's own operations are, and which names one file reaches on another.
Nothing about those facts is like a dependency: an import is a line of text, a symbol is a declaration, and a crossing into a type is a question about what a variable holds.

## Considered options

1. The project supplies every fact in a file, for every language including the one the checker reads.
2. The checker reads every language it can and takes nothing from the project.
3. The checker reads one language itself; the project supplies the rest, and never the same file twice.
4. Nothing: leave the three keys as declarations and say in the standard that they are read by people.

## Decision

Option 3, and with it four narrowings that each could have gone the other way.

**One language read natively, every other supplied.** The arrangement `FR-ARCH-200` already made for the dependencies, for the same reason: the common case needs no file, and the framework reads one format and no technology.
A file the checker can read is read and is never also taken from `arch/symbols.json`, because a symbol held by two readings that disagree is the failure the split exists to prevent.

**`kind` is the layer's own three words** — `type`, `operation`, `state` — matching `names`, `shape` and `owns`.
A format saying `class` would be readable by one language's producer and a translation for everybody else, and the file's whole purpose is to be produced from a world this framework knows nothing about.

**`symbol-unclaimed` is about types alone, and is a note.**
Every symbol would mean a project being told about every helper function it ever wrote; the forms would be written to quiet the rule, and the layer would become the retelling of the code `FR-ARCH-820` guards against.
A note rather than a warning, and conditional on the part holding a form, because this is the backlog of adopting the grain one part at a time.

**`shape-bypassed` fires only where the form states its operations, and only from outside the part.**
A form declaring no operations has said nothing that could be crossed — the silence `FR-ARCH-490` leaves to `FR-ARCH-450` one grain up — and a part reaching its own insides is how a part is built.

## Consequences

The four keys of a shape record now mean something a run can disagree with, and `shape` in particular has teeth it did not have yesterday.
A project in a language the checker does not read gets exactly as much as it produces facts for, and a run that read nothing says so (`FR-ARCH-990`) rather than passing quietly — the trap this layer's standard names about `Warnings: 0`.

What is knowingly left unread: a field reached through a variable holding an instance.
Nothing in the file says what that variable is, so the native reading cannot see it, and the rule is therefore weaker in Python than in a language whose own tooling produces entries.
That is a limit of the reading and not of the rule, and the standard says so where a reader will meet it.

Native reading stops at what another part could reach: a class brings its methods, its fields and the types nested in it, each under a dotted name, and a name declared inside a function is read by nothing.
Only a type at the top level of its file is one the unclaimed rule asks for a form about, since a nested type is part of what encloses it; a project that wants more can say more in its own facts.

What this decision did not settle, and `ADR-0055` did: where a name is looked for, and on what terms a name not found is reported as absent.
As taken here, the comparison pooled every declaration the run read, and the absence was concluded from whatever that pool happened to hold.
