---
name: srs-audit
description: Semantic drift audit between the specification and the code, including test adequacy — whether the listed tests actually prove the statements — and the links between requirements, which nothing else looks for. Invoke when the user asks to audit the spec, verify that code matches requirements, find undocumented behavior, check whether requirements are adequately tested, or derive test cases from statements. Read-only analysis with a report; fixes nothing by itself, except that on explicit request it can author the missing tests. For the everyday workflow use the srs skill.
---

# Auditing the specification

The checker (`tools/srs_check.py`) already catches everything mechanical:
broken links, missing paths, stale annotations by ID.
This audit covers what the checker cannot judge — whether the code actually does what the statements say, and whether the listed tests would prove them.
Do not re-report what the checker reports.

## Procedure

1. Run `python3 tools/srs_check.py --no-write` to start from a known mechanical state; note any warnings.
   `python3 tools/srs_view.py --coverage` then names the areas worth looking at first: realized requirements with no listed tests, drafts that already have code, realized requirements resting on a draft, and code files no requirement references.
2. For every `implemented` and `partial` requirement: read the files in its `code` and `tests` fields and judge whether the behavior matches the statement — the whole statement, including its condition and constraint, not just the action.
3. Go through “Code files outside the specification” in `specs/90-traceability.md`: for each orphan file, determine whether it carries behavior that deserves a requirement.
4. Then ask the same question from the other end, which nothing reports:
   **does the statement reach further than the `code` field names?** A statement saying “every tool”, “the skills”, “each command” claims a set;
   list what is actually in that set and compare.
   The checker cannot: it proves the paths exist, never that they are all of them.

   This is the half that stays invisible, because an incomplete field is green forever — the matrix records what is written, so nothing is stale and nothing fails.
   What it costs shows up in the everyday loop: a rule binding every tool, listed against half of them, is a rule that `--code <the other half>` never mentions — and the first thing anyone does before changing a file is ask what governs it.
5. Compare `tests` entries against what the tests actually assert: a test that exists but checks something else is drift too.
6. Report findings grouped by requirement, each with three parts: what the spec says, what the code does, where exactly they diverge (`file:line`).
   Distinguish “code is wrong”, “spec is outdated”, and “cannot tell” — do not guess which.
   Name each requirement with its title and location the first time it appears, as `AGENTS.md` asks:
   a report grouped by bare identifiers is one the reader resolves line by line.

   **Each of those three is a consequence, and one of them has to fit.** An audit surfaces far more than it finds: a count that reads as stale, a file in an odd place, a flag no statement names.
    Before any of it is written down, finish the sentence *therefore* — and where nothing follows, the answer is that nothing follows, so drop it rather than passing it on. “Cannot tell” is not that answer: it means the question is a decision the maintainer owns, and it is reported with the options.

   The cost of an unresolved observation is paid by the reader, who has less context than you did.
   A report that mixes them with findings gets skimmed, and the finding that mattered goes past unread.

## Test adequacy

Beyond drift, judge whether the listed tests would prove the statements.
Only requirements with `verification: T` get derived test cases; for `D`, `I`, and `A`, check that the evidence `specs/50-verification.md` expects is recorded, and report (ART-050).

1. Decompose the statement along its EARS parts: trigger (“When…”), state (“While…”), condition, the obligation itself, and any constraint.
   Each part is a test dimension — the trigger fires or does not, the state holds or does not, the boundary of the constraint.

   **Where conditions combine, stop decomposing and build a decision table.** List the causes — each condition that can be true or false — and the effects, then write the rows: one per combination that can actually occur, with the constraints between causes used to strike out the ones that cannot.
    The rows are the cases.
    This is the step that turns “did I think of everything” into arithmetic, and it is where judgement misses hardest: a rule firing on `--force` **and** a marker has four rows, and a suite that has one fixture reads as covered from every angle except this one.

   The table is a working instrument, not a finding.
   Build it, take the rows, compare them against the tests — and put only the gaps in the report.
   An audit that prints twenty-five tables is an audit nobody reads to the end, which costs more than the tables are worth.

   Build one only where conditions genuinely combine.
   Most statements are unconditional — “the viewer **shall** render…” — and a table for one of those is a row of ceremony.
