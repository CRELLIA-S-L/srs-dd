# Functional requirements — architecture layer

The optional layer in `arch/`: which parts the system is made of, what each part carries, and what a checker can hold that description to.
The layer is a register of its own beside `specs/`, decided in ADR-0023 for the reasons ADR-0015 decided the same shape for the grounds register.

### FR-ARCH-010 — The layer is read and reported on

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-VIEW-010]
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh, tests/arch-check.sh]
created: 2026-09-02
```

Where a project carries an architecture layer, the architecture checker **shall** read every element in it.

**Rationale.** This is the entry the rest of the layer hangs from: a description nothing reads is prose, and prose about structure is the first thing to go stale.
The requirement model comes from `srs_view.py --json`, which `IF-VIEW-010` promises to keep stable, so the layer never parses `specs/` itself and never has to be taught the requirement format twice.

### FR-ARCH-020 — Well-formed and unique identifiers

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-ARCH-010]
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh]
created: 2026-09-02
```

If an element identifier is repeated or does not match `E-<NNN>`, the architecture checker **shall** report it as an error naming both occurrences.

**Rationale.** An identifier that names two things makes every later finding ambiguous, and one that matches nothing makes the map unreadable.
The same rule the specification has for requirements and the register has for its records, for the same reason and with the same shape of message.

### FR-ARCH-030 — A missing required key is named as missing

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-ARCH-010]
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh]
created: 2026-09-02
```

Where an element omits a key the format requires, the architecture checker **shall** report that key as missing rather than as holding a bad value.

**Rationale.** The distinction `FR-CHK-170` and `FR-GND-030` both draw.
"`carries` is missing" sends the author to the record; "`carries` is empty" sends them to what the record says, and only one of those is where the mistake is.

### FR-ARCH-040 — An element names a requirement that exists

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh]
created: 2026-09-02
```

Where an element names a requirement absent from the requirement model, the architecture checker **shall** report it as an error naming the element and the requirement.

**Rationale.** The join lives in the element and nowhere else, so a name that resolves to nothing is a join to nothing — and it is invisible from the specification's side, which does not know the element exists.
An error rather than a warning because a typed identifier that resolves is the whole basis of every other check here.

### FR-ARCH-050 — An element carrying a cancelled requirement is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-ARCH-040]
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh]
created: 2026-09-02
```

Where an element names a `superseded` or `withdrawn` requirement, the architecture checker **shall** report it as a warning naming the element, the requirement and its status.

**Rationale.** A cancelled requirement is exactly the case where a part outlives its reason, and the element is where that shows first: the code is still there, the obligation is not.
A warning rather than an error because the honest resolutions differ — re-point at the successor, drop the requirement from the element, or retire the element — and the checker cannot choose between them.

### FR-ARCH-060 — A carrier no element claims is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-ARCH-010]
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh]
created: 2026-09-02
```

Where a requirement names a file that no element carries, the architecture checker **shall** report it as a warning naming the file.

**Rationale.** This is the half of the description that decays without anybody noticing: a file is added to a requirement's `code` field by whoever is changing behaviour, and no part of the system claims it.
The reading is three-sided — the specification says the file realizes a requirement, the element says which part the file belongs to, and the disagreement is between them rather than inside either.
Requirements name more than code here: the standard, the procedures, the CI templates and the payload all appear in `code` fields, so an element set that covers only source files makes this rule fire on half the repository.
That is a fact about how coarsely the parts are cut, not a reason to narrow the rule.

### FR-ARCH-070 — A realized requirement no element carries is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-ARCH-010]
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh]
created: 2026-09-02
```

Where a requirement is `implemented` or `partial` and no element names it, the architecture checker **shall** report it as a warning naming the requirement.

**Rationale.** The other direction of the same decay, and the one that says the map has stopped describing the whole system.
Scoped to the two statuses that claim realization for the reason `FR-CHK-200` is: a `draft` or `deferred` requirement has nothing built yet, so no part can be expected to carry it.

### FR-ARCH-080 — An element carrying no requirement is reported

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-ARCH-010]
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh]
created: 2026-09-02
```

Where an element that is not cancelled names no requirement, the architecture checker **shall** report it as a warning naming the element.

**Rationale.** A part that answers to nothing is either a part nobody needed or a requirement nobody wrote, and both are worth a sentence from whoever knows which.
This is the rule that keeps the layer from becoming a second file tree: every element earns its place by naming what it is for.
A `superseded` or `withdrawn` element is exempt because a dissolved part has nothing left to answer for, and a finding repeated every run is how a report teaches its reader to skim it.

