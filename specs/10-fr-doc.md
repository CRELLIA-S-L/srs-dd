# Functional requirements — documentation

What this repository's own documentation — the landing page and `docs/` — answers, and what it may claim.
The standard for the specification is `specs/README.md` and is not documentation in this sense; the guides for agents are the `SKILL` area's.

### FR-DOC-010 — The landing page consists of eleven sections, in the order a reader's questions arise

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [IF-SKILL-010]
refines: []
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

The repository's landing page **shall** consist, in this order, of an opening without a heading and the sections *What breaks without it*, *What it looks like*, *A requirement, and what the tooling does with it*, *What you get back*, *Why the thing exists, not only what it does*, *Install*, *Handing this to an agent* with *What you then tell the agent to do* under it, *The loop*, *Reading the specification* and *Where things are*, and of no other section.

**Rationale.** Which sections and in what order is a decision, and ADR-0027 records it with the alternatives it was chosen over — a short page that links out, and a page that is an index.
The order is the reader's path from stranger to maintainer: why, what it looks like, what, what I get, why the register, how to install, how to hand it to an agent, how a day goes, how to read, where things are; each section answers the question the one before it raised, which is why a section moved is a page broken even when nothing in it changed.
The picture stands second because a reader who has just recognised the problem wants to see the thing before being told what a requirement is; demonstration before argument is the one place the path bends toward the adopter rather than the stranger.

Named by heading rather than by question, because the headings are what a test can hold and what a reader scans, and because the decision is about this cut and not about any cut that would answer the same questions.
"No other section" is the half that keeps the list a decision: a section added in passing is a change to ADR-0027 made without opening it.

Each section carries a requirement of its own saying what it owes the reader and which requirements of the specification it restates; this one says only that the sections exist and in what order.
The headings are held to the list by `FR-DOC-140`; whether each section answers its question is a judgement, and this is verified by inspection.

