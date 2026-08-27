# Functional requirements — chk

The checker, `tools/srs_check.py`: what it validates, what it generates, and
how it reports. Everything here is observable from a single run.

### FR-CHK-010 — Well-formed and unique identifiers

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

If a requirement identifier is repeated or does not match
`<TYPE>-<AREA>-<NNN>` with an area declared in the configuration, the checker
**shall** report it as an error naming both occurrences.

**Rationale.** Identifiers are the only stable handle on a requirement; a
duplicate silently splits its history in two.

### FR-CHK-020 — Exactly one bolded modal verb

```yaml
status: implemented
verification: T
derives_from: [INV-SPEC-060]
depends_on: [FR-CHK-090]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

If the statement of a requirement carries no bolded modal verb from the
project lexicon, or carries more than one, the checker **shall** report it as
an error.

**Rationale.** The verb is where binding force lives, and two verbs in one
statement are two requirements — the error message says so, because splitting
them is the fix.

### FR-CHK-030 — Links resolve

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

If a link field names a requirement that does not exist, or names the
requirement itself, the checker **shall** report it as an error.

**Rationale.** A dangling link is worse than no link: it reads as coverage
that was never there.

### FR-CHK-040 — No cycles in the derivation graph

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-030]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

If `derives_from` and `refines` links together form a cycle, the checker
**shall** report it as an error listing the requirements on the cycle.

**Rationale.** The derivation graph answers "why does this exist"; a cycle
means the answer is circular, and it also breaks the tree view.

One graph over both kinds of link, not one per kind. This said "or" and was
built as two separate walks, so `A derives_from B` with `B refines A` — A
exists because B does, and B is a special case of A — was circular in exactly
the way the sentence above describes and seen by neither walk. The two fields
draw one graph because they answer one question; the message still names which
kinds a cycle was drawn in, so a cycle in one of them reads as it always did.

### FR-CHK-050 — A requirement being realized names where

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

The checker **shall** report as an error an `implemented` or `partial`
requirement with an empty `code` field.

**Rationale.** The `code` field is half of the only machine-checkable bridge
between the specification and the tree, and a requirement claiming to be
built while naming nowhere has cut it.

Both statuses the standard defines as being realized, not `implemented`
alone. The lifecycle separates them by how much is built and not by whether
anything is: `deferred` is the state for approved and not yet started, so a
`partial` with an empty `code` field is either a status nobody updated or a
half that was built and never written down. Reported for the same reason as
the other. FR-CHK-075 and FR-CHK-140 already name both statuses; this one
said `implemented` alone, which read as a decision and was an oversight.

The second half of what this once said — that a path named must exist — is
FR-CHK-055. Split under INV-SPEC-060 rather than widened in place: a
statement carrying two obligations has no answer to what passing it means,
and the fixture for either half would have kept the requirement looking
verified while the other went missing. The same reason, and the same
remedy, as FR-CHK-070 and FR-CHK-075.

### FR-CHK-055 — A path a requirement names exists

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-17
```

The checker **shall** report as an error a `code` or `tests` entry that
names a path absent from the repository.

**Rationale.** A stale path turns the traceability matrix into fiction: the
row is there, the file is not, and every reader downstream believes the
link. Both fields, because a test that moved is as invisible as a source
file that did.

Carved out of FR-CHK-050, which stated this and the obligation to name
something in the same sentence. The number is new because identifiers are
never reused (INV-SPEC-010) and the half that stays with the old number is
the one its statement opened with — the reading FR-CHK-070 and FR-CHK-075
already established here.

### FR-CHK-060 — Lifecycle consistency

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

The checker **shall** report as an error a `superseded` requirement without
`superseded_by`, and a requirement carrying `superseded_by` under any other
status.

**Rationale.** A requirement claiming supersession without naming what
superseded it is a dead end for whoever follows the reference; the reverse
pairing is a copy-paste slip.

Cancelling with nothing to replace it is a different act with a status of
its own (INV-SPEC-050), and this rule does not stand in its way: the second
half already covers it, because a `withdrawn` requirement carrying
`superseded_by` is one that does have a successor and should say
`superseded` instead.

### FR-CHK-070 — Implementation ahead of approval is a warning

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

When a requirement has status `draft` and a non-empty `code` field, the
checker **shall** warn that implementation ran ahead of approval, naming the
requirement.

