---
name: srs-init
description: Guided setup of SRS-DD in a target repository — fresh initialization, adoption of an existing SRS-shaped specification, and upgrades of already-initialized targets. Generates the specification-language lexicon for any language. Invoke when the user wants to set up, adopt into, or upgrade SRS-DD in a project. Wraps tools/srs_init.py; available only in a clone of the framework repository (the skill is not copied into targets).
---

# Setting up a target project

The mechanics live in `tools/srs_init.py` — read its `--help` if unsure.
The installer detects the mode itself: fresh (no spec), adopt (an existing spec without `specs/srs-config.json`), upgrade (config present).
This skill adds the one thing the script cannot do: language.

## Fresh initialization

1. Ask the user for: target path, project name, requirement areas (uppercase identifiers, words joined by an underscore — `MAP_ILAND`), production code roots, test roots, source file extensions, CI platform (`github` / `gitlab` / `both` / `none`), whether to keep a **grounds register** — and, where they want one, what length of period its dashboard counts by (`month` / `quarter` / `year`) — whether to keep an **architecture layer**, and **the language of the specification**.

   The period is the only one of the register's settings the install asks about, and the one nobody supplies later without knowing the key exists (`rules` and `grades` are the others, and both have working defaults).
   It is what "lately" means for this project: how often the dashboard gets to say that requirements have started arriving on no hypothesis.
   A project shipping weekly wants `month`; one shipping twice a year wants `year`.
   Where they have no opinion, `quarter` is the default and saying so is enough.
2. **Find the line width the project already follows, and confirm it.**
   Read rather than guess: `.editorconfig` (`max_line_length`), a formatter's or linter's configuration — `pyproject.toml`, `.prettierrc`, `setup.cfg`, `.eslintrc` — or a sentence in a contributing guide.
   Say what you found **and which file it came from**, so a wrong reading is visible to the person approving it.

   Where the project states nothing, say that and pass no width.
   Do not infer one from how the files happen to look, and do not offer this framework's own 120: that number governs this repository and has no standing in somebody else's.
   The value ends up in their configuration and in their agent guide, so a guess here is one they would be reading back for a long time.
3. If the language is not English, generate the lexicon yourself:
   - `modal_verbs` — every form of the binding, recommended, and optional verbs (genders, numbers, anything that can appear in a statement);
   - `negation_words` — the negation particle(s);
   - `rationale_markers` — the word that opens a rationale paragraph.
4. **Show the generated lists to the user and get confirmation before installing.**
   The choice of verbs is normative for their project — do not decide silently.
   Explain which words you assigned to which force class (mandatory / recommended / allowed).
5. Run the installer with **every collected answer as an explicit flag, plus `--defaults`** (explicit flags so nothing silently falls back to the English defaults and causes a spurious validation failure;
   `--defaults` as a guard for interactive TTYs — on EOF the prompts auto-default anyway):

   ```
   python3 tools/srs_init.py <target> --defaults --name "<name>" \
     --areas "A,B" --code-roots "src" --test-roots "tests" \
     --extensions ".py,.ts" --ci <choice> \
     --grounds <yes|no> --arch <yes|no> [--line-width <columns>] \
     --modal-verbs "<comma-separated>" --negation-words "<...>" \
     --rationale-markers "<...>"
   ```

   Add `--period <month|quarter|year>` to that command **only with `--grounds yes`** — passed alongside `--grounds no` it has no register to configure, and the installer says so rather than dropping it, which is a note the user did not need to read.

   Run that command **twice**: first with `--dry-run` appended, which writes nothing and prints the exact created / refreshed / moved / skipped list — show it to the user with the lexicon — and then, once they approve, the same command without the flag.

6. After a successful install, rewrite the placeholder requirement in the target (`specs/10-fr-<area>.md`) as a grammatical sentence in the specification language, then run the target's checker again.
7. Suggest recording the force class of each chosen verb in the target's `specs/00-glossary.md`, as `srs-dd/standard.md` recommends.
8. If the target has real code, offer to mine a specification from it with the `srs-harvest` skill.

## Adopting an existing specification

