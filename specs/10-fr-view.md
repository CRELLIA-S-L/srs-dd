# Functional requirements — view

The viewer, `tools/srs_view.py`: the read-only projections of what the checker validates — terminal queries and one self-contained page.

### FR-VIEW-010 — One requirement with its links resolved

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-07
```

When given a requirement identifier, the viewer **shall** print that requirement with its metadata, its statement, and its links resolved in both directions, incoming links included.

**Rationale.** Incoming links are the blast radius of a change and are computed, so they exist nowhere in the source files.

### FR-VIEW-020 — Which requirements describe a file

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-07
```

When given a path, the viewer **shall** list the requirements that name it in their `code` or `tests` fields or that the file's own annotations point at, accepting a directory as well as a file.

**Rationale.** This is the first question of every task that touches existing code, and grepping the spec by hand misses annotations.

### FR-VIEW-030 — The derivation tree

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-07
```

When given a requirement identifier, the viewer **shall** print what derives from it, and print the opposite direction — what it derives from — where the upward flag is given.

**Rationale.** Changing a requirement without seeing what hangs below it is how a small edit silently invalidates a subtree.

### FR-VIEW-040 — Coverage gaps

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-07
```

The viewer **shall** report, on request, realized requirements with no listed tests, drafts that already carry code, realized requirements resting on a draft, and source files no requirement that has not been cancelled references against the total number of source files.

**Rationale.** These four lists are what an audit starts from; the checker reports them as warnings at most — and under a lenient configuration not at all — so something has to surface them on demand.

The fourth is a proportion where the others are lists, because a count of unreferenced files means nothing on its own: eleven is most of a young project and a rounding error in an old one.
The other three are already proportions of a sort — the specification is their denominator, and it is on the same screen.

A cancelled requirement does not count as referencing its files, for the reason FR-CHK-210 gives and so that the two tools agree: this one said plainly that a file named by a `withdrawn` requirement was covered while the checker, in the same tree and the same run, called it unclaimed.
A reader has no way to tell which of the two is speaking about their code.

### FR-VIEW-050 — Difference against a baseline

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [INV-SPEC-040]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-07
```

When given a git revision or the version of a logged baseline, the viewer **shall** print how the specification changed since it: requirements added, removed, and the fields that differ, a statement counting as different by its words rather than by where its lines end.

**Rationale.** A baseline is only useful if the difference from it can be read; a raw `git diff` of the specification is dominated by reflow.

Which is why the words are compared rather than the characters, and that half was learned the hard way: the release that reflowed every paragraph in this repository produced a baseline row naming 176 requirements as changed when one of them had changed, and the row is what every later reader compares against.
A line break inside a paragraph renders as a space, so a statement that reads identically is identical for this purpose whatever `git diff` says.
A version is accepted because a baseline need not have a tag to name it by (INV-SPEC-040), and asking a reader to find the commit themselves would put the tag back in the middle of the process.

### FR-VIEW-060 — A page that opens from the filesystem

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-07
```

The viewer **shall** render the specification into a single self-contained HTML file — search, filters, a status dashboard, a graph of the links between requirements grouped by area, and links in both directions — that requests nothing over the network.

**Rationale.** A reviewer who does not grep still has to read the specification, and a page that needs a CDN is a page that stops working offline, behind a corporate proxy, and in five years.

### FR-VIEW-070 — Deterministic output

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-07
```

Two renderings of an unchanged specification **shall** produce byte-identical pages.

**Rationale.** A timestamp in the output would make every CI run a diff, and the page could never be committed or compared.

### FR-VIEW-080 — Reading never writes

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [CON-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-07
```

The viewer **shall not** modify anything under `specs/` or leave bytecode in the project it was run in.

**Rationale.** The traceability matrix stays the checker's artifact, with one generator; a viewer that also wrote would create a second source of truth.

