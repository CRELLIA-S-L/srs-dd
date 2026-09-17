# ADR-0025 — What a part carries may be derived, and the derivation lives in the map rather than being written back

- **Status:** accepted
- **Date:** 2026-09-17
- **Related requirements:** FR-ARCH-240, FR-ARCH-250, FR-ARCH-060, FR-ARCH-070, FR-ARCH-080, FR-ARCH-110, FR-ARCH-170, CON-ARCH-020, INV-ARCH-010

## Context and problem statement

An element record carries three required keys, and the third — `requirements` — is written by a person: the list of obligations the part answers for.
The checker verifies it in both directions, a realized requirement no element names (`FR-ARCH-070`) and a file no element owns (`FR-ARCH-060`), and the procedure tells the author how to fill it: for each path in `carries`, ask the viewer which requirements name it, and copy the identifiers.

That works for a specification written by part, where each requirement names the files of one part.
This repository is written that way, and its ten elements carry between two and fifty-three requirements each.

The first project that installed the layer is written by capability.
One requirement — the user can rename a topic — names the view, the engine and the table together, because that is what the capability is made of.
Measured there on 2026-09-17: 560 realized requirements over ten elements, 220 of them with `code` in two or three elements, 37 carriers in all, and the longest `requirements:` list 237 identifiers long.
Assembling those lists once is a morning; keeping them is the actual problem, because every new capability lands in two or three of them, each appended by hand, or `requirement-uncarried` fires under `--strict`.
The predictable outcome is the one `arch/README.md` warns about: the rule is lowered to `report`, the warnings become noise, and the field stops meaning anything.

Everything needed to fill the field is already read.
`owner_of` decides which carrier a file belongs to, the realized requirements and their `code` fields come from the published model, and the two loops that report a file no element owns and a requirement no element carries already walk both; the join they never made — every realized requirement lands in the element owning at least one of its files — is the set the written list was supposed to equal.
The checker can say a list is incomplete and cannot complete it.

## Considered options

1. Leave the field written.
   A project at that scale keeps a tool of its own that regenerates the lists, imports the checker's rule so that there is one rule and not two, and runs it in its pre-commit hook.
2. A `--fill` flag on the checker that rewrites each record's `requirements:` line from the specification, with `--fill --check` for a gate; opted into with a configuration key.
3. A mode in the configuration under which the checker computes what each element carries from `carries` and the specification, the record's `requirements` key becomes optional, and the computed set goes into the generated map — marked apart from what the record still names.

## Decision outcome

Option 3.

**Option 1 is what the project did, and it is a rule kept outside the framework that owns it.**
The tool imports `owner_of` from the checker so that the two never disagree, which is the right instinct and the wrong place: every project at that scale writes the same tool, and the framework's own rule has a consumer it does not know about.

**Option 2 was the proposal, and it crosses a line the framework has drawn twice.**
ADR-0009 says the framework never rewrites a specification, because a tool that edits the author's documents is no longer a tool the project runs but a party to what they say, and a record in `arch/` is the author's document exactly as a requirement is.
`CON-ARCH-020` draws the same line inside the layer: records are written, the map is generated, and nothing is both.
`--fill` makes one field both written and generated, and the proposal's own open question — how a hand-written entry survives the rewrite, and whether the format needs a marker for it — is the symptom of that.

**Option 3 keeps every record the author's and puts the projection where projections already live.**
The map is generated (`CON-ARCH-020`) and compared by the gate (`FR-ARCH-170`), so a derived list is held fresh by machinery that exists, and no second command and no second copy are needed.
A written entry under the mode is a claim the derivation cannot make — *this part answers for an obligation whose files it does not own* — and it is unioned with the derived set rather than overwritten by it; the map marks which is which (`FR-ARCH-250`).
`INV-ARCH-010` holds: nothing is recorded in a requirement, and the join still lives on the element's side — in its carriers rather than in a list — so removing `arch/` still leaves the specification exactly as it was.
Every reader asking what an element carries takes the union — the emptiness rule (`FR-ARCH-080`), the ownership loop (`FR-ARCH-070`) and the map — while the rules that resolve a name (`FR-ARCH-040`, `FR-ARCH-050`) stay over what the record wrote, because a derived entry exists and is realized by construction.

**It is not what ADR-0023 rejected.**
That decision measured deriving `depends_on` from the links between requirements — twenty-five conceptual edges against the seven the imports actually had — and concluded that links between requirements do not turn into call edges.
Deriving what a part carries from what it owns infers nothing: it projects what the specification already states about its files, by the rule the checker already applies when it reports the field as wrong.
`depends_on` stays written by a person.

## Consequences

The field changes meaning for a project that opts in.
Written, `requirements` is the author's claim that a part answers for an obligation; derived, it says that the part owns the files the obligation names.
For a specification by part the two coincide and the mode adds nothing; for a specification by capability the first is not writable at that scale and the second is the only version of the field that can be kept true.
The configuration key exists so that a project says which of the two it has, and a reader of `arch/` knows which they are looking at.

Under the mode a record no longer shows what its part carries — the map does — and the standard says so, so that a reader of `00-elements.md` does not take a record naming nothing for a part that answers to nothing.

Under the mode the two directions of the same decay collapse into one.
A requirement no element carries is one none of whose files any element owns, which is exactly when `carrier-unclaimed` has fired on each of them; `FR-ARCH-240` says so in its own words, and a project that finds the second voice noise lowers `requirement-uncarried` under `FR-ARCH-090`.

The default is `written`, and a layer installed before this version reads exactly as it did.
