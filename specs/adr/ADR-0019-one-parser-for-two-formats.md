# ADR-0019 — The shape is parsed once, the meaning twice

- **Status:** accepted
- **Date:** 2026-08-19
- **Related requirements:** FR-CHK-110, NFR-SPEC-010

## Context and problem statement

ADR-0015 gives the belief register its own checker. Both checkers read the
same physical shape: a `### <identifier> — <title>` heading, a fenced block of
flat `key: value` lines under it, and prose until the next heading. The shape
was chosen for the register precisely so that a reader of `specs/README.md`
recognises it without learning a second syntax.

The code that reads that shape exists once, inside `tools/srs_check.py`. The
new checker needs the same reading, and there are three ways to get it.

## Considered options

1. Write it again in `tools/srs_beliefs.py` — about thirty lines.
2. Import `srs_check` from the belief checker.
3. Extract the shape reading into `tools/srs_parse.py` and have both use it.

## Decision outcome

Option 3.

**Option 2 couples an optional subsystem to the mandatory one's startup.**
`CFG = load_config()` runs at module level (`tools/srs_check.py:124`) and
`_config_fail` calls `sys.exit(2)`. Importing means the belief checker dies on
the import line, with a message about a configuration it does not own, before
it can say anything about beliefs. It fails either way when the specification
is unreadable — the register reads the requirement model through a subprocess
and that subprocess would fail too — but there is a difference between
reporting "the requirement model could not be read, here is why" and exiting
from an import.

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

A fifth Python file ships with the framework. It is standard-library only
like the rest (NFR-SPEC-010), it has its own requirement because otherwise a
file under the code roots that no requirement names fails the strict gate,
and it carries the annotation back.

The extraction is a behaviour-preserving change to a file thirty-two
requirements point at, and the only honest evidence for that is external:
the whole suite passes afterwards without a single edit to the suites
themselves. That is the acceptance condition, and it is worth more than any
review of the diff.

Where the line between shape and meaning falls is settled by having two
consumers rather than by argument. The first consumer alone cannot tell which
of its habits are the format and which are its own; the second one can, and
the boundary is expected to move a little when it arrives.
