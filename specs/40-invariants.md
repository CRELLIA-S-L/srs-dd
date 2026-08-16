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

The price is more requirements. FR-VIEW-060 is six of them, each with a number
that can never be reused, its own links and its own `tests` field. That is the
point rather than the cost: a `tests` field is worth reading only when what it
answers for is one thing.

Written after the passage in `specs/README.md` that carries it, which is the
shape FR-SKILL-090 warns about — the rule was sharpened first and only then
noticed to have no number to be cited by. Recorded that way rather than
backdated.

### CON-SPEC-030 — The tooling does not write git history

```yaml
status: implemented
verification: T
derives_from: [INV-SPEC-040]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_baseline.py, tools/srs_release.py]
tests: [tests/baseline-smoke.sh, tests/release-smoke.sh]
```

The framework's commands **shall not** commit, tag, or push; each prepares
files and reports what is left to do.

**Rationale.** A command that commits is a command that fails for whoever
has no console git set up, and one that silently bypasses the signing and
identity their application configures. Preparing files leaves the history to
the tool the project already trusts with it, and makes every command safe to
run twice.

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
```

What the installer copies **shall not** contain requirement identifiers of
this framework, annotations naming them, or paths that exist only in this
repository.

**Rationale.** ART-070 of the constitution in one sentence: a stranger's
first install has to pass their own checker, and a leaked identifier fails it
in a way they cannot diagnose.