2. A quantified constraint implies property-style cases: “within 2 seconds” — at the boundary and beyond; “all unsaved changes” — none, one, many.
3. Map the derived cases against what the `tests` files actually assert.
   Classify each: covered, partial, uncovered — or asserted by a test yet not derivable from the statement, which means the statement is under-specified: report it, do not edit it.

   **Covered means the test could fail.** For each case you would call covered, name the change to the code that would make that test red.
    If you cannot name one, the case is uncovered however much the test mentions its subject.
    Reading tells you what a test refers to; only this tells you what it would catch, and the two part company in the two shapes that look most convincing: a statement carrying two obligations with a suite that exercises one of them, and a rule that fires on several fields with a fixture for one.
    Both have a filled `tests` field and a suite that stays green when the behaviour is deleted.

   Name the edit; do not make it.
   The audit runs nothing (ART-030), and the question is answerable while reading.
4. On the user's explicit request — and only then — author the missing tests; the new test path goes into `tests` in the same set of edits (ART-050).
   Running them still needs its own confirmation (ART-030).

## Links between requirements

The third dimension, and the one nothing else looks at.
The checker proves that every link written down resolves; it cannot prove that any link was left out, and an empty link field is valid on every requirement in the file.
Its one rule here fires only on total isolation — nothing pointing out, nothing pointing in — so a single link satisfies it, and the graph settles on that floor.
What rests on the links is every question of the form *what does this change reach*, so a radius computed from them is worth what they are worth.

**One area at a time.**

```
python3 tools/srs_view.py --areas
python3 tools/srs_view.py --list --area <AREA>
```

1. Read the area's titles together — that is the unit small enough to hold in one reading, and a link is only ever proposed between requirements that were read together.
2. For each requirement in it, open what looks related and judge which links are missing, in both directions:
   `depends_on` where one is meaningless without the other, `derives_from` where one exists because the other does, `refines` where one is the same obligation narrowed for a branch, `conflicts_with` where the divergence is deliberate.
   The four are not interchangeable — the standard says what each means, and a link filed under the wrong field misdescribes the radius as surely as a missing one.
3. Look outside the area as well. The area is where reading starts, not where the graph ends, and a link crossing two areas is the one nobody was looking at when either end was written — an author works inside an area, and reads that area.
4. **Propose, one link at a time, and let the maintainer settle each.**
   Name both ends as `AGENTS.md` asks, say which field and why in a clause, and wait.
   A batch of twenty approved in one breath is twenty links nobody read.
5. Stop at the proposal. What the maintainer approves is written the way any other specification edit is — through the everyday procedure, with the matrix regenerated in the same set of edits — and that is not this audit's act; see *Boundaries*.

Say what the pass covered — which area, how many requirements, how many links proposed and how many approved — because the next pass starts where this one stopped and nothing else records that.

**What it does not establish.** A missing link is invisible by construction, so the pass cannot end with "none remain".
It ends with an area that has been read once, by somebody, which is a different and smaller claim.
Say it that way rather than reporting the area clean.

In a project part-way through describing itself the pass has a second effect worth expecting: linking a realized requirement to a `draft` one is what makes the checker report it, and that is the rule doing its job, not the pass going wrong.

## Boundaries

- Do not flip statuses, edit requirements, or change code during the audit — which side is wrong is the maintainer's call (ART-010 of the constitution).
- Write findings into `specs/91-open-issues.md` only with the user's explicit confirmation.
- Do not run builds or tests (ART-030).
  The audit itself is read-only;
  authoring missing tests (Test adequacy, step 4) is the one exception, and only on explicit request.
