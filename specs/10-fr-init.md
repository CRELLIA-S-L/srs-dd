# Functional requirements — init

The installer, `tools/srs_init.py`: it runs from a clone of this repository
against somebody else's, which is what every requirement below is shaped by.

### FR-INIT-010 — Three modes, detected from the target

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh, tests/adopt-smoke.sh]
```

The installer **shall** decide by inspecting the target which mode it is in —
fresh when no specification is present, adopt when an SRS-shaped
specification exists without `specs/srs-config.json`, upgrade when that
configuration exists.

**Rationale.** The mode is a property of the target, not a claim the caller
should have to get right; an agent installing by URL cannot know it in
advance.

### FR-INIT-020 — Fresh install leaves a target its checker accepts

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-010]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
```

When installing into a target without a specification, the installer
**shall** lay out the skeleton, the configuration, one placeholder
requirement and the tooling, then run the target's own checker and return its
verdict.

**Rationale.** The first thing a maintainer sees must be a green run in their
repository, not ours; and the placeholder makes the format concrete before
they write anything.

### FR-INIT-030 — Adoption is transactional

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-010]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/adopt-smoke.sh]
```

While adopting an existing specification, the installer **shall** validate it
against the proposed configuration before writing anything and leave the
target byte-identical when that validation fails.

**Rationale.** Adoption is the moment of highest risk — a stranger's
specification, our guess at their lexicon. Anything short of a rollback would
mean a half-converted repository nobody asked for.

### FR-INIT-040 — Existing specification files are never modified

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-030]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/adopt-smoke.sh]
```

While adopting, the installer **shall** write only the tooling and the
service files the target lacks, leaving every existing specification file
untouched.

**Rationale.** Their requirements are theirs; we bring rules and scripts, not
edits.

### FR-INIT-050 — A specification without requirements is refused

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-010]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/adopt-smoke.sh]
```

If the target holds markdown under `specs/` but no requirement the strict
identifier grammar recognizes, the installer **shall** refuse with exit code
2 rather than treating the directory as empty.

**Rationale.** Going fresh over somebody's documentation directory would
scatter our skeleton through files that only look like a specification.

### FR-INIT-060 — Upgrades refresh the tooling and nothing precious

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-010]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
```

When run against an initialized target, the installer **shall** refresh the
checker, the viewer and the skills without a flag, while files a project
commonly owns — CI configuration, the agent guides, `.gitattributes`, the
hook — are refreshed only with `--force` and only when they carry the SRS-DD
marker.

**Rationale.** Tooling has to move with the framework or targets drift;
everything a maintainer has edited must not, and the marker is how we tell a
file we installed from one they wrote.

### FR-INIT-070 — A dry run writes nothing and tells the truth

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-010]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh, tests/adopt-smoke.sh]
```

Where `--dry-run` is given, the installer **shall** print the created,
refreshed and skipped lists the real run would produce and write nothing at
all.

**Rationale.** This is what an agent shows a maintainer before touching their
repository, so the list has to match the real run entry for entry — adopt
takes a separate branch through the code and is compared against it in the
tests.

### FR-INIT-080 — A project's own pre-commit hook is never displaced

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
```

If the target already runs something on commit, the installer **shall**
install the gate beside it and say so, instead of advising the
`core.hooksPath` switch that would disable what is already there.

**Rationale.** Silently disabling a project's linters and secret scanners
would be the single most damaging thing this tool could do.

### FR-INIT-090 — The lexicon is asked for, not assumed

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-090]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/adopt-smoke.sh]
```

The installer **shall** accept the modal verbs, negation words and rationale
markers as parameters and write them into the target's configuration, without
inferring a natural language on its own.

**Rationale.** Which words carry binding force is a decision with
consequences for every future requirement; the tooling proposes nothing here,
and the skill exists to have that conversation.

### FR-INIT-100 — The installer refuses to install into itself

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: []
```

If the target lies inside this repository, the installer **shall** refuse
before changing anything.

**Rationale.** The framework repository already has a specification of its
own; installing the payload over it would overwrite the standard with its own
starter copy.

### FR-INIT-110 — Upgrade notes come from the changelog

```yaml
status: implemented
verification: I
derives_from: [FR-INIT-060]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py, CHANGELOG.md]
tests: []
```

When upgrading, the installer **shall** print the version transition and the
upgrade notes recorded for the versions being crossed.

**Rationale.** A maintainer who upgrades three versions at once needs the
notes for all three, and nobody reads a changelog they were not handed.

### FR-INIT-120 — Upgrading is one command inside the project

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-060]
depends_on: [FR-INIT-140]
refines: []
conflicts_with: []
code: [tools/srs_upgrade.py]
tests: [tests/upgrade-smoke.sh]
```

When run inside an initialized project, the upgrader **shall** fetch the
framework that project was installed from, run its installer against the
project, and remove what it fetched.

**Rationale.** The old procedure asked a maintainer to keep a framework clone
somewhere, remember where, and pull it before every upgrade. Nothing in the
project pointed at any of that, so an agent working there could not upgrade
without being handed the address — which is the whole reason this exists.

### FR-INIT-130 — The upgrade is shown before it happens

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-070]
depends_on: [FR-INIT-120]
refines: []
conflicts_with: []
code: [tools/srs_upgrade.py]
tests: [tests/upgrade-smoke.sh]
```

Before writing anything into the project, the upgrader **shall** print the
version transition, the upgrade notes for the versions being crossed and the
list of files it would touch, and then wait for confirmation unless it was
told to proceed.

**Rationale.** A command that reaches the network and then rewrites files in
a repository has to show its hand first; the same shape the installer already
has with `--dry-run`, made the default here because the person running it
usually cannot see the framework's changelog any other way.

### FR-INIT-140 — A project records the framework it came from

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-020]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/upgrade-smoke.sh]
```

When installing into a project, the installer **shall** record in
`specs/srs-config.json` the framework repository the project is being
installed from.

**Rationale.** A fork or a mirror must upgrade from where it came, not from
an address compiled into the tooling; and a project that predates this field
still upgrades, because the compiled-in address remains the fallback.

### FR-INIT-150 — A fresh install says what to do first

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-020]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
```

When a fresh installation finishes, the installer **shall** print what to do
next in that project, beginning with the agent procedures it just installed
and followed by where the first requirement goes, the commands that check
and read the specification, and how the framework is upgraded later.

**Rationale.** Installation ends with a maintainer alone in front of a
directory of unfamiliar files. "Replace the placeholder" does not cover it:
neither the checker, nor the viewer, nor the one-command upgrade follow from
anything they can see, and those are what turn an install into a workflow.
The agent procedures come first because they are the point of the framework:
it exists so that code written with agents still has requirements behind it,
and a maintainer who never learns the skills are there gets the bookkeeping
without the reason for it. Switching the commit gate on is deliberately left
out of the list — it depends on what the project already runs, and
FR-INIT-080 answers it.

### FR-INIT-160 — An upgrade says what arrived, not only what to do

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-110]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/upgrade-smoke.sh]
```

When an upgrade crosses one or more framework versions, the installer
**shall** print what those versions added and changed, one line per entry,
beside the upgrade notes and with a pointer to the changelog for the rest.

**Rationale.** Upgrade notes answer "what must I do now", and only that.
Somebody who upgrades across three versions never learns that a new tool or
a new skill arrived, and so never uses it. One line per entry keeps the jump
across several versions readable, which the full sections would not be.
