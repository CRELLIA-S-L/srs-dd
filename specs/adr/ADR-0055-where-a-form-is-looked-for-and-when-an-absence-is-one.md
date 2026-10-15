# ADR-0055 — Where a form is looked for, and when an absence is one

- **Status:** accepted
- **Date:** 2026-10-14
- **Related requirements:** CON-ARCH-030, CON-ARCH-040, FR-ARCH-930, FR-ARCH-950, FR-ARCH-960, FR-ARCH-970, FR-ARCH-990, FR-ARCH-995

## Context and problem statement

`ADR-0054` had the checker compare a form with what the code declares and left two questions it never asked.

**Where a name is looked for.** The run pooled every declaration it read into one set of names, and a form was satisfied by any of them.
Measured on this repository: 44 names are declared in more than one part and `main` in thirteen modules, so a form naming `main` could not be falsified — delete it from the file the form is about and a neighbour's copy answers for it.
The same bare-name matching decided which form an entry crossed into, where 54 of 3541 entries read carried a name more than one part declares.

**When an absence is an absence.** Every other rule of this layer concludes from what it saw; `FR-ARCH-930` concludes from what it did not see, which `FR-ARCH-710` may do because a project supplying facts about its units claims they are complete.
`FR-ARCH-930` lost that condition when the checker learned to read a language itself, and reading a language is completeness per file rather than per part: a part carrying thirty-two shell files and one Python file is read, in the sense the gate used, and a form naming two of its shell functions was reported twice for naming what is there.

## Considered options

1. Leave it and let a project price `symbol-missing` down where it keeps a language the checker cannot read.
2. Compare a form only where the run read at least one declaration from a file its part carries.
3. Withdraw `FR-ARCH-930`: report only what was seen, as the rest of the layer does.
4. Put the file a symbol is expected in into the shape record, so an absence is decided per file.
5. Scope every comparison to the part, and conclude an absence only where that part's code was read whole.

## Decision

Option 5, as two constraints rather than a clause inside each rule, with the silence made visible.

**Option 1** silences the rule in the twelve parts where it works for the sake of the one where it does not.
**Option 2** does not fix the case it was written for: the part in question declares five Python symbols, so the condition holds and the shell names are reported exactly as before.
It also conflates a file read that declares nothing with a file never read, which loses a true finding — the one shape of defect this grain was added to catch.
**Option 3** gives up the rename, which nothing else catches: `symbol-unclaimed` reports types alone, so a renamed operation is invisible.
**Option 4** pushes the record toward the code it is supposed to be designed independently of, and makes a form carry paths a person would have to maintain.

`CON-ARCH-030` scopes the comparison; `CON-ARCH-040` gates the absence.
Two constraints and not one, because they do not apply to the same rules: `shape-built` concludes from what is there and is scoped but not gated — gating it would drop the finding on the day the code is written.
Constraints and not clauses, because four rules compare a form with the code and a fifth will be written later, and the one that forgets the clause is the one nobody reads twice.

**The facts file is the claim of completeness**, as `arch/units.json` is for the units, rather than a list of the files a producer read.
A project with nothing to supply has nothing to write, and a key naming the files read can be added to `IF-ARCH-120` afterwards without breaking a producer, which the reverse order cannot.
Until it exists, a non-native file in which nothing is declared cannot be marked read, and its part stays uncompared — named, so the project can see what it is paying.

**What counts as a code file is `code_extensions`**, read from the specification's own configuration.
A part carries a standard, a procedure and a CI template as readily as code, so the gate had to know which carriers could hold a declaration at all, and the project has already answered that question once for the two-way check.
A second list in `arch/arch-config.json` would answer the same question and drift from the first; the specification's published JSON does not carry the key, and `IF-VIEW-010` deliberately promises nothing beyond the requirements, so binding to it would have been binding to what that interface says it does not promise.

## Consequences

A form is now compared with its own part and with nothing else, so the 44 shared names stop answering for each other, and `shape-bypassed` can no longer be reported against a form whose code the caller never touched.

A part whose code the run could not read whole is compared with nothing and is named for it (`FR-ARCH-995`), which is what keeps the gate from trading a false warning for a false silence — the worse of the two in a layer whose standard warns about `Warnings: 0`.
A project gets the rule back by supplying facts for the half the checker cannot read, which is the path `FR-ARCH-980` already published.

`FR-ARCH-990` was implemented against declarations found rather than files read, which its statement never said: a file read that declares nothing had the run announce it compared the forms with nothing while the gate concluded an absence from it.
The condition now reads as written, and the two sentences no longer contradict each other.

The one case left uncovered is a part whose other language declares something the facts do not mention: the facts are trusted whole, so that name reports as absent.
It is the same trust `FR-ARCH-710` places in `arch/units.json`, and a project takes it on by writing the file.
