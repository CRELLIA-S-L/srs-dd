# ADR-0047 — The viewer is cut into the model, the command and the page

- **Status:** accepted
- **Date:** 2026-10-05
- **Related requirements:** IF-VIEW-010, FR-VIEW-060, FR-VIEW-080, NFR-VIEW-010

## Context and problem statement

`srs-dd/tools/srs_view.py` is 3 139 lines in eight sections — model 293, selection 113, terminal 532, difference 284, HTML 969, graph 198, page 372, entry point 279 — carried by one element, answering for 51 obligations, and holding the most stretched requirement in this specification by incoming links.
Because the part is one file, no instrument can see a boundary inside it: the dependency rules read imports, and there are none within a module, so the layer is blind here by construction.
Three readers already cross what would be its boundaries: both layers run the command for the model `IF-VIEW-010` publishes, the baseline command imports the row it computes, and the page folds the same model into HTML.

## Considered options

1. Leave it: one part, one file, the sections marked by comment banners.
2. Cut the page out and leave the model inside the command.
3. Cut three ways: the model as a module, the command as it is, the page as a module.
4. Cut by the eight sections, a part each.

## Decision outcome

Option 3.

**The command stays where it is.** `srs_view.py` is the name the guides, the documents, the installer's tuples and both layers' subprocess calls use; a split that moved it would break every one of them for no gain. So `E-020` narrows to the terminal answers and keeps the file.

**The model leaves first**, as `E-110`: it is what the three readers cross for, and its boundary is already published.

**The page leaves second**, as `E-120`: half the lines, and nothing in the terminal reaches it but one flag. It is also where the arithmetic the page's own script repeats lives, which `ADR-0045` left as an open duplication.

**Option 4 would cut as finely as the file tree**, which the layer's standard refuses: eight parts of a tool whose sections are read together say nothing the banner comments did not.

### How it works

This is an **extraction**, not a move, and the layer reads the two differently.
A move record re-homes a file that exists: the path leaves one part's `carries` and arrives in another's, and the checker says the move is finished when every path is at the receiving end.
Here the receiving files do not exist yet, so the record would be complete the moment it was written — which is what the checker said when this was first drafted as two moves.
The act is the design-mode loop instead: `E-110` and `E-120` stand `proposed`, their carriers name files not yet written, and when the files exist and their obligations are realized the checker says so and a person flips the status, narrowing `E-020`'s record in the same edit.

### Consequences

The `code` field of 42 `VIEW` requirements has to be re-pointed as the lines move, one file at a time with the project's own checks between, as `FR-SKILL-490` asks.
`E-020`'s interface loses the module names the baseline command imports and `E-110`'s gains them, which `FR-ARCH-490` will report until it is done.
Both halves were carried out on 2026-10-05, the model first and the page second, each verified by rendering the same specification through the file before the cut and the files after it: the command's answers and the page came back byte for byte the same.
Two things the design did not foresee came out of reading the code. `print_diff` prints to the terminal, so it stayed with the command although `FR-VIEW-050` is computed in the model, and the three tables `FR-VIEW-390` asks for do not sit together: the methods and the status colours are the page's, and the backward label of an incoming link is read by both projections, so it lives in the model.
The renderer is imported where `--html` and `--svg` are served rather than at the top of the command, so a terminal answer is not stopped by its absence — a hand install that copies the files one by one is the case that makes the difference visible.
The published command and every call of it stay exactly as they are; a project upgrading sees two new files under `srs-dd/tools/` and nothing else.
That an extraction is not a move was missing from the layer's standard when this was drafted, which is why the first draft was written as two move records and reported finished the moment it was saved; the standard says it now, under *Recording a move*.
