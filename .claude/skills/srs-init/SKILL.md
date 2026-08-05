---
name: srs-init
description: Guided initialization of a target repository with the SRS-DD skeleton, including generating the specification-language lexicon for any language. Invoke when the user wants to set up SRS-DD in a project. Wraps tools/srs_init.py; available only in a clone of the framework repository (the skill is not copied into targets).
---

# Initializing a target project

The mechanics live in `tools/srs_init.py` — read its `--help` if unsure.
This skill adds the one thing the script cannot do: language.

## Dialog

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
4. Run the installer with explicit flags:

   ```
   python3 tools/srs_init.py <target> --name "<name>" --areas "A,B" \
     --code-roots "src" --test-roots "tests" --extensions ".py,.ts" \
     --ci <choice> \
     --modal-verbs "<comma-separated>" --negation-words "<...>" \
     --rationale-markers "<...>"
   ```

   Pass every collected answer as a flag — anything omitted will be
   prompted for interactively (or silently defaulted on EOF).

5. After a successful install, rewrite the placeholder requirement in the
   target (`specs/10-fr-<area>.md`) as a grammatical sentence in the
   specification language, then run the target's checker again:
   `python3 <target>/tools/srs_check.py`.
6. Suggest recording the force class of each chosen verb in the target's
   `specs/00-glossary.md`, as `specs/README.md` recommends.
