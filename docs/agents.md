# SRS-DD and coding agents

The framework is built for codebases written with AI coding agents, but it depends on none of them: the rules live in `AGENTS.md` and in plain-markdown skills, the enforcement is a standard-library script, and a team working entirely by hand loses nothing.

## An initialized project works out of the box

`AGENTS.md` is the canonical, agent-agnostic guide, and modern agents (Cursor, Codex, Gemini CLI, GitHub Copilot, …) read an `AGENTS.md` at the repository root natively.
`CLAUDE.md` imports it with an `@AGENTS.md` line, because Claude Code loads `CLAUDE.md` and not the guide, and a pointer it is told to follow is followed less often than a file it is handed: measured on the framework's own repository, a fresh instance behind "read `AGENTS.md` first" named records bare in 87 cases of 100, and with the guide imported in 16.

The skills in `.claude/skills/` are plain markdown with no Claude-specific machinery.
An agent without a skill system reads them directly as workflow guides:

| Skill | What it is for |
|---|---|
| `srs` | The everyday loop and multi-requirement planning |
| `srs-new` | Authoring one requirement through a dialog |
| `srs-audit` | Spec ↔ code drift, test adequacy, and the links requirements do not carry |
| `srs-harvest` | Mining a specification out of existing code |
| `srs-check` | Naming and running the checks a finished change calls for |
| `srs-page` | Rendering the specification as a page, and opening it |
| `srs-baseline` | Freezing the specification at a milestone |
| `srs-upgrade` | Picking up a new framework version |
| `srs-bet` | The grounds register: a hypothesis, a bet, a measurement, a refutation — installed only where the register is |
| `srs-arch` | The architecture layer: what the parts are, what each carries, and where that description and the specification disagree — installed only where the layer is |
| `srs-init`, `srs-release` | Setup and releases — stay in the framework repository, never installed |

## If your tool wants its own rules file

A two-line pointer is enough — do not duplicate the rules:

```
This project follows the SRS-DD standard.
Read AGENTS.md first; the specification rules live in specs/README.md.
```

That works for `.cursor/rules/srs.mdc`, `.github/copilot-instructions.md`, and anything else of that shape.

## Installing by URL

An agent given nothing but this repository's URL can install the framework itself; the [README](../README.md) section "Handing this to an agent" holds the procedure and the canonical URLs.
Three things in it are not the agent's to make alone, and the skill says so: the **requirement areas** (the middle segment of every identifier, and identifiers are immutable), the **lexicon** (which words carry binding force) and the **line width** the project's code already follows.
The agent proposes; the maintainer confirms — and sees the dry-run install list before anything is written.
The width is looked for where the project states it — an `.editorconfig`, a formatter's configuration, a contributing guide — shown with where it was found, and passed on only once approved; nothing is invented where nothing is found.

### Modes and exit codes

The installer detects the mode itself from the target: **fresh** where no specification is present, **adopt** where an SRS-shaped specification exists without `specs/srs-config.json`, **upgrade** where that configuration exists.
Adopt is transactional — the target is validated first and left byte-identical on failure — which is what makes a retry safe.
An agent running unattended has only the exit code to decide by:

```
0  installed
1  checker errors, or partial completion past adopt's point of no return
2  refused before changing anything
3  adopt rolled back, target untouched
```

Zero is done; one means read the checker's report before anything else; two means answer differently and try again; three means the target is as it was and the reason is in the output.

## What the agent is held to afterwards

The loop is the same one a human follows, and the checker is what makes it non-optional: a change that alters behavior names the requirement it closes, and `specs/90-traceability.md` is regenerated and compared byte-for-byte in CI.
An agent cannot quietly widen scope without the diff showing a requirement that was never written.