### FR-DOC-020 — A command the documentation names is one the tool accepts

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-DOC-010]
refines: []
conflicts_with: []
code: [README.md, docs/install.md, docs/upgrade.md, docs/agents.md, docs/multilingual.md, .github/workflows/srs.yml]
tests: [tests/docs-commands.sh]
created: 2026-09-18
```

Where the landing page or a document in `docs/` names a tool of this repository together with a flag, the tool **shall** accept that flag.

**Rationale.** Documentation restates what the specification obliges, and nothing compared the two: `docs/upgrade.md` said the architecture layer had one setting for a release after it had two, and passed every gate in between.
Most of what a document claims about behaviour is prose no test can read, but a command is not — `srs_view.py --cite` is a string the page prints and a string the tool either accepts or refuses, and the pair can be checked without running anything for its effect.
Each tool already says what it accepts: the ones built on `argparse` print it for `-h`, and the three that read their arguments by hand print their usage line on any flag they do not know.

The check is over the pair — tool and flag on one line, or on the lines a command continues onto with a backslash — because a flag on its own belongs to nothing: `--strict` is accepted by three tools and `--cite` by three, two of them the same, and a document naming the wrong one for a flag is exactly the drift this exists to catch.
A flag in running prose with no tool beside it is left to the reader, and the rationale says so rather than pretending the test reads sentences.
What it does not check is what a flag does — that a document describes `--diff` correctly is still the reader's to find — and it does not reach the prose of the standards under `specs/`, `arch/` and `grounds/`, whose commands are governed by the requirements of their own areas.

### FR-DOC-030 — The opening says what the framework is, for whom, and what it costs

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [NFR-SPEC-010, NFR-SPEC-020, FR-CHK-090, FR-CI-040, FR-CI-060, FR-INIT-070, IF-SKILL-010, INV-SPEC-010]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

The opening of the landing page **shall** state what the framework is — in plain words before any standard is named — which repositories and which agents it is built for, the promise that a change altering behaviour names its requirement or fails the build, the constraints a project takes on — the Python version, the standard library alone, plain markdown, a specification in any language, no server or service, the licence — show how to try it on a repository without writing into it, point an agent to the installation procedure, and link to this repository's own published specification and to the example project.

**Rationale.** The first screen is what decides whether the second is read, and it has to carry both halves of the decision: what the reader gains, and what they will be asked to accept.
Three readers arrive at it with three questions, and the opening answers each in a line before the sections do at length: the stranger asks what this is, and the standards' names are not an answer to someone who has not met an SRS, so a plain sentence comes first and names the agents the reader already uses; the adopter asks what it would take to see it, and a dry run of the installer (`FR-INIT-070`) shows the whole of what would land without landing it; the agent asks where its procedure is, and is pointed at the section that carries the URL (`IF-SKILL-010`).
The constraints are one line because every one of them is a requirement elsewhere — the standard library (`NFR-SPEC-010`), plain files (`NFR-SPEC-020`), the lexicon rather than a language (`FR-CHK-090`) — and the line restates them where a stranger will read them; the standards paragraph names immutable identifiers and a lifecycle, which is `INV-SPEC-010` said once for the whole page.
The two links are evidence rather than decoration: the page this repository publishes from its own specification (`FR-CI-040`) shows the framework applied to itself, and the example project (`FR-CI-060`) shows it applied to something ordinary.

### FR-DOC-040 — The problem section names what agents broke and what a lookup repairs

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-020, FR-SKILL-010, CON-SPEC-010]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*What breaks without it* **shall** name the problems that repositories written with agents suffer — behaviour nobody asked for, intent kept where nothing checks it, every question costing a full read — and say how identifiers turn each into a lookup.

**Rationale.** A reader who does not recognise the problem does not want the solution, and the three named are the ones the framework was built against rather than a list of what a specification is generally good for.
The repair is stated in the specification's own terms: a plan cites a requirement and a diff carries the one it closes (`FR-SKILL-010`), what a file affects is a query rather than a search (`FR-VIEW-020`), and drift is a build error because the matrix is generated and compared (`CON-SPEC-010`).

### FR-DOC-050 — The requirement section shows the block and says what the tooling makes of it

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [IF-SPEC-010, FR-CHK-030, FR-CHK-050, FR-CHK-055, FR-CHK-040, FR-CHK-240, FR-CHK-080, FR-CHK-200, FR-CHK-140, FR-CHK-150, FR-CHK-120, FR-VIEW-060, FR-VIEW-100, FR-VIEW-110]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*A requirement, and what the tooling does with it* **shall** show one requirement in the shape the standard defines, say what the checker fails on and what it only warns about, and say what the rendered page offers.

**Rationale.** A stranger decides on the shape of the thing they will write every day, so the block is shown rather than described — a heading, a small metadata block, one statement, the reason — in the form `IF-SPEC-010` fixes, and `FR-DOC-150` holds the example to the parser so that the shape shown is the shape accepted.
What the checker fails on and what it warns about are two lists a reader weighs differently, and each entry in them is a rule of the checker's: a dangling link (`FR-CHK-030`), a status without code (`FR-CHK-050`), a path that does not exist (`FR-CHK-055`), a cycle in either graph (`FR-CHK-040`, `FR-CHK-240`), an annotation naming nothing (`FR-CHK-080`); a file that does not name its requirement back (`FR-CHK-200`), a test-verified requirement with no test (`FR-CHK-140`), a requirement no link touches (`FR-CHK-150`); `--strict` promoting the second list (`FR-CHK-120`).
The page is named for what it offers rather than how it is built — search, filters, the dashboard, the gaps, the graph and the comparison of baselines (`FR-VIEW-060`, `FR-VIEW-110`, `FR-VIEW-100`) — and for the one property a stranger cares about, that it opens from a file with nothing fetched.

### FR-DOC-060 — The benefits section names a capability per entry, and each is a requirement's

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-010, FR-VIEW-020, FR-CI-010, FR-SKILL-160, FR-SKILL-030, NFR-SKILL-010]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*What you get back* **shall** list what a project gains, one capability per entry, each of which is the behaviour of a requirement this specification carries and none of which is a promise about the future.

**Rationale.** A benefits list is where a page drifts fastest, because a benefit is pleasant to add and nothing checks it; binding each entry to a requirement is what keeps the section a restatement rather than a wish.
The entries as written: the lookup that does not grow with the system (`FR-VIEW-020`, `FR-VIEW-010`); the matrix compared rather than trusted (`FR-CI-010`); a test that counts only if it could fail (`FR-SKILL-160`); a specification mined from code (`FR-SKILL-030`); procedures any agent or person follows as written (`NFR-SKILL-010`).
The last of those had no requirement until this one asked for it: the page claimed it, nothing obliged it, and `NFR-SKILL-010` was written to close the gap rather than to weaken this statement.

Five entries and not nine, which is where the section stood when it was first specified.
The four that left were true and were said elsewhere on the page — immutable identifiers and the lifecycle in the opening, a milestone compared in the reading section, any language and nothing to install in the constraints line — and a list of benefits is read to the fifth entry and skimmed past it; what stays is what a team writing with agents has not heard before: that the lookup does not grow, that the gate cannot be agreed around, that a test is proof only when it could fail, that a specification can be mined from code they already have, and that none of it binds them to one agent.

### FR-DOC-070 — The grounds section says what the register and the layer add, and when not to keep one

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-GND-010, FR-GND-060, FR-GND-420, FR-GND-140, FR-GND-190, FR-GND-200, FR-GND-240, FR-GND-250, FR-GND-220, FR-GND-310, INV-GND-020, FR-ARCH-010, FR-ARCH-060, FR-ARCH-240]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*Why the thing exists, not only what it does* **shall** say what a specification does not record, describe the grounds register — its three kinds of ground and the bet that joins them to a requirement — and the architecture layer, say what the register's checker reports, and say when a project should keep no register.

**Rationale.** Both layers are optional, and a reader who does not know why they exist declines them or keeps them for the wrong reason.
The section states the gap first — a rationale is prose no rule checks — and then the two answers, in the terms the layers are specified in: a hypothesis with a threshold and a term, an ideology and a frame that are never measured, a bet that is a record of its own so that a requirement carries no field (`INV-GND-020`); a part, its files, and a file no part owns (`FR-ARCH-060`), written or derived (`FR-ARCH-240`).
What the checker reports is named because that is what the layer costs and pays: a hypothesis past its term (`FR-GND-060`), one built on and never measured (`FR-GND-420`), a verdict that does not follow (`FR-GND-140`), a threshold moved (`FR-GND-190`), evidence deleted (`FR-GND-200`), the hook naming the bets a commit touches (`FR-GND-310`); on the dashboard, how old the core is (`FR-GND-240`), what each frame refused (`FR-GND-250`), and the requirements resting on nothing (`FR-GND-220`), which the section says is the signal rather than the debt.
When not to keep one is the paragraph that makes the rest credible: a register of invented entries teaches every reader that the register is decoration, and the page says so before a reader finds out.

### FR-DOC-080 — The install section carries the commands and says what the installer asks and refuses

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-INIT-010, FR-INIT-020, FR-INIT-030, FR-INIT-040, FR-INIT-070, FR-INIT-080, FR-INIT-090, FR-INIT-170, FR-SPEC-020]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*Install* **shall** carry the clone command and the installer's invocation, name what the installer asks for, name the flags that answer for a person and that write nothing, say what adoption of an existing specification does and does not touch, and link to the installation and upgrade documents.

**Rationale.** This is the section a person copies from, so what it carries is commands and the facts a person needs before running them: the questions coming — name, areas, roots, extensions, a CI template, the lexicon (`FR-INIT-090`), the register and its period, the layer; `--defaults` and `--dry-run` (`FR-INIT-070`); that an existing specification is validated first, never modified (`FR-INIT-040`) and left byte-identical on failure (`FR-INIT-030`); that undated requirements are offered a date from the history (`FR-INIT-170`, `FR-SPEC-020`); that a pre-commit hook already in place is not displaced (`FR-INIT-080`).
The details, the modes and the exit codes are in `docs/install.md` and the upgrade path in `docs/upgrade.md`, linked rather than repeated, and `FR-DOC-190` holds the links.

### FR-DOC-090 — The agent section carries the entry point, the exit codes and the two decisions

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [IF-SKILL-010, IF-CI-010, FR-INIT-010, FR-INIT-030, FR-SKILL-040, FR-SKILL-190, FR-INIT-210]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*Handing this to an agent* **shall** carry the raw URL of the installation procedure, the clone-and-run commands with the way to pin a release, and the decisions the procedure hands back to the maintainer, and point to the agent document for the installer's modes and exit codes.

**Rationale.** The framework's own distribution channel is an agent given nothing but the repository URL (`IF-SKILL-010`), and this section is what that agent reads.
It clones rather than fetches one file because the installer copies the skeleton, the skills and the templates out of the clone.
The modes (`FR-INIT-010`) and the exit codes (`IF-CI-010`) are what an agent installing unattended decides by, and they live in `docs/agents.md` rather than here, where `FR-DOC-180` holds them to the installer: the section was the longest on the page — seven hundred words in the middle of it — and what an agent needs at the moment of a non-zero exit is the document that explains the code, not the landing page that lists it; the page says the decision is by the code and where the codes are.
The three decisions — the areas and the lexicon (`FR-SKILL-040`) and the line width, asked for rather than assumed (`FR-INIT-210`, `FR-SKILL-190`) — are named so that a maintainer handing the URL to an agent knows what will come back to them and why; adoption's rollback (`FR-INIT-030`) is what makes a retry safe, and the agent document says so beside the code that reports it.

### FR-DOC-100 — The skills table names every procedure a project receives, and the rules that bind them

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-010, FR-SKILL-030, FR-SKILL-050, FR-SKILL-060, FR-SKILL-080, FR-SKILL-090, FR-SKILL-100, FR-SKILL-110, FR-SKILL-120, FR-SKILL-130, FR-SKILL-170, FR-SKILL-180, FR-SKILL-260, FR-GND-320, FR-ARCH-150]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*What you then tell the agent to do* **shall** list every procedure the installer copies into a project — with what to say to invoke it and what the procedure does — and name the rules that bind all of them.

**Rationale.** After the install the procedures are in the project's own tree, and the table is the moment a reader learns that they exist and what each is for; a procedure missing from it is one no one asks for by name.
`FR-DOC-160` holds the set of names to what the installer copies, including the two that arrive only with a register (`FR-GND-320`) or a layer (`FR-ARCH-150`); what each does is its own requirement's — the loop (`FR-SKILL-010`), harvesting that proposes (`FR-SKILL-030`), an audit that reports and repairs nothing and offers the links an area lacks (`FR-SKILL-050`, `FR-SKILL-260`), authoring that judges the statement, asks what it stands on and stops at the requirement (`FR-SKILL-120`, `FR-SKILL-180`, `FR-SKILL-090`), the check that names what to run (`FR-SKILL-100`), the baseline that settles the number and offers an audit (`FR-SKILL-080`, `FR-SKILL-130`).
The three rules at the end are why an agent with these is safer than one without, and they are the specification's: it proposes and the maintainer approves (`FR-SKILL-030`), it runs nothing unasked, and it reports what follows rather than what it noticed (`FR-SKILL-170`).

### FR-DOC-110 — The loop section states the five steps as the installed guide states them

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-SKILL-010, FR-SKILL-120]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*The loop* **shall** state the five steps of the everyday loop — requirement before code, plans by number, code, the loop closed in the same edits, the checker — as the agent guide installed into a project states them, and say where the rules no checker reads live.

**Rationale.** The loop is the framework's one habit, and a reader who sees it in five lines can tell whether their team will keep it before installing anything.
The same five steps are in `skeleton/AGENTS.md`, so the page restates the guide rather than a second version of it, which is `FR-SKILL-010` read from the outside; what a linter cannot check — one capability, verifiable, about behaviour — is `FR-SKILL-120`'s, and the section points at the standard and the audit rather than restating them.

### FR-DOC-120 — The reading section lists the viewer's questions and what the layers answer beside it

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-010, FR-VIEW-020, FR-VIEW-030, FR-VIEW-040, FR-VIEW-050, FR-VIEW-060, FR-VIEW-240, FR-VIEW-330, FR-VIEW-340, IF-VIEW-010, FR-VIEW-080, FR-GND-310, FR-ARCH-270, FR-GND-540]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*Reading the specification* **shall** list the viewer's commands one per question a reader asks — one requirement, a file, a tree, the gaps, a citation, a baseline, the model, the page, a picture of a selection — say that the viewer writes nothing and gates nothing, and name what the register and the layer answer with their own commands.

**Rationale.** The viewer is how the specification is read once it exists, and a reader who knows its nine questions never greps.
Each line is a requirement's answer — one requirement with its links (`FR-VIEW-010`), a file (`FR-VIEW-020`), a tree (`FR-VIEW-030`), the gaps (`FR-VIEW-040`), a citation of a requirement or a decision (`FR-VIEW-240`, `FR-VIEW-330`), a baseline (`FR-VIEW-050`), the model (`IF-VIEW-010`), the page (`FR-VIEW-060`), a picture of a selection (`FR-VIEW-340`) — and `FR-DOC-020` holds every flag on the page to the tool.
That the viewer never writes (`FR-VIEW-080`) is said because a stranger assumes a tool that reads a repository might change it; what a file's requirements stand on (`FR-GND-310`) and how an element or a record is cited (`FR-ARCH-270`, `FR-GND-540`) are the layers' own commands, named here because the viewer reads the specification and nothing else.

### FR-DOC-130 — The map section names every top-level path and what it is

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [CON-SPEC-020, FR-INIT-180]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md]
tests: []
created: 2026-09-18
```

