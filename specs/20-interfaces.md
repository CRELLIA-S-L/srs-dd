# Interfaces

`IF-*` — the surfaces other people's tooling binds to. What is written here
cannot change without breaking somebody's pipeline or somebody's agent.

### IF-CI-010 — Exit codes of the installer

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-010]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/adopt-smoke.sh, tests/installer-smoke.sh]
```

The installer **shall** exit 0 on success, 1 on checker errors in the target
or completion past adopt's point of no return, 2 when it refused before
changing anything, and 3 when adoption rolled back and the target is
unchanged.

**Rationale.** An agent installing unattended has only the exit code to
decide whether to report success, retry with different answers, or stop and
ask; collapsing "refused" and "rolled back" would lose that distinction.

### IF-CI-020 — Exit codes of the checker

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-120]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/spec-check.sh, tests/checker-rules.sh]
```

The checker **shall** exit 0 where it found no error and, under `--strict`,
no warning either; 1 on errors — or on warnings under `--strict` — and 2 when
it could not run at all: an unusable configuration, an unknown flag, or no
`specs/` directory.

**Rationale.** CI distinguishes "your specification is wrong" from "the
checker never got as far as reading it": the second is not something a
contributor's change to the specification can cause.

This read "exit 0 when it found nothing to report" while the checker had
only errors to report, and it stopped being true the moment it gained
anything milder: a warning is printed and the run still succeeds, which
FR-CHK-070 has a fixture for. Reporting and failing are two
different acts, and holding them apart is the whole of the severity system —
a rule lowered to a report is said out loud and fails nothing (FR-CHK-160),
`--strict` is what promotes a warning to a failure (FR-CHK-120). A statement
that ties the exit code to whether anything was said describes neither.

### IF-SKILL-010 — The published entry point for an agent

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-040]
refines: []
conflicts_with: []
code: [.claude/skills/srs-init/SKILL.md, README.md]
tests: []
```

The installation procedure for an agent **shall** remain reachable at the raw
URL of `.claude/skills/srs-init/SKILL.md`, which the repository landing page
carries together with the clone command.

**Rationale.** Handing an agent nothing but the repository URL is the
framework's own distribution channel; the file is cited in released
documentation, so renaming or moving it breaks installs already in the wild.

### IF-VIEW-010 — The model is published, not merely dumped

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-SPEC-010, INV-SPEC-020]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

Where the model is asked for as JSON, the viewer **shall** emit every
requirement with the fields of its block, its location, and the reverse
links computed for it.

**Rationale.** This is the one machine-readable thing the framework offers,
and it was an implementation detail: something to pipe into `python -c`
while debugging. It stopped being that when things started binding to it.
Two suites parse it today, and one of them is the check that proves no
requirement of this framework leaked into a target — the guard on
CON-SPEC-020. A shape a gate depends on and no rule describes is a shape
that can be changed by somebody who thinks they are tidying.

What is promised is the requirement and what surrounds it: the block's own
fields, where it was read from, and the incoming links, which exist nowhere
in the source files and are the reason to ask a tool rather than parse the
markdown. What is deliberately not promised is the rest of the object — the
unreferenced files and their count, what outlived a cancellation, the list
of documents. Those are gathered for the page and change as it does, and a
caller that pinned them would be pinning a rendering.

An `IF-*` in a new area rather than a `FR-VIEW-*`, because the type is the
question: this is a surface somebody else's tooling binds to, and what
binds to it does not care which command produced it.

It rests on the block format and on the rule that reverse links are
computed, which is what it has to offer: the fields come from
IF-SPEC-010, and the incoming links exist only because INV-SPEC-020 keeps
them out of the files. Not on the page — the page is one reader of the
model among several, and a caller piping JSON into a script has nothing to
do with rendering.

### IF-SPEC-010 — The requirement block is a stable format

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [specs/README.md, tools/srs_check.py]
tests: []
```

A requirement **shall** be written as a level-three heading, a fenced `yaml`
metadata block of flat keys with scalar or bracketed-list values, a
statement, and an optional rationale — a shape a standard-library parser and
a future external tool can both read, whose keys are declared either
required or optional, a key it declares neither being no error.

**Rationale.** The format is deliberately poorer than YAML allows: nesting
and multi-line values would make the files unreadable by the very
line-oriented tools — grep, diff, review — that make a specification in git
worth having.

