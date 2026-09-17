---
name: srs
description: Working with the project specification (SRS in specs/). Invoke ALWAYS before any code change that alters behavior; when planning any task — including planning a feature, breaking a task into steps, or sequencing work across several requirements; when asked what the system should do; when investigating why something is built the way it is; when changing or cancelling a requirement. For a guided dialog that authors a brand-new requirement, prefer the srs-new skill. Not needed only for changes that do not touch behavior — typos, formatting, comments.
---

# Working with the specification

The project is driven by its specification.
System behavior is described in `specs/` as numbered requirements with links between them and references to code.

**The markup rules live in `specs/README.md`.** They are deliberately not restated here: two descriptions of the same rules would eventually diverge.
Read `specs/README.md` if you have not read it in this session.

The specification language follows the lexicon in `specs/srs-config.json` — statements, titles, and rationales are written in that language, whatever language this skill is written in.

## Two questions, and they enter from opposite ends

**How does this work, and what is it for?** Start with what the project wrote about itself in its own words — the terms, the purpose and the overview, which the standard's map places in `specs/00-glossary.md`, `specs/01-introduction.md` and `specs/02-overview.md`.
They are short, they are in the vocabulary the project actually uses, and they cost nothing to read: a lookup by number needs a number nobody has handed you yet, and a search over requirement text finds the word you guessed, which is the wrong word when the project calls the thing something else.
Then the areas the project declared, then one of them, then the requirement, then its code:

```
python3 tools/srs_view.py --areas
python3 tools/srs_view.py --list --area <AREA>
python3 tools/srs_view.py <ID>
python3 tools/srs_view.py --code <path/to/file>
```

Where the answer turns out to be that the specification does not say, name the rungs you actually walked — the area you asked for, the words you searched, the path you gave.
That claim is worth exactly what the query behind it was worth, and naming the query is what lets anyone who knows the project's word for the thing say so.

Where the question turns out to be undecided rather than merely unanswered, `specs/91-open-issues.md` is where that is recorded, together with the decision it waits on — and it is read whole.
An entry taken by the line will hand you a sentence the paragraph below it corrects.

**Am I about to change something?** That is the rest of this procedure, starting here.

## First things first

Before changing code, find out which requirements describe the affected behavior:

```
python3 tools/srs_view.py --code <path/to/file>
```

It answers from the `code` and `tests` fields and from the file's own `implements:`/`verifies:` annotations; a directory works too.
Where that tool is absent, `grep -rn "<path/to/file>" specs/*.md` and the “Requirement → code → verification” table in `specs/90-traceability.md` give the same answer by hand.
That table is not the only reason to know the file.
Its *Incoming links* section is every link between requirements in one place, computed and stored nowhere else — which is what to read when the question is about the shape of the graph rather than about one file, and is the wrong thing to read when it is about one file.

**Then let that answer decide what you read.** The `code` and `tests` fields of the requirements a change belongs to are the files to open; a search over the repository is the fallback, taken out loud, when they turn out not to be all of them.
The rule itself is in `AGENTS.md`.

**Report the lookup, not only its outcome** — the paths you gave, and the words, where you fell back to a search over them.
Where the answer is nothing, a lookup that missed and a lookup nobody made produce the same sentence, and the reader who could tell them apart is the one holding the report.
Where it is something, the paths are what tell that reader how wide the answer was.

Found some — read them in full, together with their `derives_from` and `depends_on`; `python3 tools/srs_view.py <ID>` prints one requirement with every link resolved in both directions.
When changing a requirement, the incoming links are the blast radius.

Found nothing — that is not permission to write code silently.
It means the behavior is not described, and a requirement must be created first.

**Where the project carries a grounds register** — a `grounds/` directory beside `specs/` — ask what the requirement is standing on before changing it:

```
python3 tools/srs_grounds.py --blast <path/to/file>
```

It names the bets on the requirements those files belong to — the ones written there, and the ones naming the file in their `code` or `tests` fields — and the state of the hypotheses under them.
A requirement standing on something `refuted` or `expired` is not a reason to stop; it is a reason to say so, because whatever you are about to build on it inherits the same ground.
Where the project has no register the command is not there, and this step does not apply.
The procedure for the register itself is `srs-bet`.

**Where the project carries an architecture layer** — an `arch/` directory beside `specs/` — ask what carries the file before changing it:

```
grep -n <path/to/file> arch/90-map.md      # or the directory above it
```

