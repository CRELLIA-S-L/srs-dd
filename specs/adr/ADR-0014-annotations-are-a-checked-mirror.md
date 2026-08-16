# ADR-0014 — An annotation is a checked mirror, not a second copy of a link

- **Status:** accepted
- **Date:** 2026-08-14
- **Related requirements:** INV-SPEC-020, FR-CHK-080, FR-CHK-055, FR-CHK-140

## Context and problem statement

Traceability between a requirement and the code that realizes it runs in two
directions. Forward, the `code` and `tests` fields name paths. Backward, a
source file may carry `implements:` or `verifies:` naming requirements. The
checker validates the forward direction — the path exists (FR-CHK-055), a
requirement verified by test lists one (FR-CHK-140) — and half of the
backward one: an annotation naming an unknown requirement is an error, and a
file claiming a requirement that does not list it back is a warning
(FR-CHK-080).

What is not checked is the other half: that a file a requirement names says
so. FR-CHK-080 forbids it in as many words — it cross-checks the annotations
it finds, "never reporting a file that carries none" — on the grounds that
annotations are an optional second opinion and mandatory ones would turn
every source file into specification surface.

Behind that sits an invariant. INV-SPEC-020 has the specification record
only forward links and leave every reverse relation to be computed, because
"a link written at both ends is a link that will one day disagree with
itself, and nothing would say which end was right."

So the question is not whether the missing check is useful. It is whether a
back-reference is a second copy of a link, which the invariant forbids, or
something else.

The measured state of this repository, which the answer has to survive: 127
requirement-to-code pairs, 77 requirement-to-test pairs, and zero
annotations. `tools/srs_check.py` is named by 28 requirements,
`tools/srs_view.py` by 24, `tests/checker-rules.sh` by 19.

## Considered options

1. Leave annotations optional; add only a list of files no requirement names,
   symmetric to "Code files outside the specification" in the matrix.
2. Require an annotation on every file under the configured roots.
3. Require an annotation on every file a requirement names; report files
   nothing names separately; let a project silence the second half while it
   is adopting the framework.
4. Drop annotations and compute the backward direction from the forward
   fields alone.

## Decision outcome

Option 3, and INV-SPEC-020 is narrowed to say what it always meant.

**The two ends are not two copies of one fact.** Option 4 is where this
becomes clear, and it is the option that looks cheapest until it is
examined: inverting the `code` fields does yield, for any file, the
requirements that name it — the matrix already does exactly this for links
between requirements, under "Incoming links". But inversion answers only
which requirements *claim* the file. It cannot answer whether the file
agrees. Those are different assertions made by different people at different
times: the `code` field is the specification's claim that a requirement is
realized here, and the annotation is the claim, made at the code by whoever
is editing it, that this code exists to satisfy that requirement. A file
gutted, split or repurposed keeps its entry in the requirement's `code`
field and stops deserving it, and the only person positioned to notice is
the one in the file.

That is what disarms INV-SPEC-020's fear. The invariant guards against a
relation stored twice and drifting silently, with no way to say which copy
is right. Here neither condition holds: the disagreement is machine-checked
on every run, so it cannot be silent, and the source of truth is settled —
the requirement's field is the record, the annotation is a mirror, and a
mismatch is reported against the mirror. The invariant keeps its full force
where it was aimed, at links between requirements, where the reverse
relation genuinely is computed and storing it would create a second record
of the same fact.

**Option 2 is right and premature.** Every file under the roots carrying its
own account of why it exists is the state worth reaching, and a project that
starts there should start there. But a project adopting the framework has
code in the thousands of files and requirements in the dozens, and a rule
that fires on all of it on day one is not a queue, it is a wall. The
distinction that makes option 3 gentler is exactly the one that matters
during adoption: a file a requirement names is a file somebody has already
described, and asking it to say so costs one line.

Option 1 was the original proposal here and is rejected as too weak to be
worth a rule. A file no requirement names is invisible only until anyone
looks at the matrix; the check that earns its place is the one that catches
a described file drifting away from its description.

**The graduation is a default, not a mechanism.** The two halves are two
named rules, which FR-CHK-160 already makes tunable per project and per
requirement. A fresh install leaves both at their defaults; an adopting
target has the strict half written into its configuration as silenced, with
the note that turning it on is what finishing the adoption means. No new
configuration concept is introduced, and a project tightens by deleting a
line.

## Consequences

- FR-CHK-080 loses its central clause. "Never reporting a file that carries
  none" was the whole of its rationale about optional second opinions, so
  the requirement is reworded rather than extended.
- INV-SPEC-020 is narrowed to links between requirements. This is a
  reworded invariant, not a withdrawn one: everything it forbids today about
  `derives_from`, `depends_on`, `refines` and `conflicts_with` it goes on
  forbidding.
- Two rule names are added, which is compatible by ADR-0009 — adding a name
  is one-way safe, renaming one is not.
- This repository owes 204 annotation lines across 35 files before the
  paired rule can pass on its own specification. The work is mechanical and
  one-time.
- A file named by 28 requirements will carry 28 lines. That cost is also a
  reading: a file 28 requirements point at is a file doing 28 things, and
  the annotation block is the first place anyone will see it written down.
- The audit stops checking pairing by hand. It was never in the procedure,
  which is why the pairing was never checked at all.
- Two requirements remain to be authored — the paired rule and the strict
  one. They are two obligations and therefore two requirements; this
  decision binds their shape and neither is written yet.