### FR-VIEW-090 — The page says what it is showing

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060, INV-SPEC-040]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-08
```

The rendered page **shall** state the specification's current baseline, the framework version that generated it, and — where the history those baselines name was not available to the render — that they could not be read.

**Rationale.** The page lives at a stable address and outlives a dozen releases.
A reader arriving from a bookmark cannot tell a fresh page from a six-month-old one, and the two questions — how current is the specification, what rendered it — have different answers when a project stops upgrading.

### FR-VIEW-100 — Any two baselines can be compared on the page

```yaml
status: implemented
verification: T
derives_from: [FR-VIEW-050]
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-08
```

The rendered page **shall** let a reader pick any two of the specification's baselines and see which requirements were added, removed, or had a field or their statement changed between them.

**Rationale.** The baseline log records what was frozen, not what changed while freezing it; that answer exists only in `--diff`, which needs a clone.
Comparing an arbitrary pair means the page carries the specification at every baseline, so it carries it the way a repository does: the oldest baseline in full and each later one as its change, folded up on demand.
Statements travel as fingerprints — a rewording still shows as a change, without the text of the whole specification riding along once per baseline.

### FR-VIEW-110 — The graph can be explored

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-08
```

The graph on the page **shall** fill the panel it is drawn in and let a reader move and scale it, collapse an area into a single block, return the view to where it started, and see what a node links to and what links to it.

**Rationale.** A specification of any size draws a graph larger than the viewport, and a picture that can only be scrolled is a picture nobody studies.
What is filled is the panel rather than the drawing: sized from the drawing, a small specification gets a postage stamp to work in — and a reader who has zoomed into one corner needs the way back, which is what returning the view is for.

Collapsing an area is what pulling a node aside used to be.
The gesture was never about the node: it was about clearing what stood in front of the thing being read, and in a drawing grouped by area (ADR-0012) the thing in the way is a whole column.
Moving one box out of a column of nineteen achieves nothing, and it also has nowhere to go — a position now means membership of an area and a place in its ordering, so a dragged node is a node lying about where it belongs.

Done in the page's own script rather than with a graph library: the layout is arithmetic — a lane per area, a row per requirement — so a library would be paid for in every reader's download and every installed project, in exchange for panning.

### FR-VIEW-120 — The baseline row is written by the tooling

```yaml
status: implemented
verification: T
derives_from: [FR-VIEW-050]
depends_on: [FR-VIEW-080]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/baseline-smoke.sh]
created: 2026-08-08
```

When asked for a baseline row, the viewer **shall** print it ready to paste:
version, date, tag, and what changed since the previous baseline — reading the working tree, or the tagged revision itself where that tag already exists.

**Rationale.** Four rows were written by hand into this project's own log, each time by reading a matrix and reducing a diff — mechanical work that invites a wrong count nobody would ever notice.
Printed rather than written into the file: the viewer never touches `specs/` (FR-VIEW-080), and a row a person pastes is a row a person has read.
A row asked for after its tag exists describes that tag rather than whatever the working tree has drifted to since, so writing it late costs nothing in accuracy.

### FR-VIEW-130 — A requirement is reachable from every view

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-10
```

When a requirement is picked from any view of the page — a link in the dashboard or in a baseline comparison, a node in the graph — the page **shall** show that requirement, switching to the view that renders it and clearing whatever filter would hide it.

**Rationale.** Following links in both directions is what this page is for, and three of its four views could not do it: the dashboard and the baseline comparison render links whose target lives in a hidden section, so following one moved the reader nowhere and gave no sign of why.
The graph reached it by its own handler rather than by this rule, which is how it stayed broken unnoticed when a later change stopped its clicks from firing at all.

### FR-VIEW-140 — The rendered page can be opened where it is made

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-10
```

Where opening is asked for, the viewer **shall** open the page it has just rendered in the reader's browser.

**Rationale.** Rendering and opening are one act for a reader and two commands with a path between them, and the path differs by platform — which puts the knowledge in a procedure an agent reads, and leaves whoever works without one to look it up.
The standard library opens a browser in a line, so the tool can carry it once instead of every reader carrying it forever.

### FR-VIEW-150 — The graph can be narrowed to one requirement's surroundings

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-10
```

When a requirement is chosen as the root, the graph **shall** draw only that requirement and what lies within a chosen number of links of it.

**Rationale.** A drawing of everything is the one view a specification of any size cannot use, and the tools that solve this converge on the same answer: a root and a radius, whether it is `root_id` with `root_depth` in sphinx-needs or impact analysis from a selected item in the commercial tools.
StrictDoc still lists the whole-project view as wanted rather than done.
The page already lights a node's immediate links on hover, which is this idea stopped one step short — the neighbourhood is computed and then thrown away instead of becoming the drawing.

### FR-VIEW-160 — Every kind of link is drawn, and the reader chooses which

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-10
```

