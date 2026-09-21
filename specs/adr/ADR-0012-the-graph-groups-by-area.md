# ADR-0012 — The graph groups by area

- **Status:** accepted
- **Date:** 2026-08-11
- **Supersedes:** ADR-0010
- **Related requirements:** FR-VIEW-060, FR-VIEW-110, FR-VIEW-180

## Context and problem statement

ADR-0010 put the vertical axis of the graph on `derives_from`, on the argument that a layer is a claim about abstraction and only that field carries one.
The argument still holds.
What did not hold is that this specification has an abstraction to draw.

At 87 requirements and 77 links it stands like this: 55 links are `depends_on`, 21 are `derives_from`, one is `refines`.
Sixty-five requirements have no derivation parent at all, so they land in a single row.
The deepest chain is two.
The drawing measures 8825 by 179 — a ribbon at 49:1, in which a node fitted to a thousand-pixel panel is thirteen pixels wide and the reader is looking at a smear.

The structure the specification does have is the area: six of them holding between nine and nineteen requirements, with 50 of the 77 links staying inside one.
Types do not group — 72 of 87 are `FR`.

So the question is not how to improve a layered drawing.
It is which structure the drawing should show, given that the one it promises is not there.

## Considered options

1. Lanes by area: a column per area, requirements ordered by number within it, position computed by arithmetic.
2. An arc diagram: one column of all requirements ordered by area and number, links drawn as arcs beside it.
3. An adjacency matrix ordered by area — the design-structure matrix of systems engineering.
4. Keep the layers and accept the ribbon.

## Decision outcome

Option 1.

Option 4 is what the open issue rejected: a default view a newcomer cannot read is not repaired by the narrowing in FR-VIEW-150, because the narrowing is what somebody does *after* the picture has told them where to look.

Option 3 is the strongest of the alternatives and the one the literature would pick: above a couple of dozen nodes a matrix beats a node-link drawing at nearly every task except following a path, and here the longest path is two.
It never crosses an edge, it needs no layout at all, and it would have deleted the most code.
It was rejected on what it costs the reader rather than the author.
A matrix is a skill: a reader who has not used one does not know that the blocks on the diagonal are the areas, and the page is aimed at the reviewer who does not grep.
It also ends the node — and with the node go the neighbourhood view, the hover that lights what a requirement links to, and every requirement written against a drawing that has nodes in it.

Option 2 keeps the nodes but spends the gain: one column of 87 with 77 arcs beside it is roughly 1200 by 1900, and the long arcs — the cross-area ones, which are the interesting minority — are laid over the short ones, which are the majority.
Sorting the column by area makes the grouping visible and does nothing about the overlap.

Lanes take the same ordering and give it a second dimension.
Six columns of up to nineteen rows measures 1005 by 956 — a shape that fits a screen instead of one that has to be swept.
The 50 intra-area links become short hops down a lane; the 27 that cross areas are the only lines that traverse the drawing, so the thing worth noticing is what stands out, without anybody having to encode it.
And the layout is arithmetic: a lane index from the area, a row index from the number.

### Consequences

- The barycentre ordering, the crossing counter and the transposition pass go — some eighty lines of the Sugiyama heuristic, along with the two suite blocks that exercised them.
  Determinism (FR-VIEW-070) stops being a property of a heuristic that must be kept stable and becomes a property of arithmetic.
- A position now means something it did not: membership of an area, and a place in that area's ordering.
  Dragging a node therefore stops being harmless, and FR-VIEW-110 trades it for collapsing an area — which is what the gesture was for anyway, clearing what stands in front of the thing being read.
- Vertical order inside a lane is the identifier, which is very nearly the order the requirements were written in.
  That is a real axis, and a smaller claim than abstraction: it says when, not how high.
- An edge from one row of a lane to another four rows down would pass under the boxes between them, so intra-lane edges bow out to the side.
  The rule has to be written twice — once where the page is generated and once in the script that recomputes an edge — and the two must agree, or an edge changes shape the moment an area is collapsed.
- What limits the drawing is now the tallest area rather than the total number of requirements.
  An area is capped at 99 by the identifier grammar (`specs/91-open-issues.md`), which puts a floor under how bad this can get and makes `GRAPH_NODE_LIMIT` measure the wrong thing.
  *Since 2026-09-20 (ADR-0028):* the cap is gone — a number widens past 999 — so the tallest area is bounded by nothing but its own growth, and `GRAPH_NODE_LIMIT` is the one bound that remains.
- Should this specification ever grow a real derivation hierarchy — deep chains, most requirements with a parent — the axis it deserves is the one ADR-0010 argued for, and this decision is what to revisit.
