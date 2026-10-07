# ADR-0052 — The architecture document leaves the layer

- **Status:** accepted
- **Date:** 2026-10-07
- **Related requirements:** FR-ARCH-410, FR-ARCH-200, FR-ARCH-490, FR-ARCH-590

## Context and problem statement

`E-060` answered for 88 requirements, against 70 for the next largest part, and carried two tools: the layer's checker at 1 908 lines and the document it prints at 683.
The two already had a boundary — the document imports `srs_arch`, and nothing imports the document — and the layer could not hold them to it, because it reports a dependency between *parts* and the two were one part.

Measured rather than argued, on 2026-10-07: the checker was made to import the document, which turns a one-way boundary into a mutual one, and the layer reported nothing at all — `Warnings: 0`.
The same code with the same import, cut into two parts, drew four findings.
The exposure is therefore not the size of the part but what the size hides: the larger a part, the more code sits where no rule of this layer can speak.

## Considered options

1. Leave it and accept that nothing inside the layer is watched.
2. Cut the document out as a part of its own.
3. Cut by tool, every tool its own part, across the whole repository.
4. Wait for a trigger — the document passing a thousand lines, a third reader of what it builds, or one change touching both files for different reasons.

## Decision outcome

Option 2, as `E-130`, carrying `srs-dd/tools/srs_arch_doc.py`, declaring `depends_on: [E-060]` and stating in its interface the one command it offers.

Fourteen obligations that are the document's alone moved with it — the document printed, what it states of the parts, the drawing, the divergence, the silences, the empty sections, what each part protects and stands on, the page and the two requirements about the published set.
Six that are about both files stay named by both parts, the way the viewer's three parts share the constraints that bind every tool here.
`E-060` keeps the checker, the standard, and 74 obligations, and its interface now states the module the document imports, which is what crosses the new boundary.

In the order of parts the document joins the group nothing leans on, beside the gate: it reads the layer and nothing reads it.

**Option 1 was rejected by the measurement.** The likely way it would have cost something is ordinary: somebody asks the checker to print the document — one flag — the import goes in, the run stays green, and two tools fuse into one 2 600-line part where nobody can say which reads which.

**Option 3 was rejected because the layer's standard refuses it**: cutting as finely as the file tree says nothing the directory listing did not. The seam here is not "one tool, one part" but a projection split from what it projects, which is the seam `ADR-0047` drew through the viewer.

**Option 4 was rejected because the trigger it waits for is the damage.** Each of the three signs would arrive *after* the thing they signal, and the cut costs one record, one path and one declared edge.

### Consequences

The same import that drew nothing now draws three findings — the undeclared dependency, the edge running against the declared order, and the part reached by a name its interface does not state — and fails a `--strict` run, which is what the hook and the pipeline do.
The layer holds thirteen parts, `E-060` is no longer the largest by a distance, and the map, the document and the page say so without an edit.
No move record was written: the redraw was agreed and carried out in one set of edits, so a record coordinating it would have been complete the moment it was saved — the trap `ADR-0047` describes for an extraction, in the other direction.
