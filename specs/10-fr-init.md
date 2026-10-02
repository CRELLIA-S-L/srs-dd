# Functional requirements — init

The installer, `tools/srs_init.py`: it runs from a clone of this repository against somebody else's, which is what every requirement below is shaped by.

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
created: 2026-08-07
```

The installer **shall** decide by inspecting the target which mode it is in — fresh when no specification is present, adopt when an SRS-shaped specification exists without `specs/srs-config.json`, upgrade when that configuration exists.

**Rationale.** The mode is a property of the target, not a claim the caller should have to get right; an agent installing by URL cannot know it in advance.

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
created: 2026-08-07
```

When installing into a target without a specification, the installer **shall** lay out the skeleton, the configuration, one placeholder requirement and the tooling, then run the target's own checker and return its verdict.

**Rationale.** The first thing a maintainer sees must be a green run in their repository, not ours; and the placeholder makes the format concrete before they write anything.

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
created: 2026-08-07
```

While adopting an existing specification, the installer **shall** validate it against the proposed configuration before installing anything and leave the target byte-identical when that validation fails.

**Rationale.** Adoption is the moment of highest risk — a stranger's specification, our guess at their lexicon.
Anything short of a rollback would mean a half-converted repository nobody asked for.

*Before installing*, and the word is exact.
The validation runs the target's checker against the proposed configuration, so that configuration and a temporary copy of the checker are on disk before it can start; both are taken back out when it fails, which is what the second half promises and what the suite compares.
A run killed between the two leaves the temporary checker behind, and the installer removes it on the next attempt — the single exception to the guarantee, named here because a statement claiming more than the design can give is a statement nobody can check code against.

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
created: 2026-08-07
```

While adopting, the installer **shall** write only the tooling and the service files the target lacks, leaving every file that carries requirements untouched.

**Rationale.** Their requirements are theirs; we bring rules and scripts, not edits.
The project's own standard is the one file this does not cover — it is set aside, not edited, and FR-INIT-230 says where (2026-09-21; until then the statement covered every file under `specs/`, the standard included).

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
created: 2026-08-07
```

If the target holds markdown under `specs/` but no requirement the strict identifier grammar recognizes, the installer **shall** refuse with exit code 2 rather than treating the directory as empty.

**Rationale.** Going fresh over somebody's documentation directory would scatter our skeleton through files that only look like a specification.

### FR-INIT-060 — An upgrade refreshes what may be the project's own only on request

```yaml
status: superseded
superseded_by: FR-INIT-360
verification: T
derives_from: [FR-INIT-010]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-07
```

When run against an initialized target, the installer **shall** refresh the files that may be the project's own — the agent guides, `.gitattributes`, the specification standard, the grounds standard, the architecture standard — only with `--force` and only when they carry the SRS-DD marker.

**Rationale.** Everything a maintainer may have edited must not move with the framework unasked, and the marker is how we tell a file we installed from one they wrote; the tooling moves without asking, under `FR-INIT-270`.

The standard was in neither list — the one refreshed without a flag, now `FR-INIT-270`'s, nor this one — until 0.14.0, so it was installed once and never moved again: a project set up at 0.7.0 and upgraded since ran the current checker and the current skills against a standard 112 lines out of date.
That is worse than a stale CI file, because `CON-SPEC-020` lets a shipped procedure cite the standard's sections by name on the grounds that it is the same document in every project — a claim nothing maintained.

It joins this list rather than `FR-INIT-270`'s because adopt deliberately keeps a project's own `specs/README.md` (`FR-INIT-040`), and refreshing without a flag would undo that at the first upgrade.
Since 2026-09-21 adopt sets that file aside and installs the standard in its place (`FR-INIT-230`), so a project adopted after that holds a standard with the marker and `--force` reaches it like any other; the standard stays in this list because the marker in it promises a maintainer that local edits survive until asked for.
`srs-dd/grounds.md` joined it on the same terms and reaches only the projects that keep a register — an upgrade refreshes it where it is and installs it nowhere else.
`srs-dd/arch.md` joined on exactly those terms when the architecture layer shipped, and this sentence did not follow it.
The code had it right from the layer's first commit — the same flag the grounds standard travels under — so what lagged was the enumeration, and an enumeration that lags is invisible: every path it names exists, and nothing reports the one it does not.
The CI configuration and the hook left this list on 2026-09-30: they are the project's files, which the installer writes once and never again (`FR-INIT-290`).
So the characterization widened: "commonly owns" was true of CI files and agent guides, and the standard is not something anyone writes for themselves — it is merely a file that may already be theirs.

The agent guides were in this list and behaved unlike the other six: an upgrade left them alone with the flag and without it, because they are filled in rather than copied and the answers had not been kept.
`FR-INIT-200` keeps the name, `FR-INIT-210` already kept the width, and the seven now mean one thing.

The marker carries the framework version — `SRS-DD-0.14.0`, matched as a pattern — because the bare name appears in ordinary prose.
A project that adopted the framework and wrote "we follow the SRS-DD standard" in its own `specs/README.md` would otherwise be told its document is ours and have it replaced.

The statement named the checker, the viewer and the skills while the installer refreshed every tool it ships, and it said the CI configuration is refreshed with `--force` while an upgrade refreshed it only when `--ci` was passed — which `srs-dd/tools/srs_upgrade.py`, the command a project runs, has no way to pass, so `--force` there never reached the pipeline at all. On 2026-09-24 the statement was brought to the tooling it covers, and the upgrade finds the template the project already carries as ours and treats it like every other file here.

**Split on 2026-09-29.** Until then this number also carried the refresh of the tooling and the skills without a flag, in a `while` clause the checker's rule for glued requirements does not see, under one status and one `tests` field.
Twice a gap in this half stood under the status of the other — the standard missing from both lists until 0.14.0, the CI configuration unreachable from `srs-dd/tools/srs_upgrade.py` until 0.21.0 — and the refresh of the tooling moved to `FR-INIT-270`.

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
created: 2026-08-07
```

