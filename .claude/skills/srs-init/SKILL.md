---
name: srs-init
description: Guided setup of SRS-DD in a target repository — fresh initialization, adoption of an existing SRS-shaped specification, and upgrades of already-initialized targets. Generates the specification-language lexicon for any language. Invoke when the user wants to set up, adopt into, or upgrade SRS-DD in a project. Wraps tools/srs_init.py; available only in a clone of the framework repository (the skill is not copied into targets).
---

# Setting up a target project

The mechanics live in `tools/srs_init.py` — read its `--help` if unsure.
The installer detects the mode itself: fresh (no spec), adopt (an
existing spec without `specs/srs-config.json`), upgrade (config
present). This skill adds the one thing the script cannot do: language.

## Fresh initialization

1. Ask the user for: target path, project name, requirement areas
   (uppercase identifiers), production code roots, test roots, source
   file extensions, CI platform (`github` / `gitlab` / `both` / `none`),
   and **the language of the specification**.
2. If the language is not English, generate the lexicon yourself:
   - `modal_verbs` — every form of the binding, recommended, and optional
     verbs (genders, numbers, anything that can appear in a statement);
   - `negation_words` — the negation particle(s);
   - `rationale_markers` — the word that opens a rationale paragraph.
3. **Show the generated lists to the user and get confirmation before
   installing.** The choice of verbs is normative for their project — do
   not decide silently. Explain which words you assigned to which force
   class (mandatory / recommended / allowed).
4. Run the installer with **every collected answer as an explicit flag,
   plus `--defaults`** (explicit flags so nothing silently falls back to
   the English defaults and causes a spurious validation failure;
   `--defaults` as a guard for interactive TTYs — on EOF the prompts
   auto-default anyway):

   ```
   python3 tools/srs_init.py <target> --defaults --name "<name>" \
     --areas "A,B" --code-roots "src" --test-roots "tests" \
     --extensions ".py,.ts" --ci <choice> \
     --modal-verbs "<comma-separated>" --negation-words "<...>" \
     --rationale-markers "<...>"
   ```

5. After a successful install, rewrite the placeholder requirement in the
   target (`specs/10-fr-<area>.md`) as a grammatical sentence in the
   specification language, then run the target's checker again.
6. Suggest recording the force class of each chosen verb in the target's
   `specs/00-glossary.md`, as `specs/README.md` recommends.
7. If the target has real code, offer to mine a specification from it
   with the `srs-harvest` skill.

## Adopting an existing specification

When the target already has an SRS-shaped spec (numbered requirements in
`specs/`):

1. Read one or two of its requirement files. Infer the language, the
   modal verbs actually used (all their forms), the negation particle,
   the rationale marker, and note the areas in the identifiers.
2. Build the lexicon lists and **confirm them with the user**, same as
   fresh step 3.
3. Run the installer as in fresh step 4 (it will detect adopt mode; the
   discovered areas are its default, but pass `--areas` explicitly with
   what you saw). The installer validates the whole spec against the
   proposed configuration **before changing anything**; on failure
   (exit 3) the target is untouched.
4. If validation fails, read the checker's output: wrong or incomplete
   lexicon (a missing verb form is the most common cause) — extend the
   lists and re-run; genuine spec defects — report them to the user
   instead of forcing the lexicon around them.
5. After success: remind the user to commit the regenerated
   `specs/90-traceability.md` together with the new tooling, and relay
   the installer's advisory about merging new framework sections into
   their own `specs/README.md`, if it printed one.

## Upgrading

An initialized target is upgraded by pulling the framework clone and
re-running the installer against the target:

```
git -C <framework-clone> pull
python3 <framework-clone>/tools/srs_init.py <target> --defaults
```

The installer prints the checker version transition and the relevant
CHANGELOG upgrade notes; the checker and the skills refresh
automatically, precious files (CI, CLAUDE.md/AGENTS.md, .gitattributes)
only with `--force`. Remind the user to commit the refreshed tooling and
the regenerated matrix.
