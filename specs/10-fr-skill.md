# Functional requirements — skill

The agent procedures in `.claude/skills/`. They are plain markdown read by
whatever tool the project uses, so their behavior is what they oblige an
agent to do, not code that runs.

### FR-SKILL-010 — The everyday loop

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [.claude/skills/srs/SKILL.md]
tests: []
```

The `srs` procedure **shall** require naming the requirements a change
belongs to before the code is written, creating one where none exists, and
re-reading their statements as the loop is closed, so that anything built
and not described is written down or taken out.

**Rationale.** Everything else in the framework is downstream of this single
habit; the checker can prove a link exists but never that the change was
thought about first. Both ends are needed, and the second was learned the
hard way: a change that begins as a fix to an existing requirement is exempt
from writing a new one, and that exemption quietly covers whatever else gets
added along the way — a control appeared on the rendered page that no
statement mentioned, because the work was framed as repair and nobody
re-read the requirement it repaired. Re-reading one statement costs a
paragraph; a change that names no requirement at all is itself the signal
that either nothing behavioural happened or the requirement is missing.

### FR-SKILL-020 — Rules are stated once

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-010]
refines: []
conflicts_with: []
code: [.claude/skills/srs/SKILL.md, specs/README.md]
tests: []
```

The skills **shall** point at `specs/README.md` for the markup rules instead
of restating them.

**Rationale.** Two copies of the same rule diverge, and the copy an agent
happens to read wins — which is the failure mode this whole framework exists
to prevent.

### FR-SKILL-030 — Harvesting proposes, the maintainer approves

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [.claude/skills/srs-harvest/SKILL.md]
tests: []
```

The `srs-harvest` procedure **shall** write requirements only in batches
shown to the maintainer beforehand, with status `draft` and without inventing
tests that do not exist.

**Rationale.** A mined specification is a reading of the code, not a
decision; the draft status makes the warning list the approval queue.

### FR-SKILL-040 — Setup brings two decisions back to the maintainer

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-INIT-090]
refines: []
conflicts_with: []
code: [.claude/skills/srs-init/SKILL.md]
tests: []
```

The `srs-init` procedure **shall** have the agent show the requirement areas
and the generated lexicon to the maintainer, together with the dry-run
install list, and install only after they approve.

**Rationale.** Areas are the middle segment of every identifier and
identifiers are immutable; the lexicon decides which words bind. Both are
normative for the target project forever, so neither is settled by whoever
happens to be driving the agent.

### FR-SKILL-050 — An audit reports, it does not repair

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [.claude/skills/srs-audit/SKILL.md]
tests: []
```

The `srs-audit` procedure **shall** report drift between the specification
and the code without changing either side on its own.

**Rationale.** When the two disagree it is unknown which one is wrong, and
that is the maintainer's call — a helpful fix here would silently pick a
side.

### FR-SKILL-060 — The upgrade procedure travels with the project

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-120]
refines: []
conflicts_with: []
code: [.claude/skills/srs-upgrade/SKILL.md, tools/srs_init.py]
tests: [tests/upgrade-smoke.sh]
```

The skills installed into a project **shall** include the upgrade procedure,
so that an agent working there can upgrade the framework without being told
where it lives.

**Rationale.** `srs-init` stays framework-only by design — it installs into
somebody else's repository. Upgrading is the one part of it a project needs
to carry itself, and until now nothing in an installed project mentioned
upgrades at all.