Where `--dry-run` is given, the installer **shall** print the created, refreshed and skipped lists the real run would produce and write nothing at all.

**Rationale.** This is what an agent shows a maintainer before touching their repository, so the list has to match the real run entry for entry — adopt takes a separate branch through the code and is compared against it in the tests.

### FR-INIT-080 — A project's own pre-commit hook is never displaced

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CI-020]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-07
```

If the target already runs something on commit, the installer **shall** write no hook and say what calls the gate from it, instead of advising the `core.hooksPath` switch that would disable what is already there.

**Rationale.** Silently disabling a project's linters and secret scanners would be the single most damaging thing this tool could do.
It lays no copy of the gate beside the project's hook either, as it did until 0.22.0 as `.githooks/pre-commit.srs-dd`: the gate is a tool (`FR-CI-180`), and what the project's hook needs is a call to it, which the installer says (`FR-INIT-300`) and the installing procedure adds (`FR-SKILL-410`).

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
created: 2026-08-07
```

The installer **shall** accept the modal verbs, negation words and rationale markers as parameters and write them into the target's configuration, without inferring a natural language on its own.

**Rationale.** Which words carry binding force is a decision with consequences for every future requirement; the tooling proposes nothing here, and the skill exists to have that conversation.

### FR-INIT-100 — The installer refuses to install into itself

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-INIT-010]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: []
created: 2026-08-07
```

If the target lies inside this repository, the installer **shall** refuse before changing anything.

**Rationale.** The framework repository already has a specification of its own; installing the payload over it would overwrite the standard with its own starter copy.

### FR-INIT-110 — Upgrade notes come from the changelog

```yaml
status: implemented
verification: I
derives_from: [FR-INIT-060, FR-INIT-270]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py, CHANGELOG.md]
tests: []
created: 2026-08-07
```

When upgrading, the installer **shall** print the version transition and the upgrade notes recorded for the versions being crossed.

**Rationale.** A maintainer who upgrades three versions at once needs the notes for all three, and nobody reads a changelog they were not handed.

### FR-INIT-120 — Upgrading is one command inside the project

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-060, FR-INIT-270]
depends_on: [FR-INIT-140]
refines: []
conflicts_with: []
code: [srs-dd/tools/srs_upgrade.py]
tests: [tests/upgrade-smoke.sh]
created: 2026-08-08
```

When run inside an initialized project, the upgrader **shall** fetch the framework that project was installed from, run its installer against the project, and remove what it fetched.

