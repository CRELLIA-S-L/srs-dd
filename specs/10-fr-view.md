# Functional requirements — view

The viewer, `tools/srs_view.py`: the read-only projections of what the
checker validates — terminal queries and one self-contained page.

### FR-VIEW-010 — One requirement with its links resolved

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

When given a requirement identifier, the viewer **shall** print that
requirement with its metadata, its statement, and its links resolved in both
directions, incoming links included.

**Rationale.** Incoming links are the blast radius of a change and are
computed, so they exist nowhere in the source files.

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
```

When given a path, the viewer **shall** list the requirements that name it in
their `code` or `tests` fields or that the file's own annotations point at,
accepting a directory as well as a file.

**Rationale.** This is the first question of every task that touches existing
code, and grepping the spec by hand misses annotations.

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
```

When given a requirement identifier, the viewer **shall** print what derives
from it, and print the opposite direction — what it derives from — where the
upward flag is given.

**Rationale.** Changing a requirement without seeing what hangs below it is
how a small edit silently invalidates a subtree.

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
```

The viewer **shall** report, on request, realized requirements with no listed
tests, drafts that already carry code, realized requirements resting on a
draft, and source files no requirement that has not been cancelled
references against the total number of source files.

**Rationale.** These four lists are what an audit starts from; the checker
reports them as warnings at most — and under a lenient configuration not at
all — so something has to surface them on demand.

The fourth is a proportion where the others are lists, because a count of
unreferenced files means nothing on its own: eleven is most of a young
project and a rounding error in an old one. The other three are already
proportions of a sort — the specification is their denominator, and it is
on the same screen.

A cancelled requirement does not count as referencing its files, for the
reason FR-CHK-210 gives and so that the two tools agree: this one said
plainly that a file named by a `withdrawn` requirement was covered while
the checker, in the same tree and the same run, called it unclaimed. A
reader has no way to tell which of the two is speaking about their code.

### FR-VIEW-050 — Difference against a baseline

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

When given a git revision or the version of a logged baseline, the viewer
**shall** print how the specification changed since it: requirements added,
removed, and the fields that differ.

**Rationale.** A baseline is only useful if the difference from it can be
read; a raw `git diff` of the specification is dominated by reflow. A
version is accepted because a baseline need not have a tag to name it by
(INV-SPEC-040), and asking a reader to find the commit themselves would put
the tag back in the middle of the process.

### FR-VIEW-060 — A page that opens from the filesystem

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

The viewer **shall** render the specification into a single self-contained
HTML file — search, filters, a status dashboard, a graph of the links
between requirements grouped by area, and links in both directions —
that requests nothing over the network.

**Rationale.** A reviewer who does not grep still has to read the
specification, and a page that needs a CDN is a page that stops working
offline, behind a corporate proxy, and in five years.

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
```

Two renderings of an unchanged specification **shall** produce byte-identical
pages.

**Rationale.** A timestamp in the output would make every CI run a diff, and
the page could never be committed or compared.

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
```

The viewer **shall not** modify anything under `specs/` or leave bytecode in
the project it was run in.

**Rationale.** The traceability matrix stays the checker's artifact, with one
generator; a viewer that also wrote would create a second source of truth.

### FR-VIEW-090 — The page says what it is showing

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/view-smoke.sh]
```

The rendered page **shall** state the specification's current baseline, the
framework version that generated it, and — where the history those
baselines name was not available to the render — that they could not be
read.

**Rationale.** The page lives at a stable address and outlives a dozen
releases. A reader arriving from a bookmark cannot tell a fresh page from a
six-month-old one, and the two questions — how current is the specification,
what rendered it — have different answers when a project stops upgrading.

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
```

The rendered page **shall** let a reader pick any two of the specification's
baselines and see which requirements were added, removed, or had a field or
their statement changed between them.

**Rationale.** The baseline log records what was frozen, not what changed
while freezing it; that answer exists only in `--diff`, which needs a clone.
Comparing an arbitrary pair means the page carries the specification at every
baseline, so it carries it the way a repository does: the oldest baseline in
full and each later one as its change, folded up on demand. Statements travel
as fingerprints — a rewording still shows as a change, without the text of
the whole specification riding along once per baseline.

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
```

The graph on the page **shall** fill the panel it is drawn in and
let a reader move and scale it, collapse an area into a single block, return
the view to where it started, and see what a node links to and what links to
it.