A directory in an element's `carries` owns everything under it, so a file inside one is found by that directory rather than by its own name — `.claude/skills` answers for every skill in it.
The row names the element the file belongs to, what else that element carries and which requirements it holds.
Read it for the same reason the register is read: a boundary is invisible from inside the file, and the change worth noticing is the one that moves a responsibility from one part to another.
A change that makes a part carry something its statement does not describe is a change to the layer as well, and that is said rather than left for the checker to find.
Where the project has no layer the directory is not there, and this step does not apply.
The procedure for the layer itself is `srs-arch`.

## Two acts, and they are not the same one

Writing a requirement and building it are separate acts.
Authoring ends at the written requirement and at whatever architecture decision the discussion settled; building it is a task started deliberately, later, and often by somebody else.
Sliding from one into the other is how a specification ends up recording only what already shipped — `deferred` never happens, and a baseline has nothing to freeze but the past.

This procedure is the second act.
For the first, use `srs-new`.

## Building a requirement

There are two ways in, and they meet at step 2.

**From a file you are about to change.** Find what describes it — see *First things first* above.
Nothing found is not permission to write code:
it means the behavior is not described, and authoring comes first.

**From an approved requirement nobody has built yet.** `deferred` is the status that says so:

```
python3 tools/srs_view.py --coverage
grep -n "status: deferred" specs/*.md
```

Read it in full with its `derives_from` and `depends_on`, and read what links back to it — `python3 tools/srs_view.py <ID>` resolves both directions.
Incoming links are the blast radius.

Then:

1. **Check the requirement still says what you are about to build.**
   If it does not, you are authoring, not building — stop and go to `srs-new`.
2. **Plans reference requirements.**
   The work plan names them rather than describing the work — not "fix the storage layer" — and names each one as `AGENTS.md` asks the first time it appears, from `python3 tools/srs_view.py --cite <ID>…`; a plan step is read by a person like anything else.
   The plan must not conflict with `specs/constitution.md`; its articles (`ART-*`) are named by number and nothing else — they are not requirements, the viewer does not carry them, and the constitution is one short file the reader already has.
3. **Code.**
4. **Close the loop.**
   Re-read the statement of every requirement this change names: does it describe what you actually built?
   Whatever it does not describe is written down or taken out — not left as a surprise for the next reader.
   A statement you reword here goes through the same judgement `srs-new` gives a new one, against the qualities `specs/README.md` requires of a statement, and what you find is said before the edit is recorded.
   This is the easiest place to skip it: the requirement already exists, so nothing feels like authoring, and a sentence quietly grows a second capability while somebody is repairing the first.

   A reworded statement also goes through the same lookup a new one does — what else already speaks to this behaviour, and what points at it — and what that turns up is said, not merely consulted.
   A rewording reaches everything that was standing on the old wording, and the incoming links are where that shows.

   Then status per Lifecycle, and `code` and `tests` filled with real paths — **and every file you named there says so back**, with `implements:` or `verifies:` (see Annotations in `specs/README.md`).
   The checker reports a file a requirement names that does not name it back, so this is not bookkeeping you can put off:
   the field is the specification's claim, the annotation is the file's own, and only the second notices when a file is gutted or repurposed and stops deserving the entry still pointing at it.
5. **Check:** `python3 tools/srs_check.py`.

Changing behavior — change the requirement in the same set of edits as the code.
They diverge exactly when one moves without the other.

A change that begins as a fix is where this goes wrong most often: repairing an existing requirement needs no new one, and that exemption quietly covers whatever else gets added while you are in there.
If step 4 finds the statement silent about something you built, the statement is what is wrong.
And a change that names no requirement at all is its own signal — either nothing about the system's behavior moved, or the requirement is missing.

## Withdrawing a requirement

`withdrawn` is for one cancelled with nothing to replace it.
Where something does replace it, that is `superseded` and the successor is named — this section is not about that case.

Withdrawal is the one edit that breaks requirements it never touches, so before the status changes:

1. **Read what points at it.**
   `python3 tools/srs_view.py <ID>` resolves incoming links in both directions; the matrix answers the same by hand.
   Show them grouped by field, because the four break differently:

   | Field | What the dependant loses |
   |---|---|
   | `depends_on` | its meaning — it was declared meaningless without this |
   | `derives_from` | its reason for existing |
   | `refines` | the general rule it was sharpening |
   | `conflicts_with` | nothing; the divergence is merely beside the point |