**Rationale.** The old procedure asked a maintainer to keep a framework clone somewhere, remember where, and pull it before every upgrade.
Nothing in the project pointed at any of that, so an agent working there could not upgrade without being handed the address — which is the whole reason this exists.

### FR-INIT-130 — The upgrade is shown before it happens

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-070]
depends_on: [FR-INIT-120]
refines: []
conflicts_with: []
code: [srs-dd/tools/srs_upgrade.py, tools/srs_init.py]
tests: [tests/upgrade-smoke.sh]
created: 2026-08-08
```

Before writing anything into the project, the upgrader **shall** print the version transition, the upgrade notes for the versions being crossed and the list of files it would touch, and then wait for confirmation unless it was told to proceed.

**Rationale.** A command that reaches the network and then rewrites files in a repository has to show its hand first; the same shape the installer already has with `--dry-run`, made the default here because the person running it usually cannot see the framework's changelog any other way.

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
created: 2026-08-08
```

When installing into a project, the installer **shall** record in `specs/srs-config.json` the framework repository the project is being installed from.

**Rationale.** A fork or a mirror must upgrade from where it came, not from an address compiled into the tooling; and a project that predates this field still upgrades, because the compiled-in address remains the fallback.

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
created: 2026-08-08
```

When a fresh installation finishes, the installer **shall** print what to do next in that project, beginning with the agent procedures it just installed and followed by where the first requirement goes, the commands that check and read the specification, and how the framework is upgraded later.

**Rationale.** Installation ends with a maintainer alone in front of a directory of unfamiliar files.
"Replace the placeholder" does not cover it:
neither the checker, nor the viewer, nor the one-command upgrade follow from anything they can see, and those are what turn an install into a workflow.
The agent procedures come first because they are the point of the framework:
it exists so that code written with agents still has requirements behind it, and a maintainer who never learns the skills are there gets the bookkeeping without the reason for it.
Switching the commit gate on is deliberately left out of the list — it depends on what the project already runs, and FR-INIT-080 answers it.

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
created: 2026-08-08
```

When an upgrade crosses one or more framework versions, the installer **shall** print what those versions added and changed, one line per entry, beside the upgrade notes and with a pointer to the changelog for the rest.

**Rationale.** Upgrade notes answer "what must I do now", and only that.
Somebody who upgrades across three versions never learns that a new tool or a new skill arrived, and so never uses it.
One line per entry keeps the jump across several versions readable, which the full sections would not be.

### FR-INIT-170 — An undated specification is offered a date

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-SPEC-020]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-21
```

Where a target's specification carries requirements without a `created` date, the installer **shall** say that one command can date them, and run nothing.

**Rationale.** The dating command exists for specifications written before the field did, which is every specification a project already has.
Nobody looks for a tool they have not heard of, and an upgrade is the one moment the framework has a project's attention.

Said and not done, for the reason nothing else here writes a requirement block unasked.
An installer that edited a hundred requirements because it noticed a missing field would be the tool taking a decision that belongs to whoever owns the specification, and a project that wants no dates at all is not a project in error.


### FR-INIT-180 — The tooling arrives without this framework's annotations

```yaml
status: implemented
verification: T
derives_from: [CON-SPEC-020]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh, tests/adopt-smoke.sh]
created: 2026-08-25
```

When copying its own tooling into a target, the installer **shall** replace every traceability annotation and end marker, leaving the line where it was and leaving one marked as an example alone.

**Rationale.** The shipped Python carries a hundred-odd `implements:` and `verifies:` lines.
They exist for the two-way check this repository runs on itself — the requirement's field is the specification's claim, the annotation the file's own — and that check is checked here, where the requirements are.
In a target they are at best inert and at worst wrong: where a project declares an area this framework also uses, `implements: FR-CHK-110` stops being an unknown identifier and resolves to *their* requirement under that number, which is the harm CON-SPEC-020 is worded against.

Every annotation, not only one naming a requirement of ours.
CON-SPEC-020 stopped sorting by whose number it is, and the removal never sorted either: it takes out exactly what a checker would have read as a claim, whatever area the claim names.

Removed on the way out rather than in the source, because the alternatives each cost something this does not.
Marking the lines `srs-ignore` would silence them here as well — the exemption is unconditional — and the check they exist for would end.
Moving the links into a register beside the code would make them a second copy of the `code` field written by the same hand in the same commit, which is what ADR-0014 rejected and INV-SPEC-020 forbids: an annotation earns its place by being a different person's claim made in the file, and a list is not that.

The line survives the removal.
A traceback from a target names the line it happened on, and a bug report is read against the source in this repository;
deleting the lines would shift every number after them and make the two disagree by an amount nobody can see.

An annotation carrying `srs-ignore` is left alone, because that is how the standard marks an example rather than a claim, and the two examples in the checker's own comments are where a target reads the annotation format at all.

### FR-INIT-190 — Each copied tool says which release it came from

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-270]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh, tests/adopt-smoke.sh]
created: 2026-08-25
```