**Rationale.** This is the approval queue of a harvested specification: the
warning list is exactly what the maintainer has to rule on, which is why it
is a warning and not an error.

A queue is read as a list, so every line has to stand on its own — hence
the identifier. A file and a line locate the requirement and name nothing:
the number moves with the next edit above it, cannot be grepped for in a
pipeline log, and cannot go into a plan that references numbers.

### FR-CHK-075 — A realized requirement resting on a draft is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-030]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-12
```

When an `implemented` or `partial` requirement derives from, depends on or
refines a `draft`, the checker **shall** report it as a warning naming both.

**Rationale.** Built work standing on something nobody has approved is the
other half of the approval queue, and it is the half that costs: the draft
may still be reworded or refused, and what was built to it is already in the
tree. A warning rather than an error for the same reason as FR-CHK-070 — a
harvested specification is full of these on the first run, and a gate that
refuses the commit stops the harvest instead of guiding it.

Both ends are named because both are what the reader acts on: one of them
gets approved, or the other gets revisited, and a message that identified
the dependant by file and line left the choice half-stated.

`conflicts_with` is not counted here, as it is not in FR-CHK-190: diverging
from a draft is a position, not a dependency, and nothing about it is
waiting on approval.

### FR-CHK-080 — Annotations are cross-checked, never required

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-050]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

The checker **shall** cross-check the `implements:` and `verifies:`
annotations found under the configured code and test roots against the
specification, treating an annotation that names an unknown requirement in
a declared area as an error and every other mismatch as a warning.

**Rationale.** An annotation is a claim made at the code, and a claim that
resolves to nothing is worse than no claim: it reads as traceability that
was never there.

An annotation naming a cancelled requirement is one of those mismatches,
and it is dead in both directions: it is reported, and it claims nothing —
so the file it sits in counts as unclaimed for FR-CHK-210 unless something
live speaks for it. This covered `superseded` alone until INV-SPEC-050 gave
a requirement a second way to be over, and a `withdrawn` one left the
annotation reading as live traceability to a decision to do nothing.

This carried the clause "never reporting a file that carries none" while
annotations were optional, and the clause did two jobs — it described this
rule and it forbade a different one. ADR-0014 settles that a file a
requirement names is obliged to say so, which the prohibition stood in the
way of. What this requirement covers is unchanged: the annotations that are
there, judged against the specification. What is asked of a file that
carries none belongs to FR-CHK-200 and FR-CHK-210, where it can be argued
on its own terms and priced by the rules those two carry.

### FR-CHK-090 — The lexicon, not a language

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/adopt-smoke.sh]
created: 2026-08-07
```

The checker **shall** take the modal verbs, negation words and rationale
markers it recognizes from `specs/srs-config.json`, so that a specification
written in any natural language validates on the same rules.

**Rationale.** The one feature that cannot be retrofitted: hard-coding
English would have made every non-English project translate its
specification to use the tooling.

### FR-CHK-100 — A readable failure for a broken configuration

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-090]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

If `specs/srs-config.json` is unreadable, is not a JSON object, or holds a
key whose value is not a list of non-empty strings, the checker **shall**
exit with status 2 after naming the offending key.

**Rationale.** A configuration mistake would otherwise surface as a regex
compilation traceback, which tells the user nothing about what to fix.

### FR-CHK-110 — Code blocks are opaque

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_check.py, tools/srs_parse.py]
tests: [tests/checker-rules.sh]
created: 2026-08-07
```

While parsing a fenced code block, the checker **shall** ignore headings,
modal verbs and rationale markers inside it.

**Rationale.** The standard itself, and every specification that documents
its own format, contains example requirements; without this they would be
parsed as real ones.

### FR-CHK-120 — Strict mode

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-070]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/spec-check.sh, tests/checker-rules.sh]
created: 2026-08-07
```

Where `--strict` is given, the checker **shall** exit non-zero when warnings
were reported even if no error was.

**Rationale.** Warnings that never fail anything accumulate until nobody
reads them; a project decides once, in its CI configuration, whether it
tolerates them.

