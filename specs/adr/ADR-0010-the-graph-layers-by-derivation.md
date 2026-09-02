# ADR-0010 — The graph layers by derivation and draws the rest across it

- **Status:** superseded by ADR-0012
- **Date:** 2026-08-10
- **Related requirements:** FR-VIEW-160, FR-VIEW-150, FR-VIEW-060

> **Superseded on 2026-08-11.** The last consequence below is the one that
> came true: `depends_on` is how this project mostly expresses structure,
> `derives_from` is left empty by three requirements in four, and the
> vertical axis carried almost nothing. ADR-0012 replaces the layers with
> lanes by area. What survives is the part this decision got right — the
> kinds of link are told apart by their form, and toggling one does not
> move anything (FR-VIEW-160).

## Context and problem statement

The graph drew two of the four link fields.
In this specification that meant twenty-one edges shown and forty-four hidden: `derives_from` is drawn and `depends_on` is not, so a reader was studying the minority relation, and fifty-five of eighty-three requirements never appeared at all.

Drawing `depends_on` fixes that and immediately raises a harder question.
The layout is layered, and a layer has to be computed from something.
The two relations do not mean the same thing: `derives_from` says "this exists because that does", which is a level of abstraction; `depends_on` says "this is meaningless without that", which is closer to an order of work.

## Considered options

1. Layers from `derives_from` alone; `depends_on` drawn across the layers, distinguishable by its own form.
2. Layers from the union of both relations.
3. Derivation by default, dependencies opt-in, with layers recomputed each time the reader switches.

## Decision outcome

Option 1.

A layer is a claim about abstraction, and `derives_from` is the only field that carries it.
Option 2 keeps every arrow pointing downwards, which is what a layered drawing is for, but the price is that the vertical axis silently changes meaning: a requirement would sink because something it needs sits above it, not because it is more concrete.
Two meanings on one axis is worse than some arrows running sideways.

Option 3 was rejected on a different ground: recomputing the layout when a kind of link is toggled moves every node, and a reader who has just found what they were looking for loses it.
Toggling a kind of link should change which arrows are drawn, not where anything sits.

### Consequences

- Some edges will run sideways, and some upwards, which a layered drawing normally avoids.
  That is the visible cost, and it is why telling the kinds apart at a glance is a requirement rather than a nicety (FR-VIEW-160).
- Cycles across the two fields together stop mattering for the layout, since only `derives_from` feeds it — the checker already forbids a cycle within each field separately (FR-CHK-040).
- The picture will get denser: at forty-four more edges the case for narrowing to a neighbourhood (FR-VIEW-150) stops being a convenience.
- Should `depends_on` ever become the way this project mostly expresses structure, with `derives_from` left empty, the vertical axis will carry almost nothing and this decision is what to revisit.