The installer **shall** stamp every tool it copies with the framework version it was installed from.

**Rationale.** The marker already tells a precious file from a project's own; on a tool it answers a different question, which is how old this particular file is.
A project can copy the tooling by hand, one file at a time, and an upgrade that failed halfway leaves some files moved and some not — in both cases the version is the first thing anybody needs and there was nowhere to read it.
Reading it out of the running tool answers only for the tool that runs.

One line per file, in the shape the marker already has, rather than one per annotation removed: the same number repeated a hundred times in one file is not more information than the same number once.

### FR-INIT-200 — A project records the name it was installed under

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-060]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-09-08
```

The installer **shall** record the project's name in the target's configuration, so that a later run can rewrite the agent guides without asking for it again.

**Rationale.** `AGENTS.md` and `CLAUDE.md` are the only payload files that are filled in rather than copied: each template carries the project's name, and `AGENTS.md` also carries the line `FR-INIT-220` writes about its width — answers a person gives at install.
An upgrade does not ask those questions, so until the answers were kept there was nothing to fill the template with — and the installer's response was to leave the guides alone entirely, with `--force` and without it.

That left `FR-INIT-060` promising a refresh nothing performed, and the guide's own header saying `--force` would overwrite it.
Keeping the name is what makes both true; the width was already kept, by `FR-INIT-210`, for a different reason and to the same effect.

Recorded rather than derived: the directory a project sits in is not its name, and a guess written into the file a project's agents read every session is a guess nobody asked for.
Where an older configuration carries no name — every project installed before this — the directory is the fallback, because a guide refreshed under a slightly wrong title is better than a guide that stops being refreshed at all.
The same for an answer the file carries but nothing can use: both of these are interpolated into text, so a name that is not a string and a width that is not a whole number each end in a traceback rather than a message, out of a tool whose whole job is to run inside somebody else's repository.
Each falls back and the run says which answer it disbelieved.

### FR-INIT-210 — The project's line width is asked for, never assumed

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-090]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-26
```

The installer **shall** accept the project's line width as a parameter and write it into the target's configuration, without inferring it from the project's files.

**Rationale.** This framework has a width of its own — 120 columns, enforced by `FR-CI-100` over this repository's sources — and it reaches no project:
the suite that enforces it does not travel, and neither does the document that states it.
That is the right arrangement and this requirement does not change it.
A project's code is written to the project's rules.

What is missing is that the framework installs an agent guide and says nothing about those rules, so an agent working there infers a width from how the files happen to look.
That is the same failure `FR-CI-100` was written against, met in somebody else's repository, where we have no business enforcing anything and every reason to pass the number along.

Taken as a parameter and not worked out here, for the reason the lexicon is taken as a parameter: finding out what a project already follows is reading, and reading is what the agent running the install is for.
A project states its width in whichever file its toolchain reads — `.editorconfig`, `pyproject.toml`, a linter's own config, or nowhere at all — and a script that went looking would need a heuristic per convention, would be wrong quietly when a project used a form it had not been taught, and would grow a new branch with every tool that comes into fashion.
`FR-SKILL-190` puts the reading on the procedure, where a wrong answer is seen by the person approving it.

A project that declares nothing anywhere is not a project in error.
Then there is no parameter and nothing is written.