### FR-CHK-130 — A baseline tag without a log entry is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-070]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/installer-smoke.sh, tests/checker-rules.sh]
created: 2026-08-08
```

If the repository holds a `spec/vX.Y.Z` tag that `92-baselines.md` has no row
for, the checker **shall** report it as a warning naming the tag.

**Rationale.** The row is what makes a baseline and the tag is a bookmark on
it (INV-SPEC-040), so a tag standing alone claims to freeze something no
reader can look up — this project left three such tags behind before the log
caught up with them. A warning rather than an error, so that a baseline
halfway written does not block the work; `--strict`, which the gate runs,
closes it. Nothing is reported where the tags are absent: a project that
never tags is keeping a perfectly good log. A checkout where git cannot
answer at all is the other case and not this one — FR-CHK-220 says what
happens there, and why the two are not the same silence.

A log that is not there is a third case and belongs to this rule. It has a
row for nothing, so the condition above holds for every tag at once — and
that was answered with silence, because the rule opened the file first and
returned when it could not. The most complete form of the defect was the one
form nobody heard about.

### FR-CHK-140 — A requirement verified by test and carrying none is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-060]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-10
```

Where a requirement is `implemented` or `partial`, says it is verified by
test, and lists none, the checker **shall** report it as a warning naming
the requirement.

**Rationale.** The data has been collected all along and shown only to
whoever asked for `--coverage` — a report nobody runs on the way to a
commit. A fact worth reporting is worth reporting where it is read.

Only where the method is `T`, and that is the whole difference between a
rule with a bottom and noise. Of the twenty-nine requirements in this
project's own specification that listed no test, ten said `T` — those were
violations of ART-050, and the harness that verifies the checker's rules
cleared them. The other nineteen say `I` or `A` and will never carry a
test, by design; reported, they would be nineteen permanent warnings
burying the ten that meant something. A warning rather than an error
because a project mid-harvest would otherwise be unable to commit at all.

### FR-CHK-150 — A requirement no link touches is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-030]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-10
```

Where a requirement that has not been cancelled neither links to another nor
is linked to by one, the checker **shall** report it as a warning naming the
requirement.

**Rationale.** A missing link is invisible: the checker proves that what is
written resolves, never that something was left out, and an empty
`depends_on` is valid on every requirement in the file. Total isolation is
the one case where the omission shows — a requirement connected to nothing
is either genuinely standalone or, far more often, one whose links nobody
wrote. It is also what makes a derived work plan degenerate into a flat list
with no order, so the cheapest place to notice it is here.

A cancelled requirement is outside this, because it has no link left to
forget. `superseded` escaped the report by accident — its `superseded_by`
counts as a link, so the requirement was never isolated — while `withdrawn`
names no successor by definition and so tripped a warning that no reader
could act on: withdrawing something nothing pointed at turned a `--strict`
gate red for having done exactly what was intended. What was accidental for
one is now deliberate for both.

### FR-CHK-160 — What a rule costs is the project's to set

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-120]
refines: []
conflicts_with: []
code: [tools/srs_check.py, tools/srs_view.py]
tests: [tests/checker-rules.sh]
created: 2026-08-10
```

The checker **shall** let a project lower a rule to a report or silence it
altogether — for the whole project in its configuration, or for one
requirement in that requirement's own block.

**Rationale.** A gate is only obeyed while its output is worth reading, and
a rule that cannot be tuned is a rule that teaches people to ignore the
whole run. Strict mode already moves severity in one direction
(FR-CHK-120); this is the other. Per requirement rather than only
per project because the honest case is singular — this one requirement is
verified by inspection and will never list a test — and an exemption written
in the block is diffed in review and dies with the requirement it excuses,
which a list of identifiers in a configuration file does neither.

The two levers meet strict mode without contradicting it: a rule lowered to
a report no longer produces a warning, and `--strict` fails on warnings
(FR-CHK-120), so lowering is what makes a gate survivable while raising
stays the default. Silence removes the rule from the run entirely and is the
heavier of the two admissions.

### FR-CHK-170 — A missing required key is named as missing

```yaml
status: implemented
verification: T
derives_from: [IF-SPEC-010]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-10
```

Where a requirement omits a key the format requires, the checker **shall**
report that key as missing rather than as holding a bad value.

**Rationale.** Omitting `verification` is answered today with "method '' is
not one of T/D/I/A", which describes the symptom and hides the cause: the
reader looks for a typo in a value that was never written. The distinction
also has to exist in the code before the format can promise anything about
optional keys, since obligation is currently an accident of validating
values.

