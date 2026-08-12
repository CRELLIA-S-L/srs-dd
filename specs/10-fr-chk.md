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
derives_from: []
depends_on: [FR-CHK-090]
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
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
```

If `derives_from` or `refines` links form a cycle, the checker **shall**
report it as an error listing the requirements on the cycle.

**Rationale.** The derivation graph answers "why does this exist"; a cycle
means the answer is circular, and it also breaks the tree view.

### FR-CHK-050 — Realized requirements point at real code

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
```

The checker **shall** report as an error a requirement with status
`implemented` and an empty `code` field, and any `code` or `tests` entry that
names a path absent from the repository.

**Rationale.** The two fields are the only machine-checkable bridge between
the specification and the tree; a stale path turns the traceability matrix
into fiction.

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
```

The checker **shall** cross-check the `implements:` and `verifies:`
annotations found under the configured code and test roots against the
specification — never reporting a file that carries none — treating an
annotation that names an unknown requirement in a declared area as an error
and every other mismatch as a warning.

**Rationale.** Annotations are an optional second opinion; making them
mandatory would turn every source file into specification surface.

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
code: [tools/srs_check.py]
tests: [tests/checker-rules.sh]
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
tests: [tests/installer-smoke.sh]
```

If the repository holds a `spec/vX.Y.Z` tag that `92-baselines.md` has no row
for, the checker **shall** report it as a warning naming the tag.

**Rationale.** The row is what makes a baseline and the tag is a bookmark on
it (INV-SPEC-040), so a tag standing alone claims to freeze something no
reader can look up — this project left three such tags behind before the log
caught up with them. A warning rather than an error, so that a baseline
halfway written does not block the work; `--strict`, which the gate runs,
closes it. Nothing is reported where git or the tags are absent: a project
that never tags is keeping a perfectly good log.

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
