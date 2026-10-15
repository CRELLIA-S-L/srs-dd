# ADR-0045 — What the published architecture skills contribute, and what they do not

- **Status:** accepted
- **Date:** 2026-10-05
- **Related requirements:** FR-ARCH-410, FR-ARCH-420, FR-ARCH-430, FR-ARCH-440, FR-ARCH-450, FR-SKILL-480, FR-SKILL-490, FR-SKILL-500

## Context and problem statement

This layer was designed from the literature — reflexion models for its shape (`ADR-0023`), architectural drivers for what a cut is designed against (`FR-ARCH-210`) — and not from what other people have built for agents.
By late 2026 there is a public ecosystem of architecture work for coding agents, and the question is which of it belongs here.
Four projects were read in full on 2026-10-05, not summarised from a search result.

**`claude-architecture-skills`** (keez97) ships seven skills. `architecture-workflow` runs four phases — discover, diagnose, a checkpoint a person approves, fix with TDD, document — writing a file per phase. `software-architecture` has a review mode (a health score over coupling, cohesion, abstraction, testability and pattern consistency; a findings table with severity, impact, effort and what each finding unlocks) and a design mode (requirements restated, decisions recorded, components with data ownership and failure modes). `describe-design` reverse-engineers a codebase in eight steps into eight artefacts — system overview, C4 context, container, sequence, ER, component deep-dives, data-flow and onboarding guides — under the rule that every claim cites a file path. The fix phase carries a file-split protocol: complete units rather than line ranges, write then verify then delete, a handful of files per round, each standing on its own. The set is measured against an unskilled baseline over the same scenarios, 15–18 binary assertions per run.

**`arch-fitness-functions`** (yonatankarp) is the Ford, Parsons and Kua taxonomy as a procedure: atomic against holistic, triggered against continual, static against dynamic, with ArchUnit, ts-arch and dependency-cruiser named, and one rule above the rest — a fitness function fails the build, because a warning ignored is not one.

**`unkode`** has an agent write `.unkode/arch.yaml` once, and everything downstream is deterministic: validation against the file tree, a Mermaid map, and a colour-coded architecture diff posted on every pull request.

**`code-map`** emits one Markdown file in eight fixed sections — business summary, architecture flowchart, key flows, data model, module guide, entry points, risks, sources — with "Not determined" written where it could not tell.

## Considered options

1. Install one of them beside the layer and use both.
2. Replace the layer's design side with `software-architecture` and keep our checker for the gate.
3. Take the parts that fit, adapt each to what we already hold, and record what was refused.
4. Take nothing: the layer was designed from the literature already.

## Decision outcome

Option 3, and the parts are these.

**The document a person reads** became `srs-dd/tools/srs_arch_doc.py` (`FR-ARCH-410` to `FR-ARCH-450`), printed on request and writing nothing.
`code-map`'s fixed sections and its "Not determined" discipline are the shape; `unkode`'s split between an authored model and a deterministic render is the principle, except that ours needs no agent at all because the records are already authored.
What ours has and none of theirs does is the section where the code disagrees with the model: a reflexion model is worth reading exactly there.

**The readings a part is judged against** went into the procedure's design step (`FR-SKILL-480`).
Their five dimensions transfer; their score does not — a number a model assigns per run is not reproducible, and ours end in an act: rename, split or merge.

**The move protocol** went into the procedure's move section (`FR-SKILL-490`), with the verification generalised from a compilation gate in two languages to the project's own checks, since a project here may be documents (`SRS-DD-ART-080`).

**The baseline** became `--baseline` on the procedure measurement (`FR-SKILL-500`): the same scenario asked again with the tool that loads a procedure out of reach, and the two shares reported with their difference.

**The vocabulary** settles a question this layer never answered: the rules its checker reports are static fitness functions in Ford, Parsons and Kua's sense, and they fail the gate, which is what that taxonomy asks of them. Dynamic ones — latency, memory, a business invariant in production — are out of scope here; a measured claim about the product belongs in the grounds register, which is built for exactly that.

### What was refused, and why

**A second model of the system.** C4 through Structurizr, or `unkode`'s YAML, is a description that has to be held in agreement with the records and the requirement fields, and nothing says which is right when they differ — the reason `ADR-0023` refused an external model, unchanged.

**A health score.** It is assigned by a model per run, so two runs disagree about a cut nobody touched, and a reader argues with the number instead of the cut. Our findings are rules a project can price (`FR-ARCH-090`).

**An agent-written model.** `unkode` generates the architecture and then diffs it; here the model is authored by a person and the code is what disagrees with it. An agent-written model agrees with the code by construction, which is the one thing a reflexion model must not do.

**The fix phase.** Compilation gates, git checkpoints per fix and TDD cycles are how a change is carried out, which is the business of whatever loop is building — not of the framework. What the framework asks is `SRS-DD-ART-050` and the gate.

**Installing any of them here.** They are not under this repository's constraints: standard library only, nothing framework-specific in what travels to a project (`ART-070`), and no number of ours in a project's own space.

### Consequences

The layer now produces three artefacts and only two of them are compared: the map and the dashboard are generated and held fresh by the gate, the document is printed and never stored by us.
The `srs-arch` procedure stands at 1 481 words of its 1 550 budget, so the next thing added to it displaces something.
`--baseline` doubles what a measurement run costs in tokens and in money, which is why it is a flag and not the default.
Reading four projects took a session's worth of fetching; the parts taken are recorded here so that the next person weighing them starts from what was decided rather than from the repositories.
