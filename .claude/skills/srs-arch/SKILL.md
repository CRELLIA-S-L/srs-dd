---
name: srs-arch
description: Working with the architecture layer — naming the parts a system is cut into, saying what each carries, and reading the three disagreements the checker computes between that description and the specification. Invoke when the user asks what the system is made of, wants to add or redraw a part, or when a change moved files between parts. For requirements themselves use srs and srs-new.
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

Three findings matter and they are not the same finding:

- **a carrier no element claims** — a file the specification says realizes a requirement, and no part owns it.
  Either a part's `carries` is out of date, or the file belongs to a part nobody has written down.
- **a realized requirement no element carries** — something is built and no part answers for it.
- **an element carrying no requirement** — a part that answers to nothing, which is either a part nobody needed or a requirement nobody wrote.

Say which of the readings it is before proposing an edit, naming the requirement in it as `AGENTS.md` asks the first time it appears, from `--cite`.
Two of the three findings are about a requirement, and which reading it is depends on what that requirement actually says.
The checker cannot choose between them, which is why all three are warnings.

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
4. **Declare its dependencies** where they are real.
   `depends_on` is the model a person writes; it is not derived from the links between requirements, and ADR-0023 records the measurement that settled why.

Every choice that could have gone another way goes into an ADR, in `specs/adr/`, next to the neighbouring files.
The layer records the cut; the ADR records why this cut and not the neighbouring one.

## Redrawing a part

Splitting or merging elements is the same act as writing one, with two additions:

- The number of a part that is dissolved stays dead: status `withdrawn`, or `superseded` with the successor named.
- Run the checker afterwards and read the three findings again — a split that left a file behind shows up as a carrier nobody claims.

## What this procedure does not do

- It does not touch `specs/`.
  A requirement never names an element, and nothing here is a reason to edit one.
- It does not write the map.
  `arch/90-map.md` is generated; run the checker and commit what it wrote.
- It does not invent parts to fill the file.
  A layer whose elements were written to have elements teaches every reader that the layer is decoration.