*Where things are* **shall** name every path at the top level of the repository, say what each is, and say which of the tools and procedures a project receives and which stay here.

**Rationale.** The last section is for the reader who has decided and now needs to find something; a path missing from it is found by listing the directory, and the table then teaches that it is incomplete.
`FR-DOC-170` holds the set of paths to the repository; what a project receives and what stays is the line `CON-SPEC-020` draws and `FR-INIT-180` keeps, restated where a reader looks for a file.

### FR-DOC-140 — The headings are the sections the decision names, in its order

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-DOC-010]
refines: []
conflicts_with: []
code: [README.md, .github/workflows/srs.yml]
tests: [tests/docs-content.sh]
created: 2026-09-18
```

The gate **shall** fail when the headings of the landing page, read outside fenced blocks, are not exactly the sections `FR-DOC-010` names in the order it names them.

**Rationale.** A section added in passing or moved for a paragraph's sake is a change to ADR-0027 made without opening it, and nothing but a test notices on the day.
Outside fenced blocks because the page shows a requirement, and a requirement's heading inside an example is not a section — the same reading the checker gives code blocks under `FR-CHK-110`.
Exactly and in order, because the decision is about the cut and not about a set: the same eleven sections shuffled are a page whose path is broken.

### FR-DOC-150 — The example requirement passes the framework's own checker

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-DOC-050, IF-SPEC-010]
refines: []
conflicts_with: []
code: [README.md, .github/workflows/srs.yml]
tests: [tests/docs-content.sh]
created: 2026-09-18
```

