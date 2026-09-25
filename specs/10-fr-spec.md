# Functional requirements — spec

The specification's own lifecycle: the acts that freeze it, and the tooling that performs them.
Everything here travels to a project that adopts the framework, because every project baselines its own specification.

### FR-SPEC-010 — Freezing a baseline is one command

```yaml
status: implemented
verification: T
derives_from: [INV-SPEC-030]
depends_on: [FR-VIEW-120, CON-SPEC-030]
refines: []
conflicts_with: []
code: [tools/srs_baseline.py]
tests: [tests/baseline-smoke.sh]
created: 2026-08-09
```

When freezing a baseline, the baseline command **shall** write the row into the baseline log and report what to commit — refusing where the log already has that row, or where the checker reports an error.

**Rationale.** Reading a diff and reducing it to a row is mechanical work that invites a wrong count nobody would notice, and it is the step that gets skipped.
The command does that step and stops: committing belongs to whatever client the project uses (CON-SPEC-030), and a `spec/v*` tag is a bookmark somebody may add afterwards or never.
Where such a tag was made first, the row describes that revision rather than the working tree, so writing it late costs nothing.
And the command ships, because every project baselines its own specification and has no release machinery of ours to lean on.

An error and not a warning, which is where this parts company with the release command (FR-CI-070).
A project part-way through describing itself carries warnings it has not worked off yet, and a baseline is the record of where it stands — refusing to freeze until the list is empty refuses the recording, not the mess.
What ships is the stricter question, and it is asked by a different command.

