# Invariants and constraints

`INV-*` — properties that hold at all times · `CON-*` — constraints
imposed on the project rather than chosen by it.

### INV-SPEC-010 — Identifiers are immutable and never reused

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CHK-010]
refines: []
conflicts_with: []
code: [specs/README.md, tools/srs_check.py]
tests: []
created: 2026-08-07
```

A published requirement identifier **shall** keep its meaning forever: a
cancelled requirement is retained in a status that says it was cancelled,
and its number is never given to anything else.

**Rationale.** References to requirements outlive the requirements — in
commit messages, review threads, and other projects' documents. A reused
number turns every one of them into a lie that reads as truth.

Which status that is belongs to the lifecycle rather than here. This
sentence named `superseded` and its pointer while that was the only way a
requirement could be cancelled; there are two now (INV-SPEC-050), and
listing them in both places is the second source of truth the standard
warns against.

### INV-SPEC-020 — Links are stored in one direction only

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-CHK-030]
refines: []
conflicts_with: []
code: [specs/README.md, tools/srs_check.py]
tests: []
created: 2026-08-07
```

The specification **shall** record a link between two requirements in one
direction only, leaving the reverse relation to be computed.

**Rationale.** A link written at both ends is a link that will one day
disagree with itself, and nothing would say which end was right.

Between two requirements, and not between a requirement and a file. This
said "only forward links" while annotations were optional and could be read
as a second opinion rather than a record; making them obligatory
(ADR-0014) would have put the sentence in the way of its own tooling. The
two cases are not alike. The reverse of `derives_from` is computed, carries
no information the forward link lacks, and storing it creates a second copy
of one fact. The reverse of `code` is not computed and is not a copy: the
field is the specification's claim that a requirement is realized in a
file, the annotation is that file's own claim about why it exists, and they
are made by different people at different times. Their disagreement is
something to report, not corruption to prevent — and it is reported on
every run, which is the condition this rationale is really about.

### INV-SPEC-030 — A baseline and a release are separate acts

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_baseline.py, tools/srs_release.py, specs/README.md]
tests: [tests/baseline-smoke.sh, tests/release-smoke.sh]
created: 2026-08-09
```

A specification baseline and a release **shall** be cut as separate acts,
neither creating the other's tag nor constraining the other's number.

**Rationale.** They answer different questions — a baseline freezes what the
system must do, a release ships what it does — and they move at different
rates: a specification can be frozen mid-development, and a release can ship
with no requirement touched. One command doing both made every release mint
a baseline, including one whose own row records that nothing had changed.

### INV-SPEC-040 — The log defines the baselines

```yaml
status: implemented
verification: T
derives_from: [INV-SPEC-030]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py, tools/srs_baseline.py, specs/README.md]
tests: [tests/baseline-smoke.sh]
created: 2026-08-09
```

The baseline log **shall** define the specification's baselines, a
`spec/v*` tag naming the revision of one only where such a tag was made.

**Rationale.** Making a tag from a script needs a git client configured for
it, and many developers drive git through an application that keeps its own
credentials and signing; a process resting on the tag is a process resting
on the client. A row is a file, and committing files is the one thing every
client does. Where a tag exists it names the revision — rows have been
written a release late for this project's whole history, so their own commit
is not what those tags froze — and where none exists, the commit that added
the row is the baseline.

### INV-SPEC-050 — A requirement can be withdrawn as well as replaced

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [INV-SPEC-010]
refines: []
conflicts_with: []
code: [specs/README.md, tools/srs_check.py, tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-12
```

A requirement cancelled with no successor **shall** be retained with the
status `withdrawn`.

**Rationale.** The lifecycle ended at `superseded`, which the standard
defines as cancelled *with a successor* and the checker enforces to the
letter, so a requirement dropped because the behaviour itself was abandoned
had nowhere to go. What happened instead was worse than a dead end: it
stayed `deferred`, where it reads as approved and merely late — and nothing
here measures lateness, because a requirement carries no date and no rule
counts how long one has stood.

FR-CHK-060 argues the opposite case, that a cancelled requirement without a
successor is a dead end for whoever follows the reference. A reference that
arrives at *withdrawn, and here is why* is not a dead end; it is the answer.
The dead end is the one that arrives at a promise nobody intends to keep.

