# ADR-0008 — Rules can be tuned, and a requirement can be excused

- **Status:** accepted
- **Date:** 2026-08-10
- **Related requirements:** FR-CHK-140, FR-CHK-150, FR-CHK-160, FR-CHK-120

## Context and problem statement

Two facts the checker already knows are shown only to whoever asks for
`--coverage`: a realized requirement listing no test, and a requirement no
link touches. Reporting them where they are read (FR-CHK-140, FR-CHK-150)
turns them into warnings — and this project's own specification would
acquire twenty-nine of them on the first run.

That number is the problem. A gate is obeyed while its output is worth
reading; a run that always prints the same twenty-nine lines teaches people
to skim past the thirtieth, which is the one that mattered. So the rules
cannot arrive without a way to turn them down.

Both legitimate shapes exist. A project may decide the rule does not apply
to it at all — mid-harvest, or verifying by inspection throughout. Or one
requirement may be the honest exception: verified by inspection, never to
list a test, and saying so once should end the argument.

## Considered options

1. Configuration only: severities and an exemption list of identifiers in
   `srs-config.json`.
2. A comment marker beside the requirement, in the style of the existing
   `srs-ignore` for annotations in code.
3. A field in the requirement's metadata block, plus severities in the
   configuration.

## Decision outcome

Option 3, and the two new rules arrive as warnings rather than as reports
nobody enables.

An exemption is a claim about one requirement, so it belongs in that
requirement: it is diffed in review beside the statement it excuses, it
shows on the rendered page, and it dies when the requirement is superseded.
Option 1 puts it in a file that outlives its subject — a list of
identifiers, in a project where identifiers are never reused, is a list that
only grows and that nobody dares delete from. Option 2 keeps the block
format untouched, which is real, but hides the exemption from every reader
who is not looking at the raw markdown; an excuse that cannot be seen is an
excuse that is never revisited.

Severity stays in the configuration, because "this rule does not apply to
this project" is a project-wide claim and there is nowhere else for it.

### Consequences

- The metadata format gains a field, and the format is a published contract
  (IF-SPEC-010): the standard, the checker's field list, the viewer and the
  page all have to learn it. An older checker meeting the new field reports
  an unknown field — a warning, and so a failed build wherever the gate runs
  `--strict`, which is where most gates run.
- The skeleton's placeholder requirement links to nothing, so a fresh
  install would warn on FR-CHK-150 the first time it ran. It will carry the
  exemption instead, which doubles as the documentation nobody reads: the
  first requirement a new project sees demonstrates the field.
- This project starts with twenty-nine warnings of its own. Filling the
  `tests` fields honestly is the intended answer; lowering the rule is the
  admission that we will not.
- A project that mutes everything gets a green gate that means nothing. That
  is the cost of making the gate tunable at all, and it is preferable to the
  alternative, where the gate is untunable and therefore ignored.