The graph **shall** draw each kind of link between requirements in a form that tells it from the others, and let the reader leave out the kinds not wanted.

**Rationale.** Two of the four link fields were drawn and two were not, which in this specification meant showing twenty-one edges and hiding forty-four:
the reader was studying the minority relation without being told.
Drawing everything and subtracting is what `needflow` does with its `link_types` option, and it is the safer default — a link that exists and is not drawn is invisible, while one that is drawn and unwanted is one click away.
Layers stay derived from `derives_from` alone: it is the relation that means "higher level", and a layer computed from the union would silently change the vertical axis from abstraction to order of work.

The drawing reduces along two axes and they are not the same one.
This is by kind: leave out `depends_on` and every edge of that relation goes, wherever it is.
Narrowing to a root and a radius is FR-VIEW-150, and it cuts by distance instead.
The distinction is worth stating because it was once lost: a root-and-radius control was taken to satisfy both, and this requirement stood at `implemented` with half of it unwritten.

### FR-VIEW-180 — A node shows the status of its requirement

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-11
```

The graph **shall** draw a requirement's node in a form that tells its status from the other statuses.

**Rationale.** The dashboard counts the statuses and the chips filter by them; the graph was the one view that stayed silent, so a reader looking at the drawing could not tell an approved requirement from a built one without opening its card.
The page has carried the answer all along — every node is emitted with its status in a class — and painted over it, because the rule colouring a box neutral wins against the attribute that would have used the class.
A requirement rather than a repair: nothing ever said the drawing should show this, so nothing was broken.

A form rather than a colour, and the difference is deliberate.
Colour is what implements it here and reuses the palette the badges already use, but a page read in grey, or by somebody who separates two of those hues poorly, still has to work — which is why the status is also in the node's tooltip and why the legend names every status.

### FR-VIEW-190 — The dashboard counts every status

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-12
```

The dashboard **shall** state, for every status the standard defines, how many requirements carry it, including a status no requirement carries.

**Rationale.** A count per status is the first number a reader wants and the last one anybody wrote down: how much of this specification is built, how much is still paper.
The page has produced it from the start, the specification never asked for it, and FR-VIEW-180 already argues from it as settled fact — it faults the graph for staying silent where the dashboard counts the statuses and the chips filter by them.
A requirement reasoning from behaviour that nothing states is a requirement resting on nothing.

Every status rather than every status in use, and the zeros are the point.
A status missing from the table and a status carried by nobody look the same and answer different questions: the first says the page is showing less than it knows, the second says the project has nothing waiting to be built.

### FR-VIEW-200 — The coverage gaps are on the page, not only in the terminal

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: [FR-VIEW-040]
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-12
```

The rendered page **shall** report the coverage gaps FR-VIEW-040 names.

**Rationale.** FR-VIEW-040 asks the viewer for the four gaps and stops there, and the terminal alone satisfied it: its test ran `--coverage`, read what came back on standard output, and went no further.
Until this was written the page could have dropped its dashboard entirely and every requirement would still have held, save for the word "dashboard" in a list inside FR-VIEW-060. Yet the reader the page was made for is the reviewer who does not grep, and that reader will never reach for a flag.

A refinement rather than a requirement of its own: the four gaps are enumerated once, in the parent, and this narrows them to the branch that renders.
The cost is worth naming — reword the parent and this one is reworded silently, because the checker resolves the link but never compares what it lists.

### FR-VIEW-220 — The list can be narrowed to what is being looked for

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-17
```

When listing requirements, the viewer **shall** narrow the list to those matching every filter given, over the metadata a requirement carries and over the text it is written in.

**Rationale.** The whole list is the wrong answer to almost every question asked of a specification of any size: what is still `draft`, what belongs to one area, what mentions a word somebody remembers.
The viewer has done this since it was written and nothing said so, which is how it came to be the only behaviour here that could have been deleted without a requirement noticing.

Every filter rather than any, because narrowing is what the reader is after — `--status draft --area CHK` asks for the intersection, and a union would return more than either flag alone.
Over metadata and over text together, because the two questions arrive in the same breath: a status is what a reader filters by, a half-remembered phrase is what they search for, and a tool that answered only the first would send them back to grep.

Which flags spell it is not stated, here or anywhere: a requirement says what the system does, and the spelling of an invocation is the interface's business, which for a terminal query is its `--help`.