The gate **shall** fail when the requirement the landing page shows as an example, placed in a project laid out as the standard asks, is not accepted by the checker without error.

**Rationale.** The example is the first requirement most readers ever see and the one they copy, and this project once shipped an invented citation inside a rule about citations; an example the checker would refuse is the same failure at the front door.
Placed in a project rather than parsed alone, because a block can parse and still fail — a status without code, a path that does not exist — and the checker's whole judgement is what the example is shown to survive.
The neighbours the example links to are supplied by the test and the files it names are created empty, because an example shows a link on purpose and what is under judgement is the block, not the code it points at.

### FR-DOC-160 — The skills table names exactly the procedures the installer copies

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-DOC-100]
refines: []
conflicts_with: []
code: [README.md, .github/workflows/srs.yml]
tests: [tests/docs-content.sh]
created: 2026-09-18
```

The gate **shall** fail when the set of procedures the landing page's skills table names differs from the set the installer copies into a project.

**Rationale.** The installer's list is the fact; the table restates it, and the two diverged the day the architecture procedure was added — the table went on naming nine while ten shipped, and nothing said so until this was written.
The set and not the order, because the table is read by what a person says and not by rank; a procedure that stays in the framework — the installer's own, the release — is not in the installer's list and not owed a row.

### FR-DOC-170 — The map names exactly the repository's top level

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-DOC-130]
refines: []
conflicts_with: []
code: [README.md, .github/workflows/srs.yml]
tests: [tests/docs-content.sh]
created: 2026-09-18
```