### IF-SPEC-020 — A published rule name keeps its meaning

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-160]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
```

A rule name the checker has published **shall** keep its meaning: it is
never renamed, and never given to a different rule.

**Rationale.** FR-CHK-160 lets a project say what a rule costs by writing
its name — in `specs/srs-config.json` for the whole project, in a
requirement's `exempt` field for one requirement. That makes the names a
vocabulary somebody else's files are written in, and nothing said so. A
rename breaks those files in the least helpful way available: the checker
refuses to start, lists the names it does know, and says nothing about what
the old one became. A name quietly reused for a different rule is worse —
everything keeps running and the exemption now excuses something nobody
meant to excuse.

An interface rather than an invariant, unlike INV-SPEC-010 which makes the
same promise about requirement identifiers. An identifier is referred to;
a rule name is *depended on* by a file the framework then reads back, which
is what the `IF-*` type is for.

Weaker than the same promise about metadata keys, and that is the point of
writing it down. A retired key has somewhere to go: the checker keeps a
table of them and reports "`depends` became `depends_on` in 0.14.0"
(FR-CHK-180). A rule name has no such table, so the compatible move is the
only move — add names, never move them. Building that table is possible and
is deliberately not asked for here: no rule has ever been renamed, and
machinery for a case that has not arisen is what ART-040 forbids.

Verified by test, which is not obvious for a promise about the future. What
a suite can hold is the past: the names published so far, listed where a
rename has to walk past them. That catches the only way this is broken in
practice — a name changed while tidying, with the project that depended on
it somewhere else entirely.

The three classes of key are what make the format extensible. Which keys are
obligatory was until now an accident of validation — omit `verification` and
the complaint was about its value being empty — and a key the checker does
not know has always been tolerated rather than refused, which is what lets a
later version of the framework add one without breaking a specification
written against an earlier one. Saying so out loud turns an emergent
property into a promise: an addition is compatible, a removal is not.

### IF-BEL-010 — The register record is a stable format

```yaml
status: deferred
verification: I
derives_from: []
depends_on: [INV-BEL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

A register record **shall** be written as a level-three heading, a fenced
`yaml` metadata block of flat keys with scalar or bracketed-list values, a
statement, and an optional rationale, whose keys are declared either required
or optional, a key it declares neither being no error.

**Rationale.** The same promise `IF-SPEC-010` makes for the requirement
block, made separately because it is a separate format: an addition is
compatible, a removal or a rename is not, and what lets a later version add a
key is that an unknown one is tolerated rather than refused.

One statement over every kind of record in the register — belief, bet,
ideology, frame — rather than one per kind. The obligation is that the rule
is the same throughout, and splitting it would destroy exactly that claim,
which is the reading `specs/README.md` gives for a list of exit codes.

The shape deliberately resembles the requirement block so that whoever has
read `specs/README.md` recognises it. Resemblance is not identity: neither
format is obliged to track the other's edge cases, and a later reader who
merges them would be inventing a coupling this subsystem was built to avoid
(ADR-0015).

### IF-BEL-020 — Exit codes of the belief checker

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-BEL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

The belief checker **shall** exit 0 where it found no error and, under
`--strict`, no warning either; 1 on errors — or on warnings under `--strict`
— and 2 when it could not run at all.

**Rationale.** A gate binds to these numbers, so they are an interface and
not an implementation detail. The three are one statement for the reason
`IF-CI-020`'s are: what a caller relies on is that these are all of them.

Its own requirement rather than an extension of `IF-CI-010`. That statement
gives the installer four codes, and `specs/README.md` names an exit-code list
as the case where splitting destroys the only claim a caller has. A fifth
code there would rewrite a promise every installed project already depends
on, to describe a subsystem most of them do not have.

### IF-BEL-030 — A published belief rule name keeps its meaning

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-BEL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

A belief rule name the checker has published **shall** keep its meaning: it
is never renamed, and never given to a different rule.

**Rationale.** The names are what a project writes in its own configuration
to say what a rule costs, so they are a vocabulary somebody else's files are
written in. `IF-SPEC-020` makes this promise for the specification checker
and explains why the compatible move is the only move: a rename breaks those
files in the least helpful way available, and a name quietly reused for a
different rule is worse, because everything keeps running while the
exemption now excuses something nobody meant to excuse.