### FR-VIEW-210 — What outlived a cancelled requirement is on the page

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060, INV-SPEC-050]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-17
```

The rendered page **shall** list what still points at a cancelled requirement.

**Rationale.** Cancelling a requirement is the one edit whose consequences outlive it, and they are scattered across three places nobody looks at together: a live requirement still deriving from it (FR-CHK-190), a file its `code` field named and that nothing live claims now (FR-CHK-210), an annotation in the tree still naming it (FR-CHK-080).
Three rules, three messages, one per line of a terminal run — and a withdrawal is precisely the moment somebody needs the whole picture, because ADR-0013 has them resolving the dependants one level at a time and each decision needs to see what is left.

The checker reports these to whoever ran it.
The page is read by the reviewer who never will, and that reader is the one being asked to approve a cancellation.
FR-VIEW-200 made this argument for the coverage gaps and it holds here more strongly: a gap in coverage is a standing condition, while this list is the aftermath of a specific act and is at its most useful in the days right after it.

What counts as pointing is left to the reader of this statement rather than enumerated in it, and the three kinds above are what it comes to today.
Enumerating them would put the same list in two places — the rules already own it — and would grow this statement by one obligation every time a rule is added, which is how FR-VIEW-060 came to name six things and be verified for three.

The page computes this itself rather than reading what the checker found.
A page whose content depends on whether somebody ran another command is a page that lies quietly when they did not; and the scan it needs is one the viewer already performs for a single file, so what this asks for is that the rule live in one place and serve both — not that a second copy be written.

### FR-VIEW-230 — The page explains its own notation

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-08-20
```

The rendered page **shall** say what each notation it draws stands for.

**Rationale.** The verification method is drawn as a single letter and nothing on the page says what it is a letter of.
`T`, `D`, `I` and `A` are defined in `specs/50-verification.md` and in the field table of `specs/README.md` — two documents the reader this page exists for does not have, because the page is what gets sent to somebody who will never clone the repository.

Half the page already does this.
The graph carries a legend naming every link kind and every status (FR-VIEW-160, FR-VIEW-180), and the reader meets it after the list of requirements, where the same statuses appear as badges with no legend at all.
What was reasoned about the drawing holds for the badges: a page read in grey, or by somebody who separates two of those hues poorly, still has to work.

Each notation rather than a list of them.
Naming the badges, the chips and the colours in the statement would make it compound — half of them explained and the requirement stands satisfied on paper — and would grow it by one obligation every time the page gains a mark.
That is the mistake FR-VIEW-060 made and FR-VIEW-210 was written to avoid.

The form is left to whoever builds it.
A legend, a tooltip on the mark itself, or both are ways of saying the same thing, and which of them a mark deserves depends on where it sits; the obligation is that the reader can find out, not that a particular widget exists.

What a suite can hold here is the marks that exist when it is written, which is the position IF-SPEC-020 is in for rule names.
That is enough to catch the way this breaks in practice — a mark added to the page and explained nowhere.

### FR-VIEW-240 — A citation is printed, not typed

```yaml
status: implemented
verification: T
derives_from: [FR-VIEW-010]
depends_on: [FR-SKILL-200]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-09-01
```

When asked to cite requirements, the viewer **shall** print each one ready to paste: its identifier, its title, the file it is written in and its status.

**Rationale.** A citation assembled by hand is a citation invented by hand.
This project shipped `FR-CORE-020 — Autosave on loss of focus (specs/10-fr-core.md:42)` in the guide of every target it installed — a title belonging to nothing and a file that never existed — inside the example of the very rule that asks for citations, and it stood there until somebody read it against the specification.
Nothing about that was careless in an unusual way; it is what retyping from memory produces, and it is why the annotation warnings print the line to copy rather than describe it, and why the baseline row is printed rather than composed (FR-VIEW-120).

Titles were never the expensive half — `--list` prints all of them in one call.
What was missing is a form nobody has to assemble: the identifier, the title, the file and the status in the order they are read, so that what reaches the reader is what the specification says at the moment of asking.

Several at once, because the plans this exists for cite ten requirements rather than one, and a citation that costs a call each is a citation that gets abbreviated back to the number.

An unknown identifier is refused the way the single-requirement view refuses it, and a cancelled requirement is printed with the status it has: a plan naming a `superseded` requirement is exactly what the status half is there to catch.