The gate **shall** fail when a path tracked at the top level of the repository — other than the page itself and git's own configuration files — has no row in the landing page's map, or when a path the map names does not exist.

**Rationale.** A directory added to the repository is added to the map by whoever remembers, which is nobody: the CI configuration, the hook directory and the licence had been at the top level for months with no row.
Git's own configuration files are excluded because they describe git and not the framework, and the page is excluded because a row saying "this page" says nothing; everything else a stranger sees when they list the directory is something the map owes them a sentence about.
A path in the map that does not exist is the other direction of the same drift — a file renamed and a row that kept its old name.

### FR-DOC-180 — The exit codes the documentation lists are the installer's

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-DOC-090, IF-CI-010, FR-INIT-010]
refines: []
conflicts_with: []
code: [docs/agents.md, docs/install.md, .github/workflows/srs.yml]
tests: [tests/docs-content.sh]
created: 2026-09-18
```

The gate **shall** fail when the set of exit codes a document under `docs/` lists for the installer differs from the set the installer states in its own usage text.

**Rationale.** An agent reading the document decides by the code, and a code the document lists that the installer never returns — or one it returns that the document omits — is a wrong decision made on the document's word.
The set rather than the wording, because what a code means is prose the document may say in its own words; that there are these codes and no others is what a test can hold, and the installer's usage text is where the tool itself says so.
The list moved from the landing page to `docs/agents.md` when the agent section was shortened (`FR-DOC-090`), and `docs/install.md` had carried one all along; the instrument holds every list it finds, each on its own, because two lists that disagree with each other are two findings and not one.

### FR-DOC-190 — A link the documentation carries leads to a file that exists

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-DOC-010]
refines: []
conflicts_with: []
code: [README.md, docs/install.md, docs/upgrade.md, docs/agents.md, docs/multilingual.md, .github/workflows/srs.yml]
tests: [tests/docs-content.sh]
created: 2026-09-18
```