### FR-SKILL-070 — The release procedure travels with the framework

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CI-070]
refines: []
conflicts_with: []
code: [.claude/skills/srs-release/SKILL.md]
tests: [tests/installer-smoke.sh]
```

Before cutting a release, the `srs-release` procedure **shall** have the
agent propose the version number for the maintainer to confirm and draft the
changelog section by its format contract; it stays in the framework
repository and is never installed into a project.

**Rationale.** The command is one line, but two of its inputs are not the
agent's to settle. The version number follows from what actually changed —
an article amended, a shipped file touched, a requirement reworded — and
that reading belongs to the maintainer, exactly as the areas and the lexicon
do in `srs-init`. The changelog section an agent can draft, provided it
knows the rule this project tripped over four times: the first sentence of
every entry stands alone, because the installer prints that sentence and
cuts the rest. Framework-only, like `srs-init`: a target releases nothing of
ours.

### FR-SKILL-080 — The baseline procedure travels with the project

```yaml
status: partial
verification: T
derives_from: []
depends_on: [FR-SPEC-010]
refines: []
conflicts_with: []
code: [.claude/skills/srs-baseline/SKILL.md, tools/srs_init.py]
tests: [tests/installer-smoke.sh]
```

The skills installed into a project **shall** include the baseline
procedure, which shows what changed since the previous baseline, offers an
audit of the requirements that change touches, and proposes the version for
the maintainer to confirm before the row is written.

**Rationale.** The command is one line, and neither of the two things around
it is the agent's to settle: the number is a claim about the specification,
and the commit that makes the baseline real happens in whatever git client
the project uses (CON-SPEC-030). A procedure is where that sequence lives —
without one, the command leaves an agent guessing at the number and stopping
in the wrong place. It travels because every project baselines its own
specification, unlike `srs-release`, which stays here.

The audit is offered here because a baseline is the last cheap moment: after
it, the frozen state is what a reader will compare against, and a statement
nobody can test freezes just as well as a good one. The offer is scoped to
what the diff names — requirements added, reworded, and those linked to them
— because auditing the whole specification at every baseline is the kind of
step people stop taking.

### FR-SKILL-090 — Authoring a requirement is not implementing it

```yaml
status: deferred
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
```

When a requirement is authored, the authoring procedure **shall** end at the
written requirement and at whatever architecture decision the discussion
settled, leaving the building of it to a task started separately.

**Rationale.** Requirements here have been born `implemented` in the same
commit as their code, so `deferred` never happened and no state existed in
which the specification described something not yet built. A baseline can
then only record what already shipped, which is why freezing one felt like
bookkeeping rather than a statement of intent (INV-SPEC-030). Separating the
two acts is what gives a baseline something to freeze. The architectural
part of that discussion is a decision, not behaviour, so it goes where
decisions go — `specs/adr/` — and only when there was a choice to settle: a
requirement describes what the system must do, and how it will be built has
no place in it.

### FR-SKILL-100 — The checks a change calls for are named, not guessed

```yaml
status: deferred
verification: I
derives_from: []
depends_on: [FR-SKILL-010]
refines: []
conflicts_with: []
code: []
tests: []
```

When a change is finished, the check procedure **shall** name the checks the
requirements it touched call for — the checker, the tests those requirements
list, and what a person has to look at where the method is not a test — and
offer to run them rather than running them unasked.

**Rationale.** The specification already answers this and nobody reads it
for the purpose: every requirement carries a `verification` method and the
paths that verify it, so which checks a change calls for is derivable rather
than a matter of memory. A method of `I` or `D` is where this matters most —
those never appear in a suite, and the reader is told what to look at or
learns about it from a bug. Offering rather than running is not politeness
but ART-030: builds and test runs need the user's word each time.

### FR-SKILL-110 — The specification can be read as a page on request

```yaml
status: deferred
verification: I
derives_from: []
depends_on: [FR-VIEW-060, FR-VIEW-140]
refines: []
conflicts_with: []
code: []
tests: []
```

When the specification is to be read rather than grepped, the page procedure
**shall** render it as one self-contained page and open it.

**Rationale.** Two commands and a path, which is two commands and a path more
than a reader should have to remember — and the reason to have the page at
all is the audience that will never run either. What the procedure adds
beyond the commands is what the commands do not say: the file is
self-contained and can simply be sent to somebody, `--repo-url` is what makes
its links to the code work, and CI publishes the same page from the default
branch so a link may already exist.

### FR-SKILL-120 — The authoring procedure judges what no checker reaches

```yaml
status: deferred
verification: I
derives_from: []
depends_on: [FR-SKILL-090]
refines: []
conflicts_with: []
code: []
tests: []
```

When a statement is written, the authoring procedure **shall** judge it
against the qualities no checker reaches — one capability, verifiable, and
free of vague wording — and say what it found before the requirement is
recorded.

**Rationale.** A specification may be written in any language, so a word
list is the wrong instrument: what reads as vague depends on the sentence,
not on the vocabulary, and a script strict enough to catch "as needed" would
reject half of a language it does not know. An agent reads the sentence and
can judge it, and that judgement is the only thing standing between a
requirement and a statement nobody can test. It belongs to authoring rather
than to audit because the cost of fixing a statement is lowest before
anything derives from it.