### FR-INIT-220 — The installed agent guide names the project's width

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-210]
refines: []
conflicts_with: []
code: [tools/srs_init.py, skeleton/AGENTS.md]
tests: [tests/installer-smoke.sh, tests/adopt-smoke.sh]
created: 2026-08-26
```

Where a project has recorded a line width, the shared agent guide the installer writes **shall** state it.

**Rationale.** The number is worth recording only if something reads it back, and the reader here is an agent rather than a gate.
A guide that carries the width turns a rule the project stated once into a rule an agent applies without being told twice, which is what the guide is for.

One guide and not both.
`AGENTS.md` is the shared one and `CLAUDE.md` opens by sending its reader there, carrying only what is specific to one agent; a width in both would be two places to keep in step and one of them would eventually be wrong.

No gate goes with it, deliberately.
Checking the width of a project's code is a linter's job and most projects already have one; the framework arrives for the specification and would be overstepping if it started refusing commits over source formatting.
Where the width is not recorded, the guide says nothing about it rather than naming a default.

### FR-INIT-230 — Adoption sets the project's own standard aside

```yaml
status: superseded
superseded_by: FR-INIT-320
verification: T
derives_from: [FR-INIT-030]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/adopt-smoke.sh]
created: 2026-09-21
```

While adopting a specification that has its own `specs/README.md`, the installer **shall** move that file to `specs/archive/README-before-srs-dd.md`, install the framework's standard in its place and name both paths in its output.

**Rationale.** After adoption the checker enforces the standard's rules whatever the project's own document says, so leaving that document in place leaves a file that claims authority it no longer has.
The archive is where the standard sends absorbed documents, and nothing reads it as requirements; the former document survives there byte for byte, for the adopt procedure to sort and for history.
A stale copy already at that path stops the run before anything is written, so that no archive of somebody else's is overwritten.

### FR-INIT-240 — A skipped file says whether it differs from what ships

```yaml
status: superseded
superseded_by: FR-INIT-320
verification: T
derives_from: [FR-INIT-060]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-09-24
```

On upgrade, the installer **shall** mark each file carrying its marker that it skipped for want of `--force` as either the same as what this version ships or different from it, the marker's version aside.

**Rationale.** An upgrade without `--force` listed every precious file it left alone under one reason, "use --force to refresh".
From 0.19.0 to 0.20.0, in a project installed without a CI template, that was seven files, of which three had changed — the standard, the grounds standard and the agent guide — and the list could not say which; the first project to read the release notes called a partial install the danger of the release, since a refreshed procedure then points at a paragraph its standard does not have.
Marking the difference is what turns the list into something to act on: a file the same as what ships needs nothing, a file that differs is either one the framework changed or one the project edited, and either way it is the one to look at before `--force`.

The marker's version is set aside because every release restamps it: a comparison that counted it would call every skipped file changed, and the list would say nothing again (ADR-0033).
A file without the marker is not compared — it is not ours, and it keeps the reason it had.

### FR-INIT-250 — Every account of what an upgrade leaves alone names each kind

```yaml
status: superseded
superseded_by: FR-INIT-360
verification: T
derives_from: [FR-INIT-060]
depends_on: []
refines: []
conflicts_with: []
code: [docs/install.md, docs/upgrade.md, tools/srs_init.py, srs-dd/tools/srs_upgrade.py, .claude/skills/srs-init/SKILL.md, .claude/skills/srs-upgrade/SKILL.md]
tests: [tests/standard-vocabulary.sh]
created: 2026-09-25
```

Every place that says which files an upgrade refreshes only with `--force` **shall** name each kind of file `FR-INIT-060` lists.

**Rationale.** Nine places say it — the installer's `--force` help among them since the audit that found it saying six — each in its own words, and on 2026-09-24 five of them left out a kind: the layers' standards in `docs/install.md` and `docs/upgrade.md`, the architecture standard in the installer's docstring, the hook in the installer's procedure, and the three standards in the upgrader's help.
Whoever reads one of them decides from it whether `--force` is safe, so a kind it leaves out is a file overwritten by surprise or a refresh never asked for.
The suite reads each place and asks each kind of it, allowing the words each place uses — "the standards" names all three; the glossary's entry is one of the places it reads, and is not in the field because the specification is not a part of the system.

### FR-INIT-260 — The tooling arrives without this framework's decision numbers

```yaml
status: implemented
verification: T
derives_from: [CON-SPEC-020]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-09-25
```

When the installer copies a tool into a project, it **shall** take out each citation of one of this framework's decisions, leaving the sentence it supported and every line where it was.

**Rationale.** The shipped tooling's comments cited this repository's decisions by number — seventeen of them on 2026-09-25 — and in a project `ADR-0009` points at nothing, or at the project's own ninth decision, the harm `CON-SPEC-020` names for a requirement's identifier.
The numbers are useful here, to whoever edits the tooling beside the decisions they cite, so they stay in the source and go on the way out, the way annotations do (`FR-INIT-180`, ADR-0022); the procedures and the standards, which are read rather than edited, state the reason instead of the number.
A citation is taken out where it stands in brackets after its sentence, which is how every one in the tooling is written; the suite scans the installed target for any number at all, so one written some other way is red rather than shipped.

### FR-INIT-270 — An upgrade refreshes the tooling and the skills without a flag

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-010]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-09-29
```

