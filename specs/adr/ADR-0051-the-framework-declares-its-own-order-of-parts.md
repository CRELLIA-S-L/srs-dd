# ADR-0051 — The framework declares its own order of parts

- **Status:** accepted
- **Date:** 2026-10-07
- **Related requirements:** FR-ARCH-590, IF-ARCH-070, FR-ARCH-650, FR-ARCH-660, FR-ARCH-670, INV-ARCH-020

## Context and problem statement

The layer gained an order of parts on 2026-10-06 and this repository declared none, so four things it built were exercised by fixtures alone: the rule on a dependency running upward, the column in the map, the section in the document and the drawing laid out by level.
A capability its own author declines is one nobody reads the output of.
The question was not whether to declare an order but which one: the parts already form a stack, and an order that only repeats what the drawing computes from `depends_on` adds nothing a reader did not have.

## Considered options

1. Declare nothing, as before.
2. Group strictly by computed depth — one group per level the drawing already draws.
3. Group by role, coarser than the depth, and leave outside it the parts the graph never touches.
4. Declare an order over every part, putting the two unconnected ones at the bottom.

## Decision outcome

Option 3, as:

```json
"layers": [["E-090"], ["E-060", "E-050"], ["E-020", "E-030", "E-040", "E-070"],
           ["E-110", "E-120"], ["E-010"]]
```

The gate on top because it runs everything; the two optional layers next; then the commands a person runs and the procedures they read; then the two halves the viewer was cut into; the checker at the bottom, which everything leans on and which leans on nothing.
`E-080` and `E-100` — the standard with the payload, and this project's own documentation — stay outside the order: nothing in the graph touches them in either direction, and placing them at a level would be a claim the model does not make.

**Option 2 was rejected because it states the computation.** The depth is six levels deep with one part in most of them, and a reader learns from it exactly what the drawing already showed; worse, it would put the release command beside the specification's page because both sit two steps above the checker, which says nothing about either.

**Option 4 was rejected for the same reason in miniature.** The bottom of an order is a claim that everything above may lean on it, and nothing leans on those two parts at all.

**What the order adds over the computation is a commitment.** The depth is a fact recomputed on every run and true whatever the code does; the order is a decision that an edge running the other way is a finding. Two edges inside a group are the deliberate exception: the architecture layer leans on the grounds register to say what a part stands on, and the specification's page leans on its model — in both cases the pair are siblings, and a level between them would be a boundary this project chose not to draw.

### Consequences

The map now says where each part stands, the document carries the order with the two parts outside it, and the drawing on the page is laid out by it instead of by the computed depth.
Declaring the order also surfaced something nobody had written down: `E-070` sits inside `E-090`, because the gate carries `tests` and the procedures carry `tests/eval` within it.
That nesting has been there for weeks, invisible, and until `INV-ARCH-020` was built on 2026-10-07 the owner of a file under `tests/eval` depended on the order the records happened to be written in.
It is the right nesting — the eval fixtures are the procedures' measurement material and not the gate's suites — and it is now stated where a person reads it.
A future edge that runs upward in this stack is a red run rather than a fact, which is the whole of what was bought here.