### FR-ARCH-090 — What an architecture rule costs is the project's to set

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh]
created: 2026-09-02
```

The architecture checker **shall** let a project lower a rule to a report or silence it altogether in the layer's configuration.

**Rationale.** The same lever `FR-CHK-160` gives the specification and `FR-GND-110` gives the register.
A project part-way through describing its parts fires the ownership rule on nearly everything, and a gate that cannot be lowered while that is being worked through is a gate that gets deleted.

### FR-ARCH-100 — Strict mode

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-ARCH-090]
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-rules.sh, tests/arch-check.sh]
created: 2026-09-02
```

Where `--strict` is given, the architecture checker **shall** exit non-zero when warnings were reported even if no error was.

**Rationale.** Most of what this checker says is a warning by design, so without a strict mode a pipeline that runs it proves only that the records parse.

### FR-ARCH-110 — The map says what each part is and what it stands on

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_arch.py]
tests: [tests/arch-check.sh]
created: 2026-09-02
```

The map **shall** state, for every element, the requirements it carries, the files it carries and its status.

**Rationale.** The map is what a reader opens instead of the records, and what a reviewer diffs when a part changes hands.
It is generated for the reason `CON-ARCH-020` gives, and it is a text file rather than a drawing because the graph already has a home on the rendered page.

### FR-ARCH-120 — The layer is a choice at install

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-09-02
```

A fresh install and an adoption **shall** offer the architecture layer as a choice, installing nothing of it where it is declined.

**Rationale.** What makes an optional thing safe to decline is that declining it costs nothing, and the register already proved the shape works.
A project whose parts fit in one sentence gains nothing here and should be able to say so once.

### FR-ARCH-130 — The layer is added deliberately, never silently

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-ARCH-120]
refines: []
conflicts_with: []
code: [tools/srs_init.py, tools/srs_upgrade.py]
tests: [tests/installer-smoke.sh, tests/upgrade-smoke.sh]
created: 2026-09-02
```

An upgrade **shall** refresh the architecture layer's tooling only where the layer is already present, adding it to a project that has none only when asked.

**Rationale.** An upgrade that quietly grows a new directory and a new gate is an upgrade nobody trusts to run unattended.
The same promise the register makes in `FR-GND-290`, and it is the reason the layer's presence is read from its configuration file rather than guessed.

### FR-ARCH-140 — A fresh layer is one its own checker accepts

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-ARCH-120]
refines: []
conflicts_with: []
code: [tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-09-02
```

Where the architecture layer is installed, the target's own architecture checker **shall** pass strictly on what was installed.

**Rationale.** A starter that fails its own gate on the first run teaches the reader that the gate is noise, and it is the first thing a new project sees.
The starter therefore carries no elements at all rather than invented ones, and the ownership rule is what the project turns on as it writes real ones.

### FR-ARCH-150 — The architecture procedure travels with the project

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-ARCH-120]
refines: []
conflicts_with: []
code: [tools/srs_init.py, .claude/skills/srs-arch/SKILL.md]
tests: [tests/installer-smoke.sh]
created: 2026-09-02
```

The skills installed into a project **shall** include the architecture procedure where the layer is installed.

**Rationale.** The format is half of what a layer is; the other half is the procedure that decides what an element is and records the choice.
Shipped without it, a project gets a checker for a description nobody was told how to write.

### FR-ARCH-200 — A dependency the model does not declare is reported

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-ARCH-010]
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-09-02
```

Where the language of a file can be read, the architecture checker **shall** report a dependency between two elements that the code has and the declared model does not.

**Rationale.** This is the reflexion model Murphy and Notkin describe: the engineer supplies the high-level model, the tool computes where the source disagrees with it.
It is a separate requirement from the ownership rules because it is the one check that needs the language read rather than the fields compared, and because it is worth nothing until elements declare dependencies at all.
Deriving the declared model instead of authoring it was measured and rejected: over this repository's own tooling the requirement graph produced twenty-five edges against seven real ones, three of them shared.
Conceptual links between requirements are not call edges, and no rule can turn one into the other.

### FR-ARCH-210 — The drivers are computed, not chosen by taste

```yaml
status: deferred
verification: T
derives_from: []
depends_on: [FR-ARCH-010]
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-09-02
```

When asked for the architectural drivers, the architecture command **shall** rank the requirements by what makes a requirement drive structure and print the few that lead.

**Rationale.** Architecture is designed against a handful of drivers rather than the whole specification, and picking that handful by feel is where the design stops being traceable.
The signal is in the model already: over this repository, requirements that took part in an architecture decision carry an average of 1.87 incoming links against 0.62 for the rest, and by the stricter reading — the ADR's own *Related requirements* field — 2.04 against 0.63.
Type carries weight too, since an interface or an invariant constrains structure by construction.
What the ranking cannot see is a trade-off nobody wrote down, so it prints candidates for a person to accept, never a decision.