**Rationale.** A specification of any size draws a graph larger than the
viewport, and a picture that can only be scrolled is a picture nobody
studies. What is filled is the panel rather than the drawing: sized from the
drawing, a small specification gets a postage stamp to work in — and a
reader who has zoomed into one corner needs the way back, which is what
returning the view is for.

Collapsing an area is what pulling a node aside used to be. The gesture was
never about the node: it was about clearing what stood in front of the thing
being read, and in a drawing grouped by area (ADR-0012) the thing in the way
is a whole column. Moving one box out of a column of nineteen achieves
nothing, and it also has nowhere to go — a position now means membership of
an area and a place in its ordering, so a dragged node is a node lying about
where it belongs.

Done in the page's own script rather than with a graph library: the layout
is arithmetic — a lane per area, a row per requirement — so a library would
be paid for in every reader's download and every installed project, in
exchange for panning.

### FR-VIEW-120 — The baseline row is written by the tooling

```yaml
status: implemented
verification: T
derives_from: [FR-VIEW-050]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_view.py]
tests: [tests/baseline-smoke.sh]
```

When asked for a baseline row, the viewer **shall** print it ready to paste:
version, date, tag, and what changed since the previous baseline — reading
the working tree, or the tagged revision itself where that tag already
exists.

**Rationale.** Four rows were written by hand into this project's own log,
each time by reading a matrix and reducing a diff — mechanical work that
invites a wrong count nobody would ever notice. Printed rather than written
into the file: the viewer never touches `specs/` (FR-VIEW-080), and a row a
person pastes is a row a person has read. A row asked for after its tag
exists describes that tag rather than whatever the working tree has drifted
to since, so writing it late costs nothing in accuracy.

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
```

When a requirement is picked from any view of the page — a link in the
dashboard or in a baseline comparison, a node in the graph — the page
**shall** show that requirement, switching to the view that renders it and
clearing whatever filter would hide it.

**Rationale.** Following links in both directions is what this page is for,
and three of its four views could not do it: the dashboard and the baseline
comparison render links whose target lives in a hidden section, so following
one moved the reader nowhere and gave no sign of why. The graph reached it
by its own handler rather than by this rule, which is how it stayed broken
unnoticed when a later change stopped its clicks from firing at all.

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
```

Where opening is asked for, the viewer **shall** open the page it has just
rendered in the reader's browser.

**Rationale.** Rendering and opening are one act for a reader and two
commands with a path between them, and the path differs by platform — which
puts the knowledge in a procedure an agent reads, and leaves whoever works
without one to look it up. The standard library opens a browser in a line,
so the tool can carry it once instead of every reader carrying it forever.

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
```

When a requirement is chosen as the root, the graph **shall** draw only that
requirement and what lies within a chosen number of links of it.

**Rationale.** A drawing of everything is the one view a specification of any
size cannot use, and the tools that solve this converge on the same answer: a
root and a radius, whether it is `root_id` with `root_depth` in
sphinx-needs or impact analysis from a selected item in the commercial
tools. StrictDoc still lists the whole-project view as wanted rather than
done. The page already lights a node's immediate links on hover, which is
this idea stopped one step short — the neighbourhood is computed and then
thrown away instead of becoming the drawing.

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
```

The graph **shall** draw each kind of link between requirements in a form
that tells it from the others, and let the reader leave out the kinds not
wanted.

**Rationale.** Two of the four link fields were drawn and two were not, which
in this specification meant showing twenty-one edges and hiding forty-four:
the reader was studying the minority relation without being told. Drawing
everything and subtracting is what `needflow` does with its `link_types`
option, and it is the safer default — a link that exists and is not drawn is
invisible, while one that is drawn and unwanted is one click away. Layers
stay derived from `derives_from` alone: it is the relation that means
"higher level", and a layer computed from the union would silently change
the vertical axis from abstraction to order of work.