When run against an initialized target, the installer **shall** refresh `srs-dd/` whole and the skills it ships to that project without a flag.

**Rationale.** Tooling has to move with the framework or targets drift; everything a maintainer may have edited must not, and `FR-INIT-060` is the other half of that sentence.
Split out of it on 2026-09-29, where the two shared a number, a status and a test, and a gap in one stood twice under the status of the other.
Nothing moved between the two lists when they were split: the tooling and the skills were refreshed without a flag before, and the files that may be the project's own were refreshed only with `--force`.
"It ships to that project": the register's checker and procedure travel only where the project keeps a register, and the layer's only where it keeps the layer.

### FR-INIT-280 — What stays the framework's says whose it is

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-270, FR-INIT-060]
refines: []
conflicts_with: []
code: [srs-dd/tools/srs_check.py, srs-dd/tools/srs_parse.py, srs-dd/tools/srs_view.py, srs-dd/tools/srs_upgrade.py, srs-dd/tools/srs_baseline.py, srs-dd/tools/srs_dates.py, srs-dd/tools/srs_gate.py, srs-dd/tools/srs_grounds.py, srs-dd/tools/srs_arch.py, .claude/skills, srs-dd/standard.md, srs-dd/grounds.md, srs-dd/arch.md, srs-dd/method.md, srs-dd/README.md, srs-dd/LICENSE]
tests: [tests/installer-smoke.sh]
created: 2026-09-30
```

Every file the installer copies into a target whose text stays the framework's — the tools, the skills, the standards and the documents of its own directory, the source of the guide aside — **shall** carry a notice naming who holds the framework's copyright and the licence it is distributed under.

**Rationale.** The licence asks that its notice travel with every copy, and none of the files the installer copies said who holds the copyright or on what terms: a tool lifted from an installed project carried the framework's name and version and no notice of whose it was.
The notice goes into the file rather than beside it, because a file is what gets copied on, one at a time.
The standards may be edited into the project's own (`FR-INIT-060`), and the notice stays true of what of ours they keep.
The pre-commit hook and the pipelines carry none: they are the project's files, shared with every other check it runs (`FR-INIT-290`), and the gate they call carries the notice as a tool.
A file that becomes the project's own — its specification, its constitution, its agent guides once filled in — carries none, because a copyright line there would claim the project's document as ours; nor does the decision template, which a project copies into every decision it writes.
The source of the guide is the one file the installer copies that stays ours and carries none: its text is written into the region of the project's own `AGENTS.md` (`FR-INIT-370`), so a line of ours in it would arrive inside their document for the same reason.
It came with the directory in 0.22.0, and the statement named the three classes of file that existed before it; the documents of the directory joined the set on 2026-10-02 and the guide's source was excused by name.

### FR-INIT-290 — The hook and the pipelines are the project's files

```yaml
status: implemented
verification: T
derives_from: [FR-CI-180]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-09-30
```

The installer **shall** never write into `.githooks/pre-commit`, `.github/workflows/srs.yml` or `.gitlab-ci.yml` where the file already exists, with `--force` or without.

**Rationale.** A project runs every pre-commit check it has through one hook, and in GitLab every job through one file; neither belongs to the framework once the project has one, and a copyright line of ours in it would claim the project's file as ours.
Before this they were refreshed with `--force` where they carried the marker, which rewrote whatever the project had added beside the gate.
Nothing is lost by leaving them alone: the gate is a tool refreshed with the rest (`FR-CI-180`), and all they hold of ours is a call to it.

### FR-INIT-300 — The installer says whether the hook runs the gate

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-290]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-09-30
```

