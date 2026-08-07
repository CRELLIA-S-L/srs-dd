# ADR-0004 — The payload lives in `skeleton/`, not behind a blocklist

- **Status:** accepted
- **Date:** 2026-08-06
- **Related requirements:** CON-SPEC-020, FR-INIT-020

## Context and problem statement

Until 0.7.0 this repository's `specs/` was both the starter files copied into
every target and the place the framework's own specification would have to
live. The installer told the two apart with a blocklist: copy everything
under `specs/` except three generated names.

That works only while the framework has no specification of its own. The
moment a requirement about the checker is written, it matches no blocklist
entry, travels into every target installed afterwards, and cites
`tools/srs_init.py` — a file that does not exist there. The target's own
checker then fails on its first run, with an error its maintainer cannot
diagnose.

## Considered options

1. Extend the blocklist to every framework file, and keep extending it.
2. Keep the framework's specification somewhere other than `specs/`.
3. Move the payload into `skeleton/` and let `specs/` be an ordinary
   specification.

## Decision outcome

Option 3. `skeleton/specs/` holds the starter files, `skeleton/AGENTS.md` and
`skeleton/CLAUDE.md` the target-facing guides, and the installer copies from
there. `specs/` in this repository is the framework's own specification, and
this repository is an SRS-DD project like any other.

One exception is deliberate: `specs/README.md` — the standard itself — is
identical in every project and ships from `specs/`. A second copy under
`skeleton/` would be a 300-line normative document maintained twice.

Option 1 was rejected because a blocklist fails open: forgetting an entry
leaks, and nothing fails until it reaches a stranger. Option 2 was rejected
because the framework should be read the way a target is — including by its
own tooling.

### Consequences

- Isolation is now testable rather than trusted: `tests/installer-smoke.sh`
  installs into a temporary directory and asserts it holds exactly one
  requirement, the generated placeholder.
- ART-070 of the constitution states the rule the directory layout enforces,
  so it also covers the routes a directory cannot: annotations in the two
  shipped tools, and paths that exist only here.
- Anyone scripting against a framework clone has to know the new locations —
  recorded in the 0.7.0 upgrade notes. Installed targets are unaffected.
- The root `AGENTS.md` and `CLAUDE.md` became free to describe this
  repository, which is what an agent handed the URL reads first.