A sixth status rather than `superseded_by` made optional, because the two
facts are different and both are worth counting: replaced by that one, and
dropped with nothing in its place. Collapsed into a single status, the
dashboard's census, the baseline row and the graph all lose the ability to
tell them apart.

The cost is a change to a released format, and not of the cheap kind. The
metadata block was built to gain a key without breaking anyone: one the
format declares neither required nor optional is no error (IF-SPEC-010).
The status field has no such cushion — a value it does not know is a hard
error — so a checker already installed in another project rejects a
specification written against this standard until it is upgraded. What it
buys is a state the framework has never had; the alternative was to keep
writing as though requirements are never abandoned.

What the status leaves open — what happens to requirements standing on the
one being withdrawn — is settled in ADR-0013 and carried by FR-CHK-190 and
FR-SKILL-150.

### INV-SPEC-060 — A requirement states one obligation

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [specs/README.md]
tests: []
created: 2026-08-17
```

A requirement **shall** state exactly one obligation.

**Rationale.** A compound requirement leaves "it passes" undefined. FR-VIEW-060
named six things under a single verb — search, filters, a dashboard, a graph,
links in both directions, nothing over the network — and three of the six went
unverified across several releases while the requirement stood `implemented`
and its `tests` field stood filled. Nothing was wrong on paper, because there
was no paper to be wrong: one slot cannot record the state of six obligations.
The same reading is INCOSE's rule R20, which treats a combinator as the signal
to split and names this exact consequence at verification time.

The mechanical half is FR-CHK-020: two bolded verbs are two requirements, and
the checker says so. The other half is out of its reach and always will be. A
single verb carrying a list of objects is as compound as two verbs, and what
reads as a list depends on the sentence and on the language it is written in —
the argument FR-SKILL-120 makes against word lists applies here word for word.
So this is held by the procedures that write statements and by whoever reviews
them, exactly as INV-SPEC-010 is: nothing can prove a number was never reused
either.

**A list is not by itself a second obligation**, and reading it as one would
condemn three quarters of this specification. FR-CHK-030 reports a link that
does not resolve or that points at its own requirement; FR-CHK-090 takes three
word lists from the configuration; IF-CI-020 gives three exit codes. Each is
one act stated over the cases it covers, and splitting them would produce
requirements that cannot be read apart — worse, for an exit code table, it
would destroy the only thing a caller binds to, which is that the codes are
these and no others.

What makes a list compound is that its items are separable: each could be
built, shipped and called done while the others were missing, and a reader
told "that one is implemented" would have no way to notice. That is the state
FR-VIEW-060 was in — search, filters, a dashboard, a graph and links in one
sentence, three of them verified, the requirement standing green for three
releases while the rest were discovered one at a time. The question to ask of
a list is therefore not how long it is but whether the sentence could be half
true without anybody being able to say so.

The price is more requirements. FR-VIEW-060 is six of them, each with a number
that can never be reused, its own links and its own `tests` field. That is the
point rather than the cost: a `tests` field is worth reading only when what it
answers for is one thing.

Written after the passage in `specs/README.md` that carries it, which is the
shape FR-SKILL-090 warns about — the rule was sharpened first and only then
noticed to have no number to be cited by. Recorded that way rather than
backdated.

### INV-GND-010 — Hypothesis identifiers are immutable and never reused

```yaml
status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [grounds/README.md, tools/srs_grounds.py]
tests: []
created: 2026-08-20
```

A published register identifier **shall** keep its meaning forever: a
cancelled entry is retained in a status that says it was cancelled, and its
number is never given to anything else.

**Rationale.** `INV-SPEC-010` makes this promise for requirements and gives
the reason: references outlive what they refer to. Here it matters more, not
less. A refuted hypothesis is cited in the decision that removed the feature
standing on it, and a declined one exists precisely so that the same question
returning in six months is answered from the record. A number handed to
something else turns both citations into quiet lies.

Stated for the register rather than inherited from the requirement invariant
because the two registers are separate and nothing makes a promise about one
apply to the other.

### INV-GND-020 — A bet is recorded in one direction only

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [grounds/README.md, tools/srs_grounds.py]
tests: []
created: 2026-08-20
```