### FR-VIEW-250 — What the specification is divided into

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-SPEC-010]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-09-09
```

Wherever the viewer states how many requirements the specification holds, it **shall** also state, for every area the project declares, how many carry it — including an area no requirement carries.

**Rationale.** A reader who arrives with a number gets an answer about it; a reader who arrives without one is handed the whole listing, and the whole listing stops fitting early.
Measured 2026-09-09: it prints as 15 KB here and as 56 KB in the first project that installed this framework, which holds 571 requirements and a traceability matrix of 187 KB.
The areas are the one partition that is always there — the middle segment of every identifier, declared by the project itself — where the architecture layer is optional and a project may have none.

Unprompted rather than only on request, and that is the whole of it.
A reader who knows to ask for the areas did not need them; the one this is for does not know the partition exists, and a flag they never type is a flag that does not help them.
The count of requirements already prints ahead of a search, of what describes a file and of the coverage gaps — three of the answers given to a reader who has no number to look up — and never ahead of a lookup by number, which is the case that has one.
So the areas cost no line of their own, and they appear in front of the reader they are for.

Including an area no requirement carries, for the reason `FR-VIEW-190` gives about the statuses: a declared area standing empty and an area nobody declared look the same from outside and answer different questions.
The first says the project drew a partition it has not filled; the second says the partition is not there.

### FR-VIEW-260 — The page offers what carries no requirements

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-09-09
```

The rendered page **shall** link every file in `specs/` that carries no requirements, except what the project has archived.

**Rationale.** The page has offered six of them since it was written — the standard, the glossary, the constitution, the matrix, the open issues and the baseline log — and the list was never described, so nothing noticed when it fell behind.
Three files the standard's own map names were missing from it: the introduction, the overview and the verification notes.

All three are absent from the checker's skipped set as well, which is how they came to be invisible from both ends at once: the parser reads them as requirement files and finds nothing, and the page does not offer them.
The list in the viewer was a copy of the checker's made by hand, and a copy is what drifts.

Every such file rather than three names, because the names are a convention the standard says so of, and a project may hold its introduction in one file or four.
Except the archived, because `specs/archive/` is not normative by that same map, and a link is an invitation to read.

Linked rather than rendered.
There is no block renderer here — the one function that turns specification text into HTML handles a single statement — and building one for the thirty-odd files this offers would be a second markdown implementation in a project that has none.

### FR-VIEW-270 — A search reaches the prose as well

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [IF-SPEC-010, INV-SPEC-070]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-09-09
```

When searching by text, the viewer **shall** search the documents in `specs/` that state no requirements — excluding the standard, the matrix, the open issues, the baseline log and the archive — as well as the requirements themselves, naming the file and the line of each hit.

**Rationale.** A search that reads only requirement text finds the word the reader guessed, and the reader who most needs the search is the one who does not yet know the project's word for the thing.
That is the failure this whole entrance was built for, and it is the half a procedure cannot fix: an instruction to read the glossary is read once at the start of a session, while the search is what an agent reaches for forty minutes later.

Line and file rather than a rendered paragraph, because `INV-SPEC-070` makes a line the unit of meaning in markdown written by hand — which is what lets a glossary table and a page of prose come back in the same shape.

**The page offers a wider set than this, and the difference is the point.** A link costs the reader nothing when it is the wrong document — they see the name and do not click.
A search hands back a line, and a line out of its document is what misleads.

**Four of the five exclusions have a reason of their own.**
The standard is the framework's own document, the same in every project that took it from here, and a search for a project's word would return its prose about how to write requirements.
The matrix is generated: measured over this repository, it adds nothing to an ordinary word — every line it contributes is already answered by the requirement above it — and what it alone carries is file paths, which have their own mode.
The baseline log is a list of versions.
The archive is not normative by the standard's own map.

**The open issues are excluded for a fifth reason, and it is the one worth writing down.** That register holds sentences it has since retracted — entries carry their own corrections, marked as such — and a search returns a line, not the paragraph that overturns it.
A reader handed a retracted sentence with no sign that it was retracted is worse off than one handed nothing.
Read whole it is sound; read by the line it is not, and a search reads by the line.

### FR-VIEW-280 — A search says what it left out

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-270]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-09-09
```

