# SRS-DD and coding agents

The framework is built for codebases written with AI coding agents, but it
depends on none of them: the rules live in `AGENTS.md` and in plain-markdown
skills, the enforcement is a standard-library script, and a team working
entirely by hand loses nothing.

## An initialized project works out of the box

`AGENTS.md` is the canonical, agent-agnostic guide, and modern agents
(Cursor, Codex, Gemini CLI, GitHub Copilot, …) read an `AGENTS.md` at the
repository root natively. `CLAUDE.md` is a thin pointer to it.

The skills in `.claude/skills/` are plain markdown with no Claude-specific
machinery. An agent without a skill system reads them directly as workflow
guides:

| Skill | What it is for |
|---|---|
| `srs` | The everyday loop and multi-requirement planning |
| `srs-new` | Authoring one requirement through a dialog |
| `srs-audit` | Spec ↔ code drift and test adequacy |
| `srs-harvest` | Mining a specification out of existing code |
| `srs-init` | Guided setup — stays in the framework repository, never installed |

## If your tool wants its own rules file

A two-line pointer is enough — do not duplicate the rules:

```
This project follows the SRS-DD standard.
Read AGENTS.md first; the specification rules live in specs/README.md.
```

That works for `.cursor/rules/srs.mdc`, `.github/copilot-instructions.md`,
and anything else of that shape.

## Installing by URL

An agent given nothing but this repository's URL can install the framework
itself; the [README](../README.md) section "Handing this to an agent" holds
the procedure and the canonical URLs. Two decisions in it are not the
agent's to make alone, and the skill says so: the **requirement areas** (the
middle segment of every identifier, and identifiers are immutable) and the
**lexicon** (which words carry binding force). The agent proposes; the
maintainer confirms — and sees the dry-run install list before anything is
written.

## What the agent is held to afterwards

The loop is the same one a human follows, and the checker is what makes it
non-optional: a change that alters behavior names the requirement it closes,
and `specs/90-traceability.md` is regenerated and compared byte-for-byte in
CI. An agent cannot quietly widen scope without the diff showing a
requirement that was never written.