2. **Show one level, count the rest.**
   The requirements pointing straight at this one, in full; whatever lies beyond them as a number.
   Every resolution below acts on the direct dependants, and any of them may itself become a withdrawal with its own tree — so the closure is settled one level per decision, not all at once (ADR-0013).

3. **Settle each dependant with the maintainer.**
   None of these is a default, and `conflicts_with` needs no decision at all:

   - **Do not withdraw** — the honest answer when the tree is large and nobody has time to dismantle it.
   - **Narrow instead** — reword the requirement to cover only what is still wanted.
     Nothing is cancelled and the dependants keep their ground.
   - **Supersede instead** — the need survives and the shape changed.
     Dependants re-point at the successor.
   - **Cascade** — withdraw the dependants too, where the branch died with its root.
     Each one comes back through this section.
   - **Re-parent** — point the dependants at another requirement carrying the same ground.
     Cheapest where the withdrawn one was a middleman.
   - **Promote** — drop the link and let the dependant stand alone, rewording it where it leaned on its parent's words.
     Usually the `refines` answer.
   - **Orphan deliberately** — the dependant outlives its target because the link recorded provenance, not necessity.
     Allowed, and to be said rather than left silent.
   - **Stage it** — for a large tree the withdrawal is a migration: record the intent, resolve the dependants, withdraw last.
     A cascade abandoned halfway is worse than one never started.

4. **Then set the status**, and say why in the rationale — a withdrawal names no successor, so the rationale is the only place the reason can live.
   The number stays dead forever either way — identifiers are never reused, whatever the status.

Anything still standing on it afterwards is reported by the checker, which is the guard on a specification edited without this procedure — not a substitute for it.

## Planning multi-requirement work

For a task that spans several requirements, build the plan from the specification, not from the code:

1. Resolve the requirements in scope (grep, the matrix), then expand the closure: read everything they list in `depends_on`, `derives_from`, and `refines`, and check “Incoming links” for the blast radius.
2. Behavior in scope with no covering requirement — the plan's first steps author the missing requirements (see `srs-new`); no step may change behavior silently.
3. Order the steps so a requirement is implemented only after everything in its `depends_on`.
   Every step cites its requirements — named as `AGENTS.md` asks at the first mention, which `--cite` prints — and the constitution articles that constrain it (“per ART-040”), and notes the requirement's verification method.
4. A `draft` in scope is a blocker, marked so in the plan — code against it waits for approval (ART-020).
   A `superseded` or `withdrawn` requirement in scope is an error; surface it instead of planning around it.
   For a `superseded` one the successor is where the plan goes instead; a `withdrawn` one has none, and a step that still needs it is a step whose ground was cancelled.
5. Every plan ends with the same two steps: close the loop (status, `code`, `tests` in the same edit set) and run the checker.
   Steps that run builds or tests are marked “requires the user's explicit confirmation each time” (ART-030).

The plan lives in the conversation.
Do not write it into `specs/` or anywhere else — the specification records what the system does, not the work queue; and a plan is not approval: statuses are (ART-020).

## Prohibitions

The list lives in the What-not-to-do section of `specs/README.md` — it is deliberately not restated here.
On top of it, for agents: **do not run builds or tests without the user's explicit confirmation** (ART-030 of the constitution).

## Architecture decisions

Choosing a storage engine, rejecting an approach, working around a platform limitation — that is not a requirement but a decision.
It belongs in `specs/adr/`, following the neighboring files.
A requirement answers “what”;
a decision answers “why this path and not the neighboring one”.

## Discrepancies

Found a mismatch between code and a requirement — do not silently fix either side.
Record it in `specs/91-open-issues.md` and tell the user: it is unknown whether the bug is in the code or in the description, and that is theirs to decide.

**First establish that it is one.** Before anything is reported, finish the sentence *therefore*: therefore this must be fixed; therefore it is deliberate, and here is why; therefore nobody can tell without a decision that is the maintainer's.
Any of the three is a finding and is reported with that half included.
An observation with no *therefore* is not a finding — work it out or drop it, but do not hand it over.

The reason is not tidiness.
Reported raw, an observation arrives as homework: read this, decide whether it means anything.
A report mixing those with real findings teaches the reader to skim both, and the next real one goes past unread.
Whoever noticed has the context to settle it; the reader does not.

"Nobody can tell" is the third answer and stays available — it means you looked and the question is a decision, not that you did not look.
Report it with the options, not as a shrug.
