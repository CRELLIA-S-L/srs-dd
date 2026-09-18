---
name: srs-arch
description: Working with the architecture layer — naming the parts a system is cut into, saying what each carries, and reading the disagreements the checker computes — three between that description and the specification, two about the dependencies the parts declare. Invoke when the user asks what the system is made of, wants to add or redraw a part, or when a change moved files between parts. For requirements themselves use srs and srs-new.
---

# Working with the architecture layer

**The format lives in `arch/README.md`.** It is deliberately not restated here: two descriptions of the same rules would eventually diverge.
Read it if you have not in this session.

The layer answers a question the specification does not: not what the system must do, but what it is made of.
An element is a part with a responsibility, the files that are that part, and the requirements it carries.

## First things first

```
python3 tools/srs_arch.py --no-write
```

Three findings are between the description and the specification, and they are not the same finding:

- **a carrier no element claims** — a file the specification says realizes a requirement, and no part owns it.
  Either a part's `carries` is out of date, or the file belongs to a part nobody has written down.
- **a realized requirement no element carries** — something is built and no part answers for it.
- **an element carrying no requirement** — a part that answers to nothing, which is either a part nobody needed or a requirement nobody wrote.
  Where the requirements are derived, a third reading: the part owns files no realized requirement names, and the question is whether the files or the requirement are missing.

Say which of the readings it is before proposing an edit, naming the requirement and the element in it as `AGENTS.md` asks the first time each appears — the requirement from the viewer's `--cite`, the element from `python3 tools/srs_arch.py --cite <ID>…`; a finding line copied as the checker printed it names them by key, which is not yet a citation.
Two of the three findings are about a requirement, and which reading it is depends on what that requirement actually says.
The checker cannot choose between them, which is why all of them are warnings.

Two more are about the dependencies the parts declare, and they are read differently — the specification has no say in either:

- **a dependency the code has and the model does not declare** — the code reaches from one part into another and nobody wrote that down.
  Either `depends_on` is incomplete, or the call is the thing that is wrong: a file in the wrong part, or a part reaching where it was cut not to.
  Read the file the finding names before deciding which; the standard says where the checker gets these edges and which languages it reads on its own.
- **elements that depend on each other in a circle** — no part on it answers for itself.
  Either the cut is wrong and two parts are one, or one edge on the circle is a dependency in name only and should not be declared.
  A warning rather than an error, because nothing the checker computes is broken by a circle, and two parts that genuinely need each other are a fact about the code rather than a mistake in the model.

## Naming a part

An element is a decision, not a description of the directory tree.
Before writing one:

1. **Name what it is responsible for in one sentence.**
   If the sentence needs an "and", that is two parts or one part with a name nobody has found yet.
2. **List its files.**
   A directory in `carries` owns everything under it; use that rather than re-listing siblings.
   Carriers are not only code — a standard, a procedure, a CI template and a payload are all things a part can be made of.
3. **List the requirements it carries**, from what the specification already says realizes those files:
   `python3 tools/srs_view.py --code <path>` answers it from the other end.

   Where the layer's configuration says the requirements are derived, skip this step: the checker counts as carried what the part owns, and the list is on the map, not in the record.
   Write `requirements:` there only for an obligation the part answers for without owning its files, and say so in the rationale — the map marks the entry as written, and a reader will ask why.
   The standard says when a project chooses that mode and what it costs; the short of it is that a specification written by capability puts every requirement in two or three parts, and a list nobody can keep by hand is a list that stops being read.
4. **Declare its dependencies** where they are real.
   `depends_on` is the model a person writes; it is not derived from the links between requirements, and ADR-0023 records the measurement that settled why.
   What the code says is compared with it, and the checker reads only Python by itself: for any other language, the project lists the edges its code has in `arch/edges.json` — the standard says the shape — or the model has nothing that ever disagrees with it.

Every choice that could have gone another way goes into an ADR, in `specs/adr/`, next to the neighbouring files.
The layer records the cut; the ADR records why this cut and not the neighbouring one.

## Redrawing a part

Splitting or merging elements is the same act as writing one, with two additions:

- The number of a part that is dissolved stays dead: status `withdrawn`, or `superseded` with the successor named.
- Run the checker afterwards and read the findings again — a split that left a file behind shows up as a carrier nobody claims, and one that moved a caller away from what it calls shows up as a dependency the model does not declare, where the code's edges are read.

## What this procedure does not do

- It does not touch `specs/`.
  A requirement never names an element, and nothing here is a reason to edit one.
- It does not write the map.
  `arch/90-map.md` is generated; run the checker and commit what it wrote.
- It does not invent parts to fill the file.
  A layer whose elements were written to have elements teaches every reader that the layer is decoration.
