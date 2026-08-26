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
   whether to keep a **grounds register** — and, where they want one, what
   length of period its dashboard counts by (`month` / `quarter` / `year`) —
   and **the language of the specification**.

   The period is the only one of the register's settings the install asks
   about, and the one nobody supplies later without knowing the key exists
   (`rules` and `grades` are the others, and both have working defaults). It
   is what
   "lately" means for this project: how often the dashboard gets to say that
   requirements have started arriving on no hypothesis. A project shipping
   weekly wants `month`; one shipping twice a year wants `year`. Where they
   have no opinion, `quarter` is the default and saying so is enough.
2. **Find the line width the project already follows, and confirm it.**
   Read rather than guess: `.editorconfig` (`max_line_length`), a
   formatter's or linter's configuration — `pyproject.toml`, `.prettierrc`,
   `setup.cfg`, `.eslintrc` — or a sentence in a contributing guide. Say
   what you found **and which file it came from**, so a wrong reading is
   visible to the person approving it.

   Where the project states nothing, say that and pass no width. Do not
   infer one from how the files happen to look, and do not offer this
   framework's own 120: that number governs this repository and has no
   standing in somebody else's. The value ends up in their configuration
   and in their agent guide, so a guess here is one they would be reading
   back for a long time.
3. If the language is not English, generate the lexicon yourself:
   - `modal_verbs` — every form of the binding, recommended, and optional
     verbs (genders, numbers, anything that can appear in a statement);
   - `negation_words` — the negation particle(s);
   - `rationale_markers` — the word that opens a rationale paragraph.
4. **Show the generated lists to the user and get confirmation before
   installing.** The choice of verbs is normative for their project — do
   not decide silently. Explain which words you assigned to which force
   class (mandatory / recommended / allowed).
5. Run the installer with **every collected answer as an explicit flag,
   plus `--defaults`** (explicit flags so nothing silently falls back to
   the English defaults and causes a spurious validation failure;
   `--defaults` as a guard for interactive TTYs — on EOF the prompts
   auto-default anyway):

   ```
   python3 tools/srs_init.py <target> --defaults --name "<name>" \
     --areas "A,B" --code-roots "src" --test-roots "tests" \
     --extensions ".py,.ts" --ci <choice> \
     --grounds <yes|no> [--line-width <columns>] \
     --modal-verbs "<comma-separated>" --negation-words "<...>" \
     --rationale-markers "<...>"
   ```

   Add `--period <month|quarter|year>` to that command **only with
   `--grounds yes`** — passed alongside `--grounds no` it has no register to
   configure, and the installer says so rather than dropping it, which is a
   note the user did not need to read.

   Run that command **twice**: first with `--dry-run` appended, which
   writes nothing and prints the exact created / refreshed / skipped
   list — show that list to the user together with the lexicon — and
   then, once they approve, the same command without the flag.

6. After a successful install, rewrite the placeholder requirement in the
   target (`specs/10-fr-<area>.md`) as a grammatical sentence in the
   specification language, then run the target's checker again.
7. Suggest recording the force class of each chosen verb in the target's
   `specs/00-glossary.md`, as `specs/README.md` recommends.
8. If the target has real code, offer to mine a specification from it
   with the `srs-harvest` skill.

## Adopting an existing specification

When the target already has an SRS-shaped spec (numbered requirements in
`specs/`):

1. Read one or two of its requirement files. Infer the language, the
   modal verbs actually used (all their forms), the negation particle,
   the rationale marker, and note the areas in the identifiers.
2. Build the lexicon lists and **confirm them with the user together with
   the areas you read out of the identifiers** — both, and before anything
   is installed. In the fresh path the areas are the user's own answer; here
   they are your reading of somebody else's specification, and they are the
   middle segment of every identifier that project will ever publish. Show
   the list back and let them correct it, exactly as with the lexicon.
3. Run the installer as in fresh step 5 (it will detect adopt mode; the
   discovered areas are its default, but pass `--areas` explicitly with
   what you saw). The installer validates the whole spec against the
   proposed configuration **before changing anything**; on failure
   (exit 3) the target is untouched. `--dry-run` lists what would be
   installed but skips that validation — it needs the checker inside the
   target — so treat the dry run as a preview of the file list only.
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
CHANGELOG upgrade notes; the tooling (`srs_check.py`, `srs_view.py`) and
the skills refresh automatically, precious files (CI,
CLAUDE.md/AGENTS.md, .gitattributes) only with `--force`. Add
`--dry-run` first when the user wants to see the file list before
anything moves. Remind them to commit the refreshed tooling and the
regenerated matrix.

After the installer finishes, offer to merge the agent docs — the one
upgrade the script deliberately never performs:

1. Diff the target's `CLAUDE.md` and `AGENTS.md` against the shipped
   templates in `skeleton/` — **not** against the ones in the framework
   repository's root, which describe that repository rather than a target.
   The templates carry `<Your Project Name>` where the target has its real
   name; account for that substitution.
2. For a file that carries the `SRS-DD` marker, propose a merged
   version: framework additions folded in, the project name and every
   local addition preserved. Show the result and apply it only on the
   user's explicit confirmation.
3. A file without the marker is not ours (same rule the installer
   follows): report what changed on the framework side and leave the
   file alone.