The register **shall** record which requirements rest on a hypothesis in the
bet alone, leaving what a requirement rests on to be computed.

**Rationale.** The same rule `INV-SPEC-020` states for links between
requirements, and here it is not a preference but the only available shape:
the subsystem never writes into a requirement file, so the requirement cannot
carry its half. Computing the reverse is what `srs_view.py --json` already
does for requirements, and the register does it for bets.

### INV-GND-030 — An unclaimed requirement is a reading, not a defect

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [INV-GND-020]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

A rule of the grounds layer **shall not** require that a requirement be
named by a bet.

**Rationale.** The load-bearing detector of this subsystem is the requirement
no hypothesis stands behind. It is the signal that the product acquired
something nobody can say why it has — and every traceability practice that has
met this problem destroys the signal by demanding completeness. Where a link
is mandatory it gets invented, and an invented link is worse than an absent
one, because it looks like knowledge. The observation reported from the field
is blunt: once every element traces to a goal, the tracing no longer clarifies
anything and merely confirms that somebody drew a line.

So the absence is protected rather than forbidden. What may be asked of an
author is a declaration with a reason — one line saying this requirement rests
on no hypothesis and why — and the declaration retires itself when a real bet
appears. What may never be asked is the bet.

Verified by inspection, not by test: this forbids a rule from existing, and
what a suite can assert is that today's rules do not require a bet, which is
a reading of the rule set rather than of behaviour. The same position
`INV-SPEC-010` is in.

### INV-GND-040 — A hypothesis states exactly one claim

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [IF-GND-010]
refines: []
conflicts_with: []
code: [grounds/README.md]
tests: []
created: 2026-08-20
```

A hypothesis **shall** state exactly one claim about the world.

**Rationale.** `INV-SPEC-060` gives the argument for requirements and it
carries over without change: a compound leaves "it holds" undefined. Here the
undefined thing is sharper, because a hypothesis carries a single threshold
and a single verdict. "Studios need time roll-up and will pay for reporting"
has one `refuted_if`, and a measurement that settles half of it settles
nothing while the record says `supported`.

Held by whoever writes the statement and by whoever reviews it, as the
requirement invariant is. No script can tell a second claim from a list of
cases, and no word list will, for the reason `FR-SKILL-120` gives about the
qualities no checker reaches.

### CON-SPEC-030 — The tooling does not write git history

```yaml
status: implemented
verification: T
derives_from: [INV-SPEC-040]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_baseline.py, tools/srs_release.py, tools/srs_check.py, tools/srs_grounds.py, tools/srs_dates.py, tools/srs_init.py, tools/srs_upgrade.py, tools/srs_view.py]
tests: [tests/baseline-smoke.sh, tests/release-smoke.sh]
created: 2026-08-09
```

The framework's commands **shall not** commit, tag, or push; each prepares
files and reports what is left to do.

**Rationale.** A command that commits is a command that fails for whoever
has no console git set up, and one that silently bypasses the signing and
identity their application configures. Preparing files leaves the history to
the tool the project already trusts with it, and makes every command safe to
run twice.

Every command is named, not only the two that prepare a release or a
baseline. The temptation to commit belongs to whichever command has just
written something — the installer that created a project, the dating command
that touched every requirement, the checker that regenerated the matrix — and
a constraint listed against two files is a constraint the everyday question
"what governs this file" never mentions for the other six. `srs_parse.py` is
absent because it is a library with no entry point: it is not a command.

### CON-SPEC-010 — The traceability matrix is generated

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CHK-050, FR-CI-010]
refines: []
conflicts_with: []
code: [tools/srs_check.py, specs/90-traceability.md]
tests: [tests/spec-check.sh]
created: 2026-08-07
```

The traceability matrix **shall** be produced by the checker and committed as
generated output, never edited by hand.

**Rationale.** It is committed so reviewers can read it in a diff, which
makes it the one file in the specification with two possible authors — and
the gate exists to keep the human one out.