### FR-CHK-180 — A retired key is reported with what replaced it

```yaml
status: implemented
verification: T
derives_from: [IF-SPEC-010]
depends_on: [FR-CHK-170]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-10
```

Where a requirement uses a key a later version of the format renamed or
withdrew, the checker **shall** report it as an error naming the version
that did so and the key that replaced it, where one did.

**Rationale.** Renaming a key should not happen and one day will. The
project that meets it is holding a specification the framework can no longer
read, and the difference between an afternoon and a week is whether the tool
says "`depends` became `depends_on` in 0.14.0" or "unknown key". An error
rather than a warning because, unlike an unrecognised key, this one is known
to be wrong and known to be fixable. The framework rewrites nothing itself:
the specification belongs to the project, and a mechanical rename is what
agents and `sed` are for.

### FR-CHK-190 — A requirement resting on a withdrawn one is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-SPEC-050]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-12
```

When a requirement that has not been cancelled derives from, depends on or
refines a `withdrawn` one, the checker **shall** report it as a warning
naming both.

**Rationale.** Withdrawing something is the one edit that can quietly break
requirements it never touched. A draft resolves — approve it and everything
resting on it is well again, which is why FR-CHK-075 treats that as a queue.
A withdrawal does not resolve: the ground is gone for good, and the
requirement standing on it now derives from, or is meaningless without, a
decision to do nothing.

Every live status rather than `implemented` and `partial` alone. What is
wrong here is structural, not a matter of how far the work got: a `deferred`
requirement whose parent was withdrawn is approved work with nothing under
it, and it will be built by somebody who never reads the parent.

A warning, not an error, and the reason is the same one that decided
ADR-0013 against refusing a withdrawal outright. An error would mean the
build breaks the moment the status changes and stays broken until every
dependant is resolved in the same commit — which forbids staging the work,
the answer that decision names for anything with a large tree. A warning
says the same thing and lets the maintainer choose the order; `--strict`
still fails on it wherever a project wants that (FR-CHK-120), and the rule
carries a name so a project can decide what it costs (FR-CHK-160).

`conflicts_with` is not counted. A requirement diverging from a withdrawn
one has lost nothing it was standing on — the divergence is simply beside
the point now, and reporting it would leave every deliberate trade-off in a
specification outliving its subject as noise.

### FR-CHK-200 — A file a requirement names says so

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-080, FR-CHK-055]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-17
```

Where an `implemented` or `partial` requirement names in its `code` or
`tests` field a file the checker scans for annotations, the checker
**shall** report as a warning a file that does not name that requirement
back.

**Rationale.** The forward half of this link has been checked since the
beginning and the backward half never was, and the missing half is the one
that decays. A field naming a path is the specification's claim that a
requirement is realized there; the annotation is the file's own claim about
why it exists, made by whoever is editing it. Only the second notices when
a file is gutted, split or repurposed and stops deserving the entry that
still points at it. Inverting the fields cannot supply it — that yields the
requirements which claim the file, never whether the file agrees
(ADR-0014).

Four combinations, and each is somebody's: named and annotated is silent;
named and not annotated is this rule; annotated and not named is
FR-CHK-080's `annotation-unlisted`; neither is FR-CHK-210. The rule is
written to the one row nothing covered.

Scoped to the files the checker reads, because a `code` field names more
than source. When this was written a fifth of this project's
requirement-to-file pairs pointed at things no annotation belongs in: the
standard it ships, every skill written in markdown, the CI templates, the
generated matrix, and one entry that is a directory. A rule demanding a
comment in `specs/README.md` would be answered by deleting the rule.

Scoped to the two statuses that claim realization for the same reason
FR-CHK-075 and FR-CHK-140 are: a `draft` carrying code is a harvested
proposal, and a harvest that also has to be annotated before the maintainer
has approved anything is a harvest nobody finishes.

A warning rather than an error, and it carries a name so a project can
lower or silence it (FR-CHK-160). The cost is not hypothetical: this
project carried no annotation at all when the rule was written, so it fires
once per in-scope pair on the day it ships — well over a hundred of them,
thirty in a single file. That is a queue of mechanical work, not a defect —
but a project meeting it mid-adoption must be able to decide when to take
it, which is what the severity lever is for. This project lowered the rule in
its own configuration while the queue lasted, and the queue is worked off:
the `rules` key is gone from `specs/srs-config.json`, no requirement carries
an `exempt` line, and the rule runs at its default severity on everything.