### FR-SPEC-020 — A specification can be dated from its own history

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_dates.py]
tests: [tests/dates-smoke.sh]
created: 2026-08-21
```

Where a requirement carries no `created` date, one command **shall** write the date its identifier first appeared in the history, leaving every requirement that already carries one untouched.

**Rationale.** The date a requirement arrived is a fact git already holds and holds correctly — it cannot be backdated without rewriting history — but it is only reachable by reading the log, which does not scale and is not available to a reader working from a snapshot.
Written into the block once, every lifecycle reading afterwards comes off the file in front of it.

Its own command rather than a step in the checker, because this writes requirement blocks and nothing else here does.
`ADR-0009` puts that beyond the checker deliberately, and the exception is not that this tool is trusted but that a person runs it on purpose, once, the way a baseline is frozen.

Leaving dated requirements untouched is what makes it safe to run twice.
A second pass over a specification that has already been dated changes nothing, so nobody has to remember whether it was done.

Read from the history and not from today: a requirement written a year ago and dated now would carry a date that is simply wrong, and wrong in the direction that makes the reading useless — every requirement looking new.

### FR-SPEC-030 — A decision that chose a mechanism says how it works

```yaml
status: implemented
verification: I
derives_from: [FR-SKILL-350]
depends_on: []
refines: []
conflicts_with: []
code: [specs/README.md, specs/adr/template.md]
tests: []
created: 2026-09-23
```

Where a decision chose an algorithm or a mechanism, the decision **shall** describe it in words — its steps, the invariants it keeps, and the inputs where it stops working.

**Rationale.** A decision says why this path and not the neighbouring one, and a path that is an algorithm can be compared with its neighbour only once it is written down; the standard's wording, "why", read as leaving the path itself to the code.
The code shows what the algorithm does today, not what a rewrite may not stop doing: an invariant the code happens to keep looks the same as one the system depends on.

The three parts are one description, not three obligations — what a rewrite must keep — and none of them is done without the others: steps with no invariants are a paraphrase of the code, invariants with no limits promise more than the algorithm gives.

The shipped decision template had *Context*, *Considered options*, *Decision outcome* and *Consequences*, and nowhere for this; an agent filling the template leaves out what it has no heading for, so the template carries a section for it, used only where the decision chose a mechanism.

### FR-SPEC-040 — An annotation stands where the requirement is carried out

```yaml
status: implemented
verification: I
derives_from: [FR-CHK-200]
depends_on: [FR-VIEW-380]
refines: []
conflicts_with: []
code: [specs/README.md]
tests: []
created: 2026-09-24
```

An annotation **shall** stand at the declaration that carries out the requirement it names, except in a file that carries the requirement as a whole, which carries it at its top.

**Rationale.** Since `FR-VIEW-380` an annotation's place is what a reader is shown: `--where --source` prints the region under it, and a line parked at the top of a file answers "where is this realized" with the imports.
The checker counts per file and cannot hold this, so it is verified by inspection, the way the language of a statement is (ADR-0034).
The first project to use the framework kept the rule in its own copy of the standard from 0.14 on and asked for it on 2026-09-24; its finer points — a doc comment, an attribute, a computed property — are its language's, and the standard keeps what holds in any.

The exception is the case where the top is the place: a suite that verifies a requirement, or a tool every part of which serves one — nothing to install, no git history written — is carried by the file as a whole, and the region under a line at its top is that file.
When this was written, twenty-one of this repository's twenty-two suites carried their `verifies:` lines at the top, as a suite that verifies a requirement whole should, and the tools carried lists above their first function naming what the whole file answers for — nothing to install, no git history written. Two of those lists named something a single place carries — the ordering of identifiers in `tools/srs_dates.py`, the exit codes in `tools/srs_arch.py` — so those two lines moved to where the thing is done.

### FR-SPEC-050 — The standard names every rule the checker reports by name

```yaml
status: implemented
verification: T
derives_from: [IF-SPEC-020]
depends_on: [FR-CHK-160]
refines: []
conflicts_with: []
code: [specs/README.md]
tests: [tests/standard-rules.sh]
created: 2026-09-24
```

The standard **shall** name every rule the checker reports by name, with what it reports.

**Rationale.** A project sets what a rule costs in `rules` and excuses a requirement from one in `exempt`, and both take the rule's name; the standard named one rule of thirteen, pointed `exempt` at a section that never mentioned it, and said of annotations that "unannotated files are never reported" while two rules reported exactly that.
The names are a published contract (`IF-SPEC-020`) that a project could learn only by getting one wrong and reading the checker's refusal.
A list of names kept by hand beside a tuple in code is the list that falls behind — the third found in a week, after the pipeline's steps and the table of suites — so a suite holds the table to `RULES` in `tools/srs_check.py`, both ways, and holds the *Annotations* section to every rule it restates.

### FR-SPEC-060 — A dry run of the baseline command writes nothing

```yaml
status: implemented
verification: T
derives_from: [FR-SPEC-010]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_baseline.py]
tests: [tests/baseline-smoke.sh]
created: 2026-09-24
```

Run with `--dry-run`, the baseline command **shall** write no file, the traceability matrix included.

**Rationale.** The command's help promised "print the row and write nothing", the `srs-baseline` procedure told its reader the same, and the dry run ran the checker without `--no-write`, so it rewrote `specs/90-traceability.md` and then printed "Dry run: nothing was written".
The suite asserted a clean working tree after the dry run, which a fresh matrix rewritten into itself leaves clean, so the assertion held for the wrong reason; it now makes the matrix stale first and holds it byte for byte.
`FR-INIT-070` said this of the installer and nothing said it of this command, so the promise lived in a help string and nobody checked it.

### FR-SPEC-070 — The standards name every value their tools define

```yaml
status: implemented
verification: T
derives_from: [FR-SPEC-050]
depends_on: []
refines: []
conflicts_with: []
code: [specs/README.md, specs/50-verification.md, grounds/README.md, arch/README.md]
tests: [tests/standard-vocabulary.sh]
created: 2026-09-25
```

The standards **shall** name every value their tools define for the reader to write — the requirement types, the verification methods, the files the checker reads no requirement from, the specification's configuration keys, the severities a rule can be set to, the register's kinds, keys, statuses, grades, classes, periods, confidence levels and configuration, and the layer's statuses and required keys.

**Rationale.** These lists matched the code on 2026-09-25 — all but the map of `specs/`, which left out the standard itself — and nothing held them: each is a line or a table a person keeps beside a tuple in a tool, which is the shape every list this release found behind had.
A value a reader cannot find in the standard is one they learn by writing it wrong and reading the refusal.
The suite compares both ways where a list claims to be the whole set, and asks that each value be named at all where the standard names it in prose.