The drawing reduces along two axes and they are not the same one. This is
by kind: leave out `depends_on` and every edge of that relation goes,
wherever it is. Narrowing to a root and a radius is FR-VIEW-150, and it cuts
by distance instead. The distinction is worth stating because it was once
lost: a root-and-radius control was taken to satisfy both, and this
requirement stood at `implemented` with half of it unwritten.

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
```

The graph **shall** draw a requirement's node in a form that tells its
status from the other statuses.

**Rationale.** The dashboard counts the statuses and the chips filter by
them; the graph was the one view that stayed silent, so a reader looking at
the drawing could not tell an approved requirement from a built one without
opening its card. The page has carried the answer all along — every node is
emitted with its status in a class — and painted over it, because the rule
colouring a box neutral wins against the attribute that would have used the
class. A requirement rather than a repair: nothing ever said the drawing
should show this, so nothing was broken.

A form rather than a colour, and the difference is deliberate. Colour is
what implements it here and reuses the palette the badges already use, but a
page read in grey, or by somebody who separates two of those hues poorly,
still has to work — which is why the status is also in the node's tooltip
and why the legend names all five.

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
```

The dashboard **shall** state, for every status the standard defines, how
many requirements carry it, including a status no requirement carries.

**Rationale.** A count per status is the first number a reader wants and the
last one anybody wrote down: how much of this specification is built, how
much is still paper. The page has produced it from the start, the
specification never asked for it, and FR-VIEW-180 already argues from it as
settled fact — it faults the graph for staying silent where the dashboard
counts the statuses and the chips filter by them. A requirement reasoning
from behaviour that nothing states is a requirement resting on nothing.

Every status rather than every status in use, and the zeros are the point. A
status missing from the table and a status carried by nobody look the same
and answer different questions: the first says the page is showing less than
it knows, the second says the project has nothing waiting to be built.

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
```

The rendered page **shall** report the coverage gaps FR-VIEW-040 names.

**Rationale.** FR-VIEW-040 asks the viewer for the four gaps and stops
there, and the terminal alone satisfied it: its test ran `--coverage`, read
what came back on standard output, and went no further. Until this was
written the page could have dropped its dashboard entirely and every
requirement would still have held, save for the word "dashboard" in a list
inside FR-VIEW-060. Yet the reader the page was made for is the reviewer who
does not grep, and that reader will never reach for a flag.

A refinement rather than a requirement of its own: the four gaps are
enumerated once, in the parent, and this narrows them to the branch that
renders. The cost is worth naming — reword the parent and this one is
reworded silently, because the checker resolves the link but never compares
what it lists.

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
```

When listing requirements, the viewer **shall** narrow the list to those
matching every filter given, over the metadata a requirement carries and
over the text it is written in.

**Rationale.** The whole list is the wrong answer to almost every question
asked of a specification of any size: what is still `draft`, what belongs to
one area, what mentions a word somebody remembers. The viewer has done this
since it was written and nothing said so, which is how it came to be the
only behaviour here that could have been deleted without a requirement
noticing.

Every filter rather than any, because narrowing is what the reader is
after — `--status draft --area CHK` asks for the intersection, and a union
would return more than either flag alone. Over metadata and over text
together, because the two questions arrive in the same breath: a status is
what a reader filters by, a half-remembered phrase is what they search for,
and a tool that answered only the first would send them back to grep.

Which flags spell it is not stated, here or anywhere: a requirement says
what the system does, and the spelling of an invocation is the interface's
business, which for a terminal query is its `--help`.

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
```

The rendered page **shall** list what still points at a cancelled
requirement.

**Rationale.** Cancelling a requirement is the one edit whose consequences
outlive it, and they are scattered across three places nobody looks at
together: a live requirement still deriving from it (FR-CHK-190), a file its
`code` field named and that nothing live claims now (FR-CHK-210), an
annotation in the tree still naming it (FR-CHK-080). Three rules, three
messages, one per line of a terminal run — and a withdrawal is precisely the
moment somebody needs the whole picture, because ADR-0013 has them resolving
the dependants one level at a time and each decision needs to see what is
left.

The checker reports these to whoever ran it. The page is read by the
reviewer who never will, and that reader is the one being asked to approve
a cancellation. FR-VIEW-200 made this argument for the coverage gaps and it
holds here more strongly: a gap in coverage is a standing condition, while
this list is the aftermath of a specific act and is at its most useful in
the days right after it.

What counts as pointing is left to the reader of this statement rather than
enumerated in it, and the three kinds above are what it comes to today.
Enumerating them would put the same list in two places — the rules already
own it — and would grow this statement by one obligation every time a rule
is added, which is how FR-VIEW-060 came to name six things and be verified
for three.

The page computes this itself rather than reading what the checker found.
A page whose content depends on whether somebody ran another command is a
page that lies quietly when they did not; and the scan it needs is one the
viewer already performs for a single file, so what this asks for is that
the rule live in one place and serve both — not that a second copy be
written.
