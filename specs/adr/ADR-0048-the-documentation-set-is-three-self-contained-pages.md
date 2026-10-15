# ADR-0048 — The published documentation is three self-contained pages the framework draws itself

- **Status:** accepted
- **Date:** 2026-10-06
- **Related requirements:** FR-ARCH-520, FR-ARCH-530, FR-GND-580, IF-SPEC-050, INV-SPEC-130, FR-CI-190

## Context and problem statement

The specification has been published as a page since `FR-CI-040`: one self-contained HTML file, with the graph image beside it, deployed to GitHub Pages from the default branch.
The two optional layers have no such form. The architecture document prints markdown (`FR-ARCH-410`), the register's dashboard is a generated markdown file inside `grounds/`, and neither is published anywhere — so the audience that will never clone the repository sees the requirements and nothing about what the system is made of or what its claims rest on.

The ask was a publishable form for those two and a pipeline to carry them. Three questions had to be settled before any of it could be written: what draws the architecture diagram in HTML, where the pages' style comes from, and what the published set is.

## Considered options

**The diagram.**

1. Keep the markdown form's Mermaid source in the page and load `mermaid.js` from a CDN.
2. Lay the drawing out in the command and emit an inline SVG.
3. Leave the Mermaid source as a code block, undrawn.

**The style.**

1. A stylesheet of the page's own, in the command that prints it.
2. Share the specification page's stylesheet, widening `E-120`'s interface to publish it.

**The set.**

1. The two new pages beside the specification's, named and linked as one set.
2. The architecture page alone, since the dashboard is already a document in the repository.

**What decides which links a page carries.**

1. The caller names them, from the set of published names, and a page with nothing named carries no links.
2. The page decides from what the repository holds — a `grounds/` directory, an `arch/` one.
3. The page decides from what is already beside its output.

## Decision outcome

Option 2 for the diagram, option 1 for the style, option 1 for the set, option 1 for the links.

**The command draws the diagram** (`FR-ARCH-530`).
A CDN script is three lines against a layout the command has to carry, and it was still refused: a page that fetches anything stops working where the network does not reach, and a published page that calls a third party reports every one of its readers to it — a cost the reader pays and never agreed to.
It also contradicts what the page is for: `FR-ARCH-520` asks for a file that needs nothing beyond itself, and `NFR-SPEC-010` has kept this framework free of anything to install since `ADR-0003`.
Undrawn source was refused because the dependency graph is the one thing about a cut that prose cannot carry, which is `FR-ARCH-430`'s own reason for existing.

**Each page carries its own stylesheet** (`FR-ARCH-520`, `FR-GND-580`).
Sharing would make the specification's page a dependency of both layers and widen a boundary this release has just narrowed (`ADR-0047`), and what is shareable is mostly the palette — a copy of a list another file defines, which `INV-SPEC-110` then has to hold in agreement.
The cost is accepted knowingly: three pages that do not look identical. One look is a later decision, and the cheap version of it is a palette in one place rather than a shared renderer.

**The set is three pages with fixed names** (`IF-SPEC-050`), published together from one revision (`FR-CI-190`).
A set of names is an interface: the pages link by them, the pipelines write by them, and readers bookmark them, so they are published once and never moved.

**The caller names the links** (`INV-SPEC-130`).
A link then exists on one ground only — somebody said that file will be there — and the page cannot promise a sibling nobody printed.
Deciding from the repository's layers was written first and refused on reading it back: a hand-run that prints one page would carry a link to a page it never produced, which is the broken link the set exists to avoid, and a command printing to stdout cannot look beside its output to check.
Deciding from what is already beside the output was refused for the same reason from the other end: two of the three print to stdout and know nothing about where they land, so the result would depend on the order of the steps, and the page rendered first would never gain the link.
The flag takes a name from `IF-SPEC-050`'s set and refuses anything else, so a published URL is never one the caller invented.

### Consequences

Each of the three renderers owns its stylesheet, which is the price of three parts that do not reach into one another.
Two of them carry a graph layout as well: the architecture page gains an element graph that the specification page's requirement graph cannot be reused for — that one is keyed to areas and statuses, and a dozen parts with a dozen edges is a different drawing — while the dashboard page draws nothing, being tables.
A project that keeps neither layer sees no change: one page, named as before, linking nothing.
Publishing stays the project's own act: `ci/github-workflow.yml` carries the Pages block commented out with the setting it needs, and `FR-INIT-290` keeps an upgrade from rewriting a pipeline at all, so no project begins publishing its specification because it upgraded.
