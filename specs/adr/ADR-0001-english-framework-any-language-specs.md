# ADR-0001 — The framework is English-only; specifications are not

- **Status:** accepted
- **Date:** 2026-08-05
- **Related requirements:** FR-CHK-090, FR-INIT-090

## Context and problem statement

The tooling has to enforce that every requirement carries exactly one modal
verb of binding force. Modal verbs are words, and words belong to a language.
The first real consumer of this framework keeps its specification in Russian,
while the framework's own documentation is read by whoever finds the
repository.

Hard-coding English would have forced every non-English project to write its
specification in a language its authors do not think in — or to fork the
checker.

## Considered options

1. English everywhere: the framework and every specification it validates.
2. Localized builds of the tooling: one checker per language.
3. A per-project lexicon: the tooling knows no language and reads the words
   it enforces from configuration.

## Decision outcome

Option 3. The framework's own documentation, code comments and requirements
are written in English, so that anyone can read and contribute to them. What
a project writes in its `specs/` is that project's business: `modal_verbs`,
`negation_words` and `rationale_markers` in `specs/srs-config.json` decide
which words carry which force, and the checker compiles its patterns from
them.

### Consequences

- The checker contains no natural-language knowledge at all — it cannot
  suggest a lexicon, and the installer refuses to guess one. Generating a
  lexicon is the `srs-init` procedure's job, and the maintainer confirms it.
- A project that inflects its modal verb must list every form it intends to
  write. A missing form is the most common cause of a failed adoption.
- Framework files stay free of other languages, with deliberate exceptions
  where a demonstration is the point: the Configuration section of
  `specs/README.md`, one comment in `tools/srs_check.py` about the placement
  of negation, the Russian fixture in `tests/adopt-smoke.sh`, and
  `docs/multilingual.md`.