After installing or upgrading, the installer **shall** report whether git runs a pre-commit hook in the target and whether that hook, or the pre-commit framework, husky or lefthook configuration that runs it, calls `srs-dd/tools/srs_gate.py`, giving what to add where it does not.

**Rationale.** The installer no longer writes into a hook that exists (`FR-INIT-290`), so whether the gate runs before a commit depends on a line somebody else adds, and on git running the hook at all; an install that says nothing of either leaves a gate that looks installed and never runs.
A hook manager's own file is a shim that calls its configuration, so the configuration is what is read.

### FR-INIT-310 — The installer says whether a pipeline runs the gate

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-290]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-09-30
```

After installing or upgrading, the installer **shall** report whether any file under `.github/workflows/`, or `.gitlab-ci.yml`, calls `srs-dd/tools/srs_gate.py`, giving the step to add where none does.

**Rationale.** The pipeline is the gate nobody can skip, and it is the project's file (`FR-INIT-290`), so the installer says whether it calls the gate rather than making it.
Any workflow will do, because a project's other workflows — a release, a deployment — have no reason to run it, and naming each of them would be a false alarm.
These are the two services the starters are for; a pipeline elsewhere is read by the agent (`FR-SKILL-420`).

### FR-INIT-320 — The framework's files live in one reserved directory

```yaml
status: implemented
verification: T
derives_from: [FR-CI-180]
depends_on: [FR-INIT-270]
refines: []
conflicts_with: []
code: [tools/srs_init.py, srs-dd/README.md]
tests: [tests/installer-smoke.sh, tests/adopt-smoke.sh]
created: 2026-10-01
```

The installer **shall** put every file that stays the framework's — the tools, the standards of the specification and of each layer the project keeps, the method's articles, the source of the framework's guide and the licence — under `srs-dd/` in the target, and write nothing of the framework's elsewhere but the procedures under `.claude/skills/` and the region of the guide that `FR-INIT-370` names.

**Rationale.** After an install two authors wrote into the same places, and the border between them was only implied: a marker in a file, a prefix in a name, a row in a table. Articles of the constitution were numbered by both, each taking the next free number; the guide held the framework's numbered rules and the project's additions in one file that `--force` replaced whole; `tools/` and `.claude/skills/` held files of both with nothing saying which an upgrade rewrites. The first visible case was ART-SRS-100, written twice on 2026-09-25 and 2026-09-29 by the framework and by a project; the others are of the same kind.
Ownership is now a place: what is under `srs-dd/` is the framework's and an upgrade rewrites the files it owns there, naming any other path it finds (`FR-INIT-380`), what is outside is the project's and the framework writes it once as a starter or never. The procedures are the one exception, because the client looks for them under `.claude/skills/` and nowhere else (`FR-SKILL-450`).
This repository is the first project of its own method, and here the rule is literal: its `srs-dd/` is the source the installer copies, not a copy; `tools/` keeps what never ships — the installer, the release, the measurements, the local self-test — and `skeleton/` keeps only the starters of the project's files.

### FR-INIT-330 — A directory of that name that is not the framework's is refused

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-320]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-10-01
```

The installer **shall** refuse to install into or upgrade a target where `srs-dd/` exists and its `README.md` carries no marker of the framework.

**Rationale.** The directory is the one place the installer rewrites without asking, so a directory of that name that somebody else made is the one thing it must never touch: overwriting it would be the clobbering the marker on every precious file used to prevent, now concentrated in one place. The marker lives in the directory's `README.md`, which says what the directory is and which version wrote it.