The gate **shall** fail when a relative link in the landing page or in a document under `docs/` names a path that does not exist in the repository.

**Rationale.** The page links out for everything it does not repeat — the install details, the upgrade path, the agent guide, the language note — and a link is the one claim on the page that a rename breaks in silence.
Relative links only: an address on another host is somebody else's to keep, and a test that fetched it would fail for reasons that are not the page's.

### FR-DOC-200 — A section is re-read when a requirement it restates changes

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-DOC-010, FR-SKILL-010]
refines: []
conflicts_with: []
code: [README.md, .claude/skills/srs/SKILL.md]
tests: []
created: 2026-09-18
```

When a requirement that a section of the landing page stands on changes, the procedure making the change **shall** re-read that section against the requirement's new statement in the same set of edits, and change the section where it no longer restates it.

**Rationale.** The instruments hold what a test can read — headings, names, paths, codes, flags, links — and the rest of the page is sentences about behaviour, which drift the way `docs/upgrade.md` drifted: a requirement moved and the sentence restating it did not.
The section requirements name in `depends_on` what they restate, so the change reaches the section by the route the everyday loop already walks — the incoming links of the changed requirement are its blast radius, and a landing-page section among them is a document to open, not a link to note.
The same set of edits, for the reason the loop gives for the requirement and the code: they diverge exactly when one moves without the other.

### FR-DOC-210 — The picture section shows the graph the pipeline publishes, linked to the page

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-DOC-010, FR-CI-110, FR-VIEW-340, FR-VIEW-110]
refines: [FR-DOC-010]
conflicts_with: []
code: [README.md, .github/workflows/srs.yml]
tests: [tests/docs-content.sh]
created: 2026-09-18
```

*What it looks like* **shall** show the graph image the pipeline publishes beside the page — this page's own requirements and everything they link to — as a link to the live page, and say what a box and a line are and which lane is the page's own.

**Rationale.** A stranger who has recognised the problem wants to see the thing, and the page is the one place a forge lets them: it strips frames and scripts and shows an image, so the image is what a reader gets who has not clicked.
The image is the pipeline's (`FR-CI-110`), drawn by the viewer (`FR-VIEW-340`) from the specification at every deploy, so the page never shows a picture older than itself and nobody keeps a screenshot; the gate holds the name the page shows to the name the pipeline writes, because a picture addressed by URL breaks in silence when either side renames it.
The page's own requirements with what they link to, rather than the whole graph, because the whole graph is the picture nobody reads (`FR-VIEW-110` draws it on the page for whoever wants it) and the neighbourhood of the page is the one picture a reader of the page already has a story for.
A link to the live page, because the image is the graph without its interaction, and the page is where the interaction is.

