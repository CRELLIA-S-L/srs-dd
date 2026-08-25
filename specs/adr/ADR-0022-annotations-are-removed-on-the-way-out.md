# ADR-0022 — The annotations are removed on the way out, not given up

- **Status:** accepted
- **Date:** 2026-08-25
- **Related requirements:** CON-SPEC-020, FR-INIT-180, FR-INIT-190, FR-CHK-080

## Context and problem statement

CON-SPEC-020 says what the installer copies shall not contain requirement
identifiers of this framework or annotations naming them. The seven Python
tools it copies contain 101 such lines, and have since annotations were
introduced. The check guarding the constraint had only ever walked
`.claude/skills`, so nothing said so.

The harm is a ladder and only its top rung matters. A target whose code roots
are the default `src` never reads `tools/` and sees nothing. A target that
puts `tools` on its code roots saw 78 warnings (2026-08-24) about identifiers
in areas it does not declare — noise. A target that declares an area this
framework also uses gets our `implements: FR-CHK-110` resolving to **their**
requirement under that number: not a dangling reference, a confidently wrong
one, in a file whose whole job is to be read by a checker.

## Considered options

1. Append `srs-ignore` to every annotation line in the shipped tooling.
2. Declare `tools/` out of scope in CON-SPEC-020's statement.
3. Leave it, and say in the standard which rule a project silences.
4. Drop the annotations and record the links in a register file beside them.
5. Remove the annotations as the installer copies, keeping them here.

## Decision outcome

Option 5.

**Option 1 was the recommendation here until it was measured.** The entry in
`91-open-issues.md` said the marker "costs the framework's own two-way check
nothing". It ends it. Measured 2026-08-24 and reproduced 2026-08-25:
marking all 131 annotation lines under `tools/` — the seven that travel
and the two that do not — turns this repository's own gate red with 156
warnings, each a requirement naming a file that no longer names it back.
The two numbers count different things and neither is a typo for the
other: 131 lines carry 197 mentions, which resolve to 156 distinct
requirement-to-file links, and a link is what the gate reports. This
repository's `code_roots` are `tools`, which is why its own gate reads
them at all where a target's default `src` never would. The exemption is unconditional — it silences
the annotation here exactly as in a target, and being read here is the whole
of what those lines are for.

**Options 2 and 3 leave the top rung standing.** Both are honest about the
noise and neither touches the case the constraint is worded against. Option 3
was chosen first, on the grounds that it kept both the two-way check and
byte-identical shipped copies, and the second half of that turned out not to
describe the code: the copier already rewrote bytes on the way out,
replacing `SRS-DD-VERSION` with the version in every file carrying the
token. Shipping exactly what the repository runs
stopped being true when the marker was introduced. What remained of the
argument was the two-way check, and option 5 keeps it whole.

**Option 4 is ADR-0014's option 4 with an extra file.** Moving the links out
of the code and into a register makes them a second copy of the `code` field,
written by the same hand in the same commit. ADR-0014 settled why that is not
the same artefact: inverting the `code` fields "answers only which
requirements *claim* the file. It cannot answer whether the file agrees",
and a file gutted or repurposed keeps its entry and stops deserving it. An
annotation escapes INV-SPEC-020's ban on a link written at both ends only
because it is a different assertion by a different person in a different
place. A list beside the code is not that, and would be exactly the second
record of one fact the invariant forbids.

**Option 5 puts the removal where the transformation already happens.** It
sits beside the stamping, in `outbound()` (`tools/srs_init.py:285`), which
is the single function every path into a target goes through. What leaves
is precisely what
the checker would have read as a claim — `RE_ANNOTATION`, the checker's own
pattern, so the two can never disagree about what an annotation is — and a
line carrying `srs-ignore` is left alone, because that is how the standard
marks an example and the two examples in the checker's comments are where a
target reads the annotation format at all.

The line survives the removal, replaced rather than deleted. A traceback from
a target names the line it happened on, a bug report is read against the
source here, and deleting 101 lines would shift every number after them by an
amount nobody can see.

## Consequences

Measured on a fresh target with `tools` added to its code roots: 78 warnings
before, 7 after, and the 7 are of a different kind — `no requirement names
this file and it claims none`, which is FR-CHK-210 correctly reporting files
the project put on its own code roots and never described. Nothing of this
framework resolves in a stranger's specification any more, at any rung.

The leak check in `tests/installer-smoke.sh` stops excluding `tools/`. It was
excluded for the duration of the problem, which is the shape a check takes
when it is written around what it cannot yet pass.

There are two paths into a target, not one, and the second is why the
transformation is a function rather than a few lines in the copier. Adopt
writes the checker itself — it has to run it against a stranger's
specification before any tooling is installed, and the file it ran becomes
the target's checker (`tools/srs_init.py:1230`). Written first as a
substitution inside the copier, this decision shipped 26 annotations and an
unreplaced version token on that path; `tests/adopt-smoke.sh` now asserts
against it, and the assertion was checked by removing the fix and watching
it go red.

A target's copy of a tool is no longer byte-identical to ours, and a bug
report quoting one will differ from the source by the content of those
comments. Line numbers are not among the differences, which is what the
choice to replace rather than delete buys.

FR-INIT-190 arrives with this: each copied tool carries the version it came
from, one stamp per file in the marker's existing shape. It answers the
question a hand-copied or half-upgraded tree cannot otherwise answer. One per
file rather than one per removed annotation, because the same number a
hundred times in one file is not more information than the same number once.

Copying by hand — which `docs/install.md` documents — has no installer and
therefore no removal. That is said there rather than fixed: the annotations
are inert unless a project puts `tools/` on its code roots, and a project
that does has been told what to do about it.

AGENTS.md carried the opposite rule, forbidding annotations in two of the
seven files and predicting a failure that does not happen in a default
target. It is rewritten to say what is now true: annotate the tooling like
anything else, and never reach for `srs-ignore` to quiet it.
