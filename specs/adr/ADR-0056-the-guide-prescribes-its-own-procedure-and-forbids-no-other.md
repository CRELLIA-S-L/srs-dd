# ADR-0056 — The guide prescribes the project's procedure and forbids no other

- **Status:** accepted
- **Date:** 2026-10-14
- **Related requirements:** FR-SKILL-700, FR-SKILL-710

## Context and problem statement

The framework ships a procedure for each act a change goes through, and since 2026-10-13 that includes
the three acts the work is actually driven by — the build over several passes, the review and the commit
(`FR-SKILL-630`, `FR-SKILL-640`, `FR-SKILL-650`).
The shipped guide names every one of them, and naming turned out not to be enough.

`FR-SKILL-640`'s rationale holds the measurement: over 18 sessions of three projects, a general build
procedure of the maintainer's own machine was invoked 135 times, more than anything else in those
sessions, while the framework had nothing in its place.
It now has something in its place, and nothing anywhere says to prefer it.
Measured again on 2026-10-14, in this repository: an architecture stage was built through a general
procedure while the framework's own existed, and the set of checks was assembled from the files that had
been edited rather than derived from the requirements the change touched, which is what `FR-SKILL-100`
exists to do and the one thing the two procedures do differently.
The maintainer learned of the substitution by asking afterwards.

An agent reads the guide in every session, whatever it was asked, so the guide is where a rule of this
kind can be stated at all.
What had to be decided is whether it states a preference or a refusal, and where it lives.

## Considered options

1. Nothing — the guide names the procedures, and an agent that reads it will use them.
2. A refusal in this repository's own tool configuration, naming each general procedure that duplicates one
   of the framework's.
3. A line in this repository's own agent-specific file, outside the region the installer ships.
4. A rule in the shipped guide region, prescribing the project's procedure and forbidding nothing.
5. Option 4 with a refusal beside it, so that a substitution is both named and stopped.

## Decision outcome

Option 4, as two obligations rather than one.

Option 1 is what was in force while the measurement was taken, twice.
Option 2 and option 5 refuse an instruction the maintainer gave, which is the one thing a procedure layer
has no standing to do: an instruction naming a procedure has already made the choice, and a refusal makes
the framework argue with the person it serves.
They are also unshippable — a refusal has to name the procedure it refuses, those names exist on one
machine, and a project installed afterwards would carry a rule about something it does not have.
Option 3 binds one agent in one repository and reaches no project the installer touches, which is the
opposite of where the measurement says the gap is.

Two obligations, because they are separable in the sense *How to phrase* gives the word: the guide could
prescribe the project's procedure and say nothing about the case where an instruction names another, and a
reader would be able to tell.
`FR-SKILL-700` is the prescription, and it is silent exactly where it is overridden; `FR-SKILL-710` covers
that point, which is where a substitution otherwise becomes invisible.

### How it works

One rule, rule 12 of *The rules most easily broken*, in `srs-dd/guide.md`, carried verbatim into the region
of both guides as `FR-SKILL-440` requires.
It holds wherever the instruction left the choice open, and asks for a name — not a question — wherever it
did not: the instruction is followed, and the project's procedure for that act is named in the same
message, so the maintainer can say that the instruction was given without knowing there was an
alternative.

The rule names no procedure of its own.
It is about a kind — the procedure the project names for an act — so it covers the procedures the framework
ships today, those it ships later, and the general ones on whatever machine the session runs on, none of
which this repository can enumerate.

What holds it: two literal phrases of the rule's own words in `tests/guide-parity/AGENTS.txt`, found in
both guides by `tests/guide-parity.sh`.
A rule in a file every session reads and no suite holds is a rule that will be deleted by the next edit
that needs the words.

### Consequences

A general procedure can still be invoked by name, and will be — the rule costs that nothing.
What changes is that the framework's own procedure is the default wherever nobody said otherwise, and that
a substitution is said out loud instead of being discovered afterwards.

Nothing in the repository refuses anything, so an agent that does not read the guide is not stopped.
That is accepted knowingly: this layer's only instrument is the text an agent reads in every session, and
the alternative instruments all refuse the maintainer's own instruction.

The guide's budget rose from 2 290 to 2 320 for fifty-five words (`NFR-SKILL-020`), raised rather than paid
for by cutting an instruction, which is `INV-SKILL-020`.