### FR-INIT-340 — An upgrade moves what an earlier version wrote elsewhere

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-320]
depends_on: [FR-INIT-300, FR-INIT-310]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-10-01
```

On upgrading a target installed before the directory existed, the installer **shall** move into `srs-dd/` each file an earlier version wrote under `tools/` or as a standard under `specs/`, `grounds/` or `arch/`, delete the copy it leaves behind, and report the new path every hook, pipeline and guide has to call.

**Rationale.** A project installed before 0.22.0 has the tools under `tools/` and the standards beside what they govern, and its hook, pipeline and guide call them there. The upgrade is the one moment both layouts are in front of the installer, so it is the one that moves the files; the hook and the pipeline are the project's (`FR-INIT-290`) and the report that already says whether they call the gate (`FR-INIT-300`, `FR-INIT-310`) now says the path they have to call. Deleting the old copies matters: a stale `srs-dd/tools/srs_check.py` beside a current `srs-dd/tools/srs_check.py` is two checkers, and the project's gate would run whichever its pipeline still names.

### FR-INIT-350 — The installer refuses an area named like a directory the checker skips

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-300]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-10-01
```

The installer **shall** refuse an area whose name, in lowercase, is a directory the checker skips under `specs/` — `adr`, `archive`.

**Rationale.** An area named `ADR` installs without a word and its file reads fine at the top of `specs/`; grouped into its own folder, `specs/adr/`, it vanishes — the checker skips that folder as the decision log and reports no requirements and no errors. Run on 2026-09-30: `--areas ADR` accepted, the folder made, `Requirements: 0. No errors.` The checker refuses the name as well (`FR-CHK-300`); the installer refuses it first, where the person who chose it is still at the prompt.

### FR-INIT-360 — The agent guides and `.gitattributes` are the project's files

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-290]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-10-01
```

The installer **shall** write `AGENTS.md`, `CLAUDE.md` and `.gitattributes` only where the file is absent, with no `--force` to rewrite them.

**Rationale.** The three were precious: refreshed with `--force` where the marker survived, which replaced whatever the project had added — the reason the upgrade notes of 0.21.0 had to tell a project whose guide was its own which lines to add by hand. They join the hook and the pipelines (`FR-INIT-290`): starters, written once, the project's from then on. What the framework needs in them is small and travels another way — the pins of the generated files in `.gitattributes` are named by the report when missing, and the framework's rules in the guide are a region of their own (`FR-INIT-370`). With them, nothing is precious any more and `--force` has nothing left to do; `FR-INIT-060` and `FR-INIT-240` are superseded by this requirement and `FR-INIT-320`.

### FR-INIT-370 — The framework's region of the guide is refreshed in place

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-360]
depends_on: [FR-SKILL-440]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-10-01
```

On every install and upgrade, the installer **shall** rewrite in the target's `AGENTS.md` only the region between the first line holding nothing but `<!-- srs-dd -->` and the next line holding nothing but `<!-- /srs-dd -->`, replacing it with the current text of `srs-dd/guide.md`, and leave every line outside the region as it is, reporting the text to add where the guide carries no such region.

**Rationale.** An import mechanism exists only in Claude Code's `CLAUDE.md`; every other client reads `AGENTS.md` as plain text, and a line that says to read another file is followed as well as any instruction is — which is not a mechanism. The rules of the method therefore have to be in the guide's text, and the only way to keep them current without touching what the project wrote around them is a region with a border the installer can find. The region is the framework's by place, as the directory is; the file is the project's.

### FR-INIT-380 — What the installer does not own in its directory is reported

```yaml
status: implemented
verification: T
derives_from: [FR-INIT-320]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-10-02
```

After installing or upgrading, the installer **shall** report every path under `srs-dd/` in the target that it did not write, naming each.

**Rationale.** The directory is declared the framework's and the installer refreshes the files it owns there, so a file somebody else put beside them stayed for ever and nothing said so: driven through a sandbox on 2026-10-01, `srs-dd/notes-of-mine.md` and `srs-dd/tools/mytool.py` survived three upgrades unmentioned. `FR-INIT-330` does not reach them, because it reads the marker in `srs-dd/README.md` alone and a stranger's file beside a marked README never makes the directory somebody else's.
It is reported and not deleted. Deleting a file it did not write is what `ART-SRS-030` reserves for the user's explicit confirmation, and `FR-INIT-340` deletes only copies that carry the marker; a path under `srs-dd/` is both at once — in a place declared ours, and written by somebody else — so the installer names it and leaves the choice where it belongs.
Naming each rather than counting them: the list is what a maintainer acts on, and a count says only that something is there.