When the target already has an SRS-shaped spec (numbered requirements in `specs/`):

1. Read one or two of its requirement files.
   Infer the language, the modal verbs actually used (all their forms), the negation particle, the rationale marker, and note the areas in the identifiers.
2. Build the lexicon lists and **confirm them with the user together with the areas you read out of the identifiers** — both, and before anything is installed.
   In the fresh path the areas are the user's own answer; here they are your reading of somebody else's specification, and they are the middle segment of every identifier that project will ever publish.
   Show the list back and let them correct it, exactly as with the lexicon.
3. Run the installer as in fresh step 5 (it will detect adopt mode; the discovered areas are its default, but pass `--areas` explicitly with what you saw).
   The installer validates the whole spec against the proposed configuration **before changing anything**; on failure (exit 3) the target is untouched.
   `--dry-run` lists what would be installed but skips that validation — it needs the checker inside the target — so treat the dry run as a preview of the file list only.
4. If validation fails, read the checker's output: wrong or incomplete lexicon (a missing verb form is the most common cause) — extend the lists and re-run; genuine spec defects — report them to the user instead of forcing the lexicon around them.
5. After success: remind the user to commit `specs/90-traceability.md` with the tooling.
   A README of the project's own under `specs/` stays where it is — the standard lives in `srs-dd/standard.md` — and its rules are sorted the same way: what the standard already says needs nothing; a project rule the standard permits goes to `specs/constitution.md`; a rule the checker refuses is a practice the maintainer has to change — name it and stop.
   What it said about the system rather than its rules goes to `specs/01-introduction.md` and `specs/00-glossary.md`. The README itself is the project's and is not edited.

## Upgrading

An initialized target is upgraded by pulling the framework clone and re-running the installer against the target:

```
git -C <framework-clone> pull
python3 <framework-clone>/tools/srs_init.py <target> --defaults
```

The installer prints the checker version transition and the relevant CHANGELOG upgrade notes; `srs-dd/` and the skills refresh whole, the region of `AGENTS.md` between `<!-- srs-dd -->` and `<!-- /srs-dd -->` is rewritten in place, and nothing else of the project's is touched — the hook, the pipelines, `CLAUDE.md`, `.gitattributes` and the rest of `AGENTS.md` are the project's.
Add `--dry-run` first when the user wants to see the file list before anything moves.
Remind them to commit the refreshed tooling and the regenerated matrix.

A project installed before 0.22.0 is moved into the directory by the upgrade: the tools and the standards leave `tools/`, `specs/`, `grounds/` and `arch/`, and the report says what the hook, the pipelines and the guide now have to call; the articles of the method it kept in `specs/constitution.md` may be deleted, since `srs-dd/method.md` carries them.

## Wiring the gate

The hook and the pipelines are the project's files: the installer writes a starter only where there is none, never again, and its report — *Pre-commit gate*, *Pipeline gate* — says whether git runs a hook, whether that hook calls `srs-dd/tools/srs_gate.py`, whether any pipeline does, and prints what to add where not.
Read it after every run and add what it prints where the project runs its hooks: a line in a hook of the project's own, a `repo: local` hook in `.pre-commit-config.yaml`, the line in `.husky/pre-commit`, a command in `lefthook.yml` — with `pre-commit install` or `lefthook install` where git runs nothing yet — and a step in a workflow under `.github/workflows/` or a job in `.gitlab-ci.yml`.
Where nothing runs at all, `git config core.hooksPath .githooks` switches the starter on, and only then: the switch turns off whatever ran before.
On a service the installer does not know, read its pipeline and add the step in that service's form.
Done is the report, run again, saying the hook and a pipeline call the gate — or your reading of the step on a service it does not know; a hook git does not run is a gate that looks installed.

## Where the region landed

The installer finds the framework's region of `AGENTS.md` by its border alone: a line holding nothing but a marker is one, a sentence naming the markers is not, and a fenced example of those lines reads to it exactly like the region.
So open the file once and see that the region stands where an agent meets the method's rules — not inside an example or a fenced block.
Where it landed wrong, move the two marker lines to where the rules belong and run again.