Where a search leaves something out — the prose because a filter asked about requirements, a document because the project does not have it, or hits beyond the number it prints — the viewer **shall** say which.

**Rationale.** The page already works this way and says why: what is dropped is stated rather than silently cut, which is how a reader learns that the graph drew a hundred and fifty nodes and how many it left undrawn.
A terminal answer had the same problem and no such rule.

The three cases fail the same way and would fail invisibly.
A filter suppressing the prose is right — `--status draft` is a question about requirements — but a reader who is never told will conclude the prose is not searched at all and stop asking.
A document the project does not have is the ordinary case in a project that adopted the framework rather than starting from it, and silence there reads as "searched, nothing found".
A truncated list read as complete is the worst of the three, because the reader acts on it.

Which, rather than that: naming the missing thing is what lets the reader ask again differently, and a bare "some results were omitted" costs a line and answers nothing.

### FR-VIEW-290 — A path searched for is answered by the mode for paths

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-020]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-09-09
```

Where the text searched for names a path the project carries, the viewer **shall** also name the mode that answers about a path.

**Rationale.** A path is not in what the search reads: it lives in the `code` and `tests` fields, and a hit happens only where the text being searched mentions the path in passing — searching for `tools/srs_arch.py` finds this sentence and nothing else, while the mode beside it returns nineteen requirements.
Silence is the wrong answer twice over — it is indistinguishable from "the project does not mention this file", and it arrives at the reader least able to tell the difference, since a reader who knew the mode would have used it.

Also, never instead: a needle can be a path and a word at once — `tools` is a directory here and a word in a dozen rationales — and a hint that replaced the results would answer a question nobody asked while dropping the one they did.

### FR-VIEW-300 — Which requirements are related to a line of a file

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-020, FR-CHK-080]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-09-16
```

When given a path and a line within it, the viewer **shall** name the requirements the annotation covering that line marks, and how many the whole file answers for.

**Rationale.** Two questions hide behind one path, and the answer to one is the wrong size for the other.
"What breaks if I touch this file" wants every requirement the file answers for, and that list is long by nature — thirty here at the median, sixty-four for one file of a project that adopted the framework — because a file carries many things.
"What does this line realize" wants the requirements marked at that line, and that set is one or two almost everywhere an annotation stands, because a line carries one thing.
The mode for a path answers the first and no mode answers the second, so a reader at a line reads the long list and picks by eye.

Added beside `FR-VIEW-020` rather than folded into it.
That requirement answers from three sources — the `code` fields, the `tests` fields and the annotations — and the first two have no lines to be asked about; this one answers from the annotations alone, and only where one covers the line: the annotation on the line itself, or the nearest one above it.
Narrowing the mode for a path to what a line marks would take the long answer away from the reader who came for it.

Both halves in one sentence for the reason `FR-VIEW-280` gives: a reader who asked about a line and was handed one requirement cannot tell it from one of thirty, and the count is what tells them.
The line before any annotation marks nothing, and the count is then the whole of the answer.
The count is printed with the command that lists what it counts, because a number a reader cannot expand is a number they will go and derive by hand; that is the same mode named, not a second one, which is why it earns no requirement of its own where `FR-VIEW-290` did.

A directory before the colon is refused with a sentence rather than read as a path: a directory has no lines, and the mode for a path would answer about the directory and say nothing about the number the reader typed.

### FR-VIEW-310 — The page links to the repository when told where it is

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
created: 2026-09-16
```

Where a repository URL is given — on the command line or in the project's configuration — the rendered page **shall** link each file it names to that repository, and each requirement to its line in it.

**Rationale.** A page read from the filesystem links relatively and works for whoever has the tree; a page published for people who will never clone it has nowhere relative to point.
The URL is a prefix ending at a revision, copied out of a browser rather than assembled from a host's URL shape, and a pipeline passes the revision it built from — a link into a moving branch lies as soon as the branch moves, which is the argument `FR-CI-040` makes for what it hands the viewer.
The command line wins over the configuration because the configuration names the branch a person reads by hand and the pipeline knows the commit.

Written down six weeks after the flag: the behaviour was promised by a requirement about the pipeline the day after the flag arrived, built in the viewer, and described by nothing in this area — which the audit found because the annotation nearest the code named a requirement about baselines.
Files and requirements in one sentence because one function makes both links and a page with half of them pointing at a clone the reader does not have is a broken page, not half of a working one.