### FR-CHK-210 — A file neither end claims is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-080]
refines: []
conflicts_with: []
code: [tools/srs_check.py, tools/srs_init.py]
tests: [tests/checker-rules.sh, tests/adopt-smoke.sh, tests/installer-smoke.sh]
created: 2026-08-17
```

Where no requirement that has not been cancelled names a file under the
configured code or test roots, and that file carries no annotation, the
checker **shall** report it as a warning naming the file.

**Rationale.** The matrix lists code files no requirement references and
stops there, which makes the fact readable and never actionable; nothing at
all is said about test files, so a suite nobody claims is invisible in both
directions. A file neither end claims is either behaviour with no
requirement behind it — the thing this framework exists to prevent — or a
helper that will never have one.

A cancelled requirement counts for neither end, and this is the case the
rule exists for as much as the plainly orphaned file. Withdrawing a
requirement leaves its code where it was; counting the dead `code` field as
somebody naming the file would make a withdrawal the quietest way to take
code out of sight, which is the opposite of what INV-SPEC-050 was for.

Any annotation at all, rather than one that resolves. A file carrying
`implements:` for a requirement that was cancelled, or never existed, has
said something about itself and has already been answered by FR-CHK-080 —
with the line and the identifier, which is more than this rule can give.
Reporting it here as well would put two findings on one file, the second of
them saying it claims nothing while the first quotes what it claims.

Taken with FR-CHK-200 this amounts to every file under the roots accounting
for itself, which is the state worth reaching and the wrong state to demand
on the first day. A project adopting the framework has code in the
thousands of files and requirements in the dozens; this rule fires on all
of it, and a wall is not a queue. So an adopted target starts with it
silenced in its configuration, and switching it on is what finishing the
adoption means (ADR-0014). A fresh project has nothing to silence and
starts strict.

The per-requirement lever does not reach here, and cannot: the finding is
about a file, and there is no requirement to write `exempt` in. A project
that keeps fixtures and helpers under its test roots tunes this rule in its
configuration or lives with the list — the same position `baseline-without-row`
is in, and for the same reason.

### FR-CHK-220 — History that cannot be read is said to be unread

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-130]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-25
```

Where a rule needs the specification's history and that history cannot be
read, the checker **shall** report that it could not be read rather than
pass the rule.

**Rationale.** One rule reads history rather than files: the baseline tag
that no row in the log describes. It meets a wall in a checkout that is not
a repository, in an environment with no git on the path, and in a shallow
clone that carries no tags.

Two situations that look identical from inside the rule and are not. A
repository with no tags answers the question — there is nothing to report,
and a project that never tags keeps a perfectly good log, which is why
silence is right there. A checkout where git cannot answer at all leaves the
question unasked, and silence then reports the same green as a specification
that was actually checked. The two are told apart by how git exits: no tags
is a successful run with an empty list, no repository is a failure.

Reported as a note rather than a warning, so a project without git is not
failed for a dependency this framework does not require (NFR-SPEC-010). It
is the same rule the grounds layer states for the register's own history,
made separately because the two checkers share no code (ADR-0019).

### FR-CHK-230 — The matrix counts the same set the rules do

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
created: 2026-08-27
```

The traceability matrix **shall** count a file as referenced only where a
requirement that has not been cancelled names it.

**Rationale.** Three readings of one question, and the matrix was the only one
answering it differently. `FR-CHK-210` and `FR-VIEW-040` both say *a
requirement that has not been cancelled*, and the viewer's own code says why in
a comment: counted in, a withdrawal would quietly move its files out of the gap
list, and the two tools would describe one file differently in the same run.
The matrix said "no requirement references them" and meant any requirement,
cancelled or not — self-consistent, and the third answer in that run.

Its own number rather than a clause in `CON-SPEC-010`. That statement obliges
the matrix to be generated and never hand-edited; what a section of it counts
is a second obligation, and `INV-SPEC-060` is why they do not share a
sentence.

Scoped to the one reading. The *Incoming links* section keeps every link,
including those from cancelled requirements, because settling a withdrawal is
exactly the case that needs them whole — the same reason the viewer computes
its reverse links over every entry.