### CON-SPEC-020 — Nothing of the framework travels into a target

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-020]
refines: []
conflicts_with: []
code: [tools/srs_init.py, skeleton]
tests: [tests/installer-smoke.sh]
created: 2026-08-07
```

What the installer copies **shall not** cite a requirement identifier,
carry an annotation naming one, or name a path that exists only in this
repository; which area an identifier is in makes no difference.

**Rationale.** ART-070 of the constitution in one sentence: what we ship has
to be about their project, not ours.

The harm is not the one first written here. A leaked identifier was said to
fail a stranger's checker undiagnosably; it does not, because a checker
reads requirement blocks and annotations and neither is what leaks. What
leaks is a citation in the prose of a procedure — and the areas are the
project's to declare, so a target may have an `FR-SKILL-090` of its own.
Then the citation resolves: an agent told "writing a requirement and
building it are separate acts (FR-SKILL-090)" looks the number up and reads
a requirement of theirs about caching. Not a dangling reference, a
confidently wrong one, in the file whose whole job is to instruct.

So a shipped procedure explains itself instead of citing. The reason a rule
exists belongs in the sentence a stranger reads, not behind a number only
this repository can resolve. What may be cited is what travels with them:
the articles of the constitution they receive, and the sections of
`specs/README.md`, which is the same document in every project.

Cite rather than contain, and whichever area rather than ours. Both halves
of that were read the other way once, by an agent working from this
sentence. The standards that travel carry identifiers inside the record
examples that show the format, and a template carries one in a field
waiting to be filled; neither asks anybody to look a number up, and a
sentence in a procedure does. Nor does it help to ask whose number it is:
`FR-CORE-020` belongs to no project here, and under the area a fresh
install offers first it resolves in the reader's own specification more
readily than one of ours ever would.

### CON-GND-010 — The grounds layer writes nowhere else

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-rules.sh]
created: 2026-08-20
```

The grounds layer's commands **shall not** write to any path outside the
register.

**Rationale.** The subsystem is optional, and what makes an optional thing
safe to decline is that declining it costs nothing and removing it leaves no
trace. A tool that edited requirement files, or a configuration outside its
own, would make the register something a project cannot back out of.

It also settles the question the join raised: a bet names a requirement, and
the temptation is to have the tool write that name back into the requirement
so both ends agree. It may not. The requirement half is computed, never
stored (`INV-GND-020`), and this is the constraint that keeps it so.

### CON-GND-020 — The dashboard is generated

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py, grounds/90-dashboard.md]
tests: [tests/grounds-rules.sh, tests/grounds-check.sh]
created: 2026-08-20
```

The register's dashboard **shall** be produced by the grounds checker from
the records and never edited by hand.

**Rationale.** `CON-SPEC-010` makes the same constraint for the traceability
matrix, and for the same reason: a summary somebody can edit is a summary
that will be edited into agreement with what its author wishes were true. The
readings this dashboard carries — how much of the system stands on refuted
ground, how old the confirmations are — are exactly the numbers somebody
under pressure would round.

Committed rather than generated on demand, so that a diff shows the readings
moving and a gate can compare what is committed against what the records say
now.

### CON-GND-030 — Records are authored, never written

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-GND-010]
refines: []
conflicts_with: []
code: [tools/srs_grounds.py]
tests: [tests/grounds-check.sh]
created: 2026-08-20
```

The grounds layer's commands **shall not** modify a record in the register.

**Rationale.** `CON-GND-010` draws the boundary of the register and says
nothing about what happens inside it, which leaves the tool free to edit the
entries themselves. That freedom is one the subsystem must not have. Evidence
is appended and never rewritten; a hypothesis whose term has run out is
reported and left alone, because expiry is not a verdict and a tool that
changed the status would be answering a question only a measurement can
answer.

The instinct is the framework's own: `FR-VIEW-080` forbids the viewer to
modify anything under `specs/`, and the reason carries over unchanged —
authored content belongs to whoever authored it, and a tool that improves it
is a tool nobody can trust with the rest.

The dashboard is not a record. It is generated output living in the register,
governed by `CON-GND-020`, and writing it is the one thing these commands do
inside `grounds/`.
