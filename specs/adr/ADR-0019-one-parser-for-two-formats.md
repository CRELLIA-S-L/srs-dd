# ADR-0019 — The shape is parsed once, the meaning twice

- **Status:** accepted
- **Date:** 2026-08-19
- **Related requirements:** FR-CHK-110, NFR-SPEC-010

## Context and problem statement

ADR-0015 gives the grounds register its own checker. Both checkers read the
same physical shape: a `### <identifier> — <title>` heading, a fenced block of
flat `key: value` lines under it, and prose until the next heading. The shape
was chosen for the register precisely so that a reader of `specs/README.md`
recognises it without learning a second syntax.

The code that reads that shape exists once, inside `tools/srs_check.py`. The
new checker needs the same reading, and there are three ways to get it.

## Considered options

1. Write it again in `tools/srs_grounds.py` — about thirty lines.
2. Import `srs_check` from the grounds checker.
3. Extract the shape reading into `tools/srs_parse.py` and have both use it.

## Decision outcome

Option 3.

**Option 2 couples an optional subsystem to the mandatory one's startup.**
`CFG = load_config()` runs at module level (`tools/srs_check.py:124`) and
`_config_fail` calls `sys.exit(2)`. Importing means the grounds checker
dies on the import line, with a message about a configuration it does not own,
before it can say anything about hypotheses. It fails either way when the
specification is unreadable — the register reads the requirement model through
a subprocess and that subprocess would fail too — but there is a difference
between reporting "the requirement model could not be read, here is why" and
exiting from an import.

**Option 1 is affordable and still wrong for the reason that decides this.**
The duplication is small: `parse_metadata` is 24 lines and `parse_file` is 5;
`collect_spec_files` is not needed, since the register walks its own
directory. Thirty lines is well under the threshold at which duplication
normally earns a shared module. But two copies of a reading are two places to
change when the reading changes, and the second copy is the one that gets
forgotten — the framework already carries a rule about a second definition of
the same thing, and the argument does not stop at prose.

**What makes option 3 cheap here is that the seam already exists in the
code.** `RE_HEADING` is deliberately broad, and the comment above it says why:
"a deliberately broad net: anything ID-shaped is captured (including junk like
FR-CORE-010-B) and then judged loudly by RE_ID — a malformed identifier must
never be skipped silently" (`tools/srs_check.py:185-190`). Capture and
judgement are already separated. The module takes the capture; each checker
keeps its own judgement.

So `tools/srs_parse.py` knows the shape and nothing else: how to find the
boundaries of an entry and how to split all of its fields **without knowing
their names or how many there are**. It returns the identifier as written,
the title, a mapping of the fields, the body and the line. What the fields
mean, which are required, which are retired, what an identifier must look
like — none of that is its business.

**The cost to what exists is small and was measured.** Thirty-two
requirements name `tools/srs_check.py`. Exactly one describes behaviour that
moves: FR-CHK-110, "While parsing a fenced code block, the checker **shall**
ignore headings, modal verbs and rationale markers inside it" — fence opacity
is shape, so its `code` field gains the module. The rest stay where they are,
and this was checked statement by statement rather than assumed: FR-CHK-010
is entirely judgement ("if a requirement identifier is repeated or does not
match…"), and the capture regex it is often confused with is described by no
requirement at all, being implementation. Required keys (FR-CHK-170), retired
keys (FR-CHK-180), rule severities (FR-CHK-160), identifier immutability
(INV-SPEC-010) and configuration reading (FR-CHK-100) are untouched.

## Consequences

A fifth file joins the tooling copied into every target. It is
standard-library only like the rest (NFR-SPEC-010), which names it, and so
does FR-CHK-110 — the one behaviour that moved. It needs no requirement of
its own: FR-CHK-210 reports a file under the code roots that neither a
requirement names nor an annotation claims, and this one is named at both
ends.

The extraction is a behaviour-preserving change to a file thirty-two
requirements point at, and the only honest evidence for that is external:
the whole suite passes afterwards without a single edit to the suites
themselves. That is the acceptance condition, and it is worth more than any
review of the diff.

Recorded after the fact, because it was not quite met. Every assertion in
every suite passed untouched; three `cp` lines did not. The fixtures in
`tests/checker-rules.sh` are built by copying the tooling file by file, so a
new tooling file has to be named there — an inventory, not a check. Running
them also found the one place the extraction genuinely broke something:
`--mode adopt` validates a stranger's specification with a checker it places
in the target before any tooling is installed, and that checker had no parser
beside it. Neither would have come out of reading the diff.

Mutating the moved code found something older than the move: neither edge
CommonMark draws around a closing fence — a run shorter than the opener, a
run carrying an info string — was covered by anything, and breaking both
passed all ninety-six fixtures. Two fixtures now fail on them. That gap is
not the extraction's doing and would have kept until something else went
looking.

Where the line between shape and meaning falls is settled by having two
consumers rather than by argument. The first consumer alone cannot tell which
of its habits are the format and which are its own; the second one can, and
the boundary is expected to move a little when it arrives.

It moved on the day the second consumer first ran, and outward rather than
inward: the identifier grammar left the module. The register numbers its
entries in two parts — `H-010` — and the capture written for `FR-CHK-010`
requires three, so the shared parser returned nothing at all for a well-formed
hypothesis. Broadening the one capture to cover both was the obvious repair
and was rejected on a measured cost: it also takes `### Phase-2` and `###
Windows-10`, so a heading that a stranger's `specs/` may already contain
becomes a hard error, and `--mode adopt` on that project stops installing. The
pattern is now an argument and each checker brings its own. What stayed is the
fence walk, the field split and the boundaries of a record — the bulk of the
module, and the part that turned out to have no test coverage at all.
