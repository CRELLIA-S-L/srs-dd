# The architecture layer

<!-- SRS-DD-VERSION — installed by the framework; --force overwrites local edits -->

A specification records what the system must do.
It does not record what the system is made of: which parts exist, what each one is responsible for, which files are that part, and which parts lean on which.
That description usually lives in a diagram nobody regenerates and in a paragraph of prose no rule reads — delete either and every gate stays green.

This layer is where it goes instead.
Each part is a record with an identifier, a statement of what it is responsible for, the requirements it carries and the files it is made of.
From those the checker computes three disagreements that are otherwise invisible: a file the specification claims and no part owns, a requirement that is built and belongs to no part, and a part that answers to nothing.

The layer is optional.
It is a sibling of `specs/`, never a part of it, and nothing here is ever written into a requirement file.

## When not to have this

Do not install the layer where the parts are obvious and few — a single script, a library with one public module, a service whose whole structure fits in the README's first paragraph.
There the description would be a second copy of the file tree, and a description that adds nothing teaches every reader that this directory is decoration.

The question worth asking is not "could we list our parts" but "is there a boundary somebody could cross without noticing".
Where the answer is no, decline the layer and lose nothing.

## The join, and which way it points

An element names the requirements it carries.
A requirement never names an element.
The other direction is computed, and it is computed rather than stored for the reason the same rule exists in the grounds register: a link written on both ends eventually disagrees with itself, and only one of the two copies is ever updated.
Where the project derives the requirements instead (see *Derived requirements*), the direction does not change: the join still lives on the element's side, in its `carries` rather than in a list, and the requirement still names no element.

It is also what keeps the layer optional.
Nothing in `specs/` mentions this directory, so removing `arch/` removes the layer and leaves the specification exactly as it was.

## Identifier

`E-<NNN>`, numbered in steps of 10 so there is room to insert a neighbour.

An identifier is immutable and never reused.
A part that is dissolved gets status `withdrawn`, or `superseded` with its successor named; the number stays dead either way, because a reference from an old review has to keep leading to the same place.

## The record

Every record in this layer is written the same way:

````markdown
### E-010 — The document store

```yaml
status: built
carries: [src/store, src/store_index.py]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
interface: a query API and a write path, both over the same index
```

Holds every document, indexes it and answers a query about it.

**Rationale.** Split from the editor because the two are used at different moments and by different people: one is written to, the other is read from under load.
````

A level-three heading with the identifier and a title; a fenced `yaml` block of flat keys whose values are scalars or bracketed lists; a statement of what the part is responsible for; and, optionally, a rationale.

The shape deliberately resembles a requirement and a grounds record, so that whoever has read one standard can read this one.
It is not the same format.
None of the three is obliged to follow another's edge cases, and a later reader who merges them would be inventing a coupling all three were designed to avoid.

**Keys are added, never renamed.**
A key that is neither required nor optional here is not an error — that tolerance is what lets a later version add one without breaking a layer written against an earlier version.

| Key | | |
|---|---|---|
| `status` | required | `proposed`, `built`, `superseded`, `withdrawn` |
| `carries` | required | the files and directories that are this part |
| `requirements` | required, unless derived | the requirements this part realizes — see *Derived requirements* |
| `depends_on` | optional | other elements this part leans on — the declared model |
| `interface` | optional | how the part is reached from outside |
| `superseded_by` | by status | the successor, where the status is `superseded` |

`carries` is not limited to source files.
A requirement's `code` field names whatever realizes it — a standard, a procedure, a CI template, a template shipped to somebody else — and the part that owns those files is a part like any other.

`depends_on` is the declared model, and it is written by a person.
It is not derived from the links between requirements: those record one obligation resting on another, which is not the same relation as one part calling another, and deriving it was measured and rejected (ADR-0023).

## Derived requirements

A specification written by capability names the view, the engine and the table in one requirement, so a requirement lands in two or three parts and every part's list grows with every capability.
Past a few hundred requirements those lists cannot be kept by hand, and a list nobody can keep is lowered to `report` and stops meaning anything.

A project at that scale says so in the configuration:

```json
{"requirements": "derived"}
```

Under `derived` the checker counts as carried by an element every `implemented` or `partial` requirement whose `code` field names a file the element owns — by the same rule that decides which carrier a file belongs to — together with any the record still names.
The `requirements` key becomes optional.
A record that keeps it is making a claim the derivation cannot: that this part answers for an obligation whose files it does not own.

**What the record shows changes.**
Under `derived` a record naming no requirement is not a part that answers to nothing; what the part carries is in the map, which marks what the record names apart from what was computed.
Read the map, not the record, to learn what a part carries.

Nothing is written back.
The records stay the author's, the map is where the projection lives, and the gate that compares the map now holds it fresh against the specification's `code` fields as well as against the records.
The default is `written`: every entry is the author's claim, and a layer written before this key existed reads exactly as it did.
This is not the derivation ADR-0023 rejected — `depends_on` is still written by a person — and ADR-0025 says why the projection lives in the map rather than in the record.

## The map

`arch/90-map.md` is generated from the records and never edited by hand.
It states, for every element, what it carries, which requirements it holds and what state it is in; where the requirements are derived, it marks which of them the record names and which were computed.
A committed map that no longer matches what the records produce is a change somebody made without looking at the parts, which is why the map is compared rather than trusted.

## Checking

```
python3 tools/srs_arch.py              read the layer, report, regenerate the map
python3 tools/srs_arch.py --no-write   report only
python3 tools/srs_arch.py --strict     treat warnings as errors
```

Errors are the readings that make the rest meaningless: a repeated identifier, a missing required key, a requirement that does not exist.
Everything else is a warning, because the honest resolution differs case by case and the checker cannot choose it.

What a rule costs is the project's to set, in `arch/arch-config.json`, beside the `requirements` key described above:

```json
{"rules": {"carrier-unclaimed": "report"}}
```

`warn` is the default and what `--strict` fails on, `report` is said and fails nothing, `off` is not said at all.
A rule name the checker has published keeps its meaning: names are never renamed and never given to a different rule, because this file is written against them.

## What not to do

- Do not write a requirement identifier into a requirement file to point back at an element.
  The join lives here, in one direction.
- Do not edit `90-map.md`.
  It is generated; the next run overwrites it.
- Do not describe a part that does not exist yet.
  An element is a record of how the system is cut today, and a plan for cutting it differently is an ADR.
- Do not cut the parts as finely as the file tree.
  If every module is an element, the layer says nothing the directory listing did not.
