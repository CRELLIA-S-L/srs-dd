# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions are framework releases, tagged `vX.Y.Z`; the same number is
embedded in `tools/srs_check.py` as `__version__`.

<!-- Format contract, relied upon by tools/srs_init.py when it reports an
     upgrade: a version section starts with `## [X.Y.Z]`; the lines after
     a `### <heading>` heading, up to the next `##`/`###`, belong to it.
     `### Upgrade notes` is printed in full; `### Added` and `### Changed`
     are printed one line per `- ` entry, so keep every entry's first
     sentence self-contained. Keep that shape. -->

## [0.12.0]

### Added

- The metadata block declares which keys are required. `status` and
  `verification` are; everything else is optional, and a key the checker
  does not know stays a warning — which is what lets a later version add
  one without breaking a specification written against an earlier one
  (IF-SPEC-010, FR-CHK-170).
- The `srs-check` skill names and runs the checks a change calls for. It
  reads the `verification` method and the `tests` field of every
  requirement the change touched, offers exactly those, and says in words
  what a person still has to look at (FR-SKILL-100).
- The `srs-page` skill renders the specification and opens it. It also
  says what the commands do not: the file is self-contained and can be
  sent to somebody, `--repo-url` is what makes its links to the code work,
  and CI may already publish the same page (FR-SKILL-110).
- Authoring a requirement and building it are two acts now. `srs-new` ends
  at the written requirement and the decision the discussion settled, and
  `srs` gained a second way in — from an approved requirement nobody has
  built yet, not only from a file about to change (FR-SKILL-090,
  ADR-0006).
- Whoever writes a statement judges what no checker reaches. One
  capability, verifiable, unambiguous, about behavior rather than
  implementation — no word list can do it, because what reads as vague
  depends on the sentence and a specification may be written in any
  language. It is asked of every procedure that puts a statement in the
  file, not only the authoring dialog: `srs-harvest` judges a mined batch
  before showing it, where a sentence read off an `if` sounds precise and
  says nothing testable, and `srs` judges a statement it rewords while
  closing the loop, which is where a repair quietly grows a second
  capability (FR-SKILL-120).
- The authoring dialog checks the verification method against the
  statement. `T` declared over a sentence no test could assert used to
  surface much later, when the requirement was built and somebody had to
  write a test that could not be written; the sentence and the method are
  on the table together in one step, which is where the question costs
  nothing (FR-SKILL-140).
- The baseline procedure offers an audit before it freezes. Scoped to the
  requirements the diff names, because auditing everything at every
  baseline is the step people stop taking (FR-SKILL-130).
- The graph draws every kind of link, told apart by its own form. Layers
  still come from `derives_from` and `refines` alone — a layer claims a
  level of abstraction, and a requirement must not sink because something
  it needs sits above it (FR-VIEW-160, ADR-0010).
- The graph can be narrowed to one requirement's surroundings. Pick a root
  and a distance, and the rest is hidden; a drawing of everything is the
  one view a specification of any size cannot use (FR-VIEW-150).
- `srs_view.py --open` renders the page and opens it. It implies `--html`
  when no path is given, so reading the specification is one word
  (FR-VIEW-140).
- A requirement that says it is verified by test and lists none is
  reported. Only where the method is `T` — one verified by inspection or
  analysis has no test by design, and reporting those would bury the ones
  that mean something (FR-CHK-140).
- A requirement no link touches is reported. Total isolation is the one
  case where a forgotten link shows: the checker can prove that what is
  written resolves, never that something was left out (FR-CHK-150).
- What a rule costs is the project's to set. Every rule short of an error
  now carries a name, and `rules` in `specs/srs-config.json` lowers one to
  a note that never fails `--strict`, or silences it; a single requirement
  excuses itself with `exempt: [rule-name]` in its own block, where the
  excuse is diffed in review and shows on the page (FR-CHK-160, ADR-0008).
- A retired key is reported by name. Where a later version of the format
  renames or withdraws one, the checker says which version did it and what
  replaced it; the framework never rewrites your specification, it tells
  you what to change (FR-CHK-180, ADR-0009).
- A requirement is reachable from every view of the page. Links in the
  dashboard and in a baseline comparison, and nodes in the graph, now open
  the requirement they name — switching to the view that renders it and
  clearing a filter that would hide it (FR-VIEW-130).

### Changed

- The graph is grouped by area instead of layered by derivation. A column
  is an area and a row is a requirement's number, so a line crossing
  columns is a link that leaves its area; this specification's drawing
  goes from 8825 by 179 — a ribbon in which a node fitted to a screen is
  thirteen pixels wide — to about 1005 by 956. Sixty-five of its
  eighty-seven requirements have no derivation parent, so the axis the
  layers claimed was never there (FR-VIEW-060, ADR-0012, superseding
  ADR-0010).
- A node in the graph shows its status in colour, with a legend. The class
  had been on every node since the graph was drawn and a neutral stroke in
  the stylesheet painted over it, so the one view that could have shown
  the statuses was the one that did not (FR-VIEW-180).
- Dragging a node is now collapsing an area. A position means membership
  of an area and a place in its ordering, so a dragged node is a node
  lying about where it belongs; clicking a column's name folds it away,
  which is what pulling a node aside was for (FR-VIEW-110).
- The graph lights a node's links on hover, not on click. That leaves the
  click free to open the requirement the node names (FR-VIEW-110,
  FR-VIEW-130).

### Fixed

- The filters work again. The graph's transform function and the filters'
  were both called `apply`, and a function declared inside a block is also
  assigned to the enclosing function's binding of the same name — so every
  click on a status, type or area chip moved the graph a little and
  filtered nothing. Silently, in every page this framework has rendered.
- A wide layer is no longer folded into rows. Wrapping put the eleventh
  node under the first, nowhere near its parent, discarding the only thing
  the ordering pass computes; the canvas pans and zooms, so the drawing is
  free to be wide instead.
- The graph's node order is settled by sweeping in both directions and
  swapping adjacent pairs, as `dot` does. One downward sweep left every
  lower layer at the mercy of whatever the upper one happened to be.
- The rendered page is a text file again. Its comparison script joined
  values on a unicode escape for NUL, written for JavaScript and eaten by
  the Python string that carries the script, so every page shipped with
  real NUL bytes in it — enough for grep, diff and an editor to call it
  binary.
- Omitting a required key is answered by naming it. `verification` left out
  used to be reported as `method '' is not one of T/D/I/A`, which describes
  the symptom and hides the cause (FR-CHK-170).
- Clicking a graph node does something again. Cancelling `pointerdown`
  suppressed the compatibility mouse events, and with them every click the
  graph relied on, so neither the highlight nor the jump to a requirement
  had been firing (FR-VIEW-110).

### Upgrade notes

- Two skills arrive with this upgrade, `srs-check` and `srs-page`. Ask an
  agent to check a finished change or to show you the specification, and
  they are what answers.
- Two new rules may report on your specification the first time you upgrade:
  a requirement claiming `verification: T` with an empty `tests` field, and
  one no link touches. Both are warnings, so only a `--strict` gate fails on
  them. Fill the field or the link where the report is right, and where it
  is not, lower the rule in `specs/srs-config.json` or excuse the one
  requirement with `exempt: [test-missing]` or `exempt: [unlinked]` in its
  own block.

## [0.11.1] — 2026-08-09

### Changed

- The CI templates check out the whole history. The page compares
  baselines by reading the commits they name, and both templates asked for
  the shallow clone their platform gives by default.

### Fixed

- A baseline is no longer reported from a checkout that cannot hold it.
  Given a shallow clone — or a history that was squashed or imported —
  `srs_view.py` answered every baseline with the one commit it had, so the
  page showed six baselines agreeing that nothing had ever changed between
  any two of them; it now names only the states its repository actually
  holds, and says how many it could not reach (FR-VIEW-090, INV-SPEC-040).
- The page reads the current baseline from the log rather than from the
  snapshots it managed to load, so it names one even where the history to
  compare against is absent (FR-VIEW-090).

### Upgrade notes

- Your rendered page shows baselines only where CI checks out the whole
  history. Refresh the shipped CI template with `python3
  tools/srs_upgrade.py --force`, or add it by hand: `fetch-depth: 0` under
  `actions/checkout` on GitHub, `GIT_DEPTH: 0` in the job's `variables:`
  on GitLab.
- If your page has been showing baselines that all report no changes, that
  is this defect and not your specification.

## [0.11.0] — 2026-08-09

### Added

- `tools/srs_baseline.py` freezes the specification with one command. It
  writes the row into `specs/92-baselines.md` — version, date, and what
  changed since the previous baseline — and stops there; it ships with the
  framework, because every project baselines its own specification
  (FR-SPEC-010).

- The `srs-baseline` skill installs into every project. It is the way to
  ask for a baseline by name: it reads what changed, proposes the version
  for you to confirm, runs the command, and hands back the commit
  (FR-SKILL-080).

### Changed

- A baseline is the row in the log, not the tag. The commit that adds the
  row is the baseline, a `spec/vX.Y.Z` tag is an optional bookmark, and
  where there is none the baseline is found by that commit (INV-SPEC-040).
- No command commits, tags or pushes any more. `srs_release.py` and
  `srs_baseline.py` prepare files and report what to commit, so neither
  needs a console git set up (CON-SPEC-030).
- `tools/srs_release.py` cuts no baseline any more. It dates the changelog
  section, bumps the checker's version and stops; freezing the
  specification is its own command with its own number (FR-CI-070).
- `srs_view.py --diff` accepts a baseline version, not only a revision.
  Asked for `0.9.0` it finds that baseline whether or not anybody tagged it
  (FR-VIEW-050).

### Upgrade notes

- A release and a baseline are independent from now on (INV-SPEC-030): they
  need not share a number, neither implies the other, and one command each
  prepares them.
- `tools/srs_baseline.py` and the `srs-baseline` skill arrive with this
  upgrade. Ask an agent for a baseline, or run
  `python3 tools/srs_baseline.py X.Y.Z` yourself, then commit the row it
  writes — that commit is the baseline, and a `spec/v*` tag on it is
  optional from here on.
- Nothing in the framework runs `git commit` or `git tag` for you. If you
  drive git through an application rather than the console, the commands
  now stop where that application takes over.
- A `spec/v*` tag with no row in `specs/92-baselines.md` is no longer a
  baseline, and drops off the rendered page. The checker has been warning
  about exactly those tags; where your log fell behind them, `python3
  tools/srs_baseline.py X.Y.Z` writes each missing row from the tagged
  revision, so nothing has to be retagged or deleted.

## [0.10.0]

### Added

- `tools/srs_release.py` cuts a release in one command. It dates the
  changelog section, bumps the checker's version, adds the baseline row,
  commits those files and creates both tags — refusing before it touches
  anything if the tree is dirty, the section is missing, a tag exists or
  the checker does not pass. It writes no prose and does not push
  (FR-CI-070).
- The `srs-release` procedure carries what the command will not decide.
  Which number the release takes is a claim about compatibility
  and belongs to the maintainer; the changelog section an agent may draft,
  provided it knows that the first sentence of every entry stands alone,
  because an upgrade prints that sentence and cuts the rest. Framework-only,
  like `srs-init` (FR-SKILL-070).
- `srs_view.py --baseline X.Y.Z` prints the baseline row, ready to paste.
  It carries the version, the date, the tag and what changed since the
  previous baseline. Four rows of this project's own log were reduced by
  hand from a matrix and a diff — mechanical work that invites a wrong
  count nobody would ever notice (FR-VIEW-120).

### Changed

- Closing the loop now includes re-reading the statement. The `srs`
  procedure asked for a requirement before the code and, at the end, only
  for bookkeeping — status, `code`, `tests` — so nothing ever asked
  whether the statement still described what had been built. A change
  that starts as a fix needs no new requirement, and that exemption
  covers whatever else is added along the way: it is how a control
  reached the rendered page with no statement mentioning it
  (FR-SKILL-010).
- The Baselines procedure in the standard now writes the row before the
  tag. Tagging first leaves the tag pointing at a state the log does not
  describe until a later commit fixes it — and that later commit is the
  one that gets forgotten, three times here. Written in this order there
  is no gap to forget.

### Fixed

- The graph now fills its panel. Its canvas used to be sized from the
  drawing, so a small specification got a postage stamp to drag nodes
  around in, and a node left it at the first tug; the panel is the canvas
  now, the drawing is fitted into it, and a reset control brings back
  whatever was dragged out of sight. The gestures convert screen pixels
  into the drawing's own units, which they never had to while an unstretched
  canvas made the two the same by accident — and zooming converts a point
  rather than a distance, so it also accounts for the margin a centred
  drawing leaves inside its panel. FR-VIEW-110 says both now: the graph
  fills its area, and the view can be returned to where it started.

### Upgrade notes

- An upgrade brings three things into a project. `tools/srs_view.py` gains
  `--baseline X.Y.Z`, which prints the row for your own baseline log. The
  `srs` skill gains a step: closing the loop now means re-reading the
  statement and asking whether it describes what you built. And the
  release command is framework-only — nothing of it is installed.
- What an upgrade does not bring is the standard itself: `specs/README.md`
  is yours once installed, and this release reordered its Baselines
  procedure to write the log row before the tag. Copy that paragraph over
  if you want the order that keeps a tag from ever pointing at a state the
  log does not describe; a project that keeps tagging first loses nothing
  but the guarantee.

## [0.9.0] — 2026-08-08

### Added

- The checker reports a `spec/vX.Y.Z` tag the baseline log has no row for.
  Cutting a baseline is a tag and a row, in that order and so in separate
  commits — the gap between them is where it gets forgotten, twice in this
  repository already. A warning, which `--strict` turns into a failed
  build; silent where git or the tags are absent (FR-CHK-130).
- The rendered page says which baseline it shows and what rendered it.
  A page lives at a stable address
  and outlives a dozen releases; a reader arriving from a bookmark could
  not tell a fresh one from a six-month-old one (FR-VIEW-090).
- The graph can be explored. Pan it, zoom around the pointer, pull a node
  aside with its edges following, and click one to light what it links to
  and what links to it while the rest dims. Written in the page's own
  script: the layout is layered, which is the right shape for a
  derivation DAG and not what a force layout gives, so a graph library
  would have been paid for in every reader's download and every installed
  project in exchange for panning (FR-VIEW-110).
- Nodes within a layer are ordered by the barycentre of what they derive
  from. Edges run down the page instead of across it — three crossings
  became none in this repository's own graph — and the order is still
  computed the same way on every run, so the page stays byte-identical.
- The page compares any two baselines. It carries a snapshot of the
  specification at each, so a reader picks a pair and sees what was
  added, removed, or changed — without a clone and without the network.
  Statements travel as fingerprints: a reworded statement shows up as a
  change, and the page does not grow by the length of the whole
  specification per baseline (FR-VIEW-100).

### Upgrade notes

- A project that already cut baselines will see a warning for every tag
  its `92-baselines.md` has no row for. That is the point; write the rows
  or, if the log is not how the project records them, the warning is
  harmless outside `--strict`.
- The page carries the specification at every baseline: the oldest in
  full, each later one as its change. Sixty requirements and three
  baselines cost 14 KB, and the cost grows with what changes rather than
  with the size of the specification.

## [0.8.0] — 2026-08-08

### Added

- `tools/srs_upgrade.py` ships with every project. One command picks up a
  new framework version: it fetches the framework the project was
  installed from, prints the version transition, the upgrade notes and the
  file list, asks, and then applies — removing what it fetched either way.
  No clone to keep around, no address to look up. `--ref` pins a release,
  `--from` uses a clone already on disk and never touches the network,
  `--yes` is required where there is no terminal to confirm at
  (FR-INIT-120, FR-INIT-130).
- The `srs-upgrade` skill ships with it. An agent working inside an
  installed project can now upgrade without being handed the framework's
  address — which until now it had to be, because nothing in a project
  mentioned upgrading at all (FR-SKILL-060).
- A fresh install ends with the first steps, agent procedures first.
  It names every skill it just installed and what each
  is for, then where the first requirement goes, what validates the
  specification, what renders it as a page, and how the framework is
  upgraded later — the two lines it printed before said none of that.
  The skills lead because they are the point: the framework exists so
  that code written with agents still has requirements behind it
  (FR-INIT-150).
- An upgrade reports what arrived, not only what to do about it. The
  versions it crosses are summarized one line per changelog entry, marked
  `+` for added and `~` for changed, above the upgrade notes and with a
  pointer to the full text. Somebody who upgrades across three versions
  used to learn nothing about a new tool or skill, and so never used it
  (FR-INIT-160).
- `framework_url` in `specs/srs-config.json` records where to upgrade from.
  It is written at install time from the installing clone's own remote,
  SSH rewritten to HTTPS. A fork or a
  mirror sends its projects back to itself; a project installed before this
  field existed falls back to the framework's canonical address
  (FR-INIT-140).

### Upgrade notes

- Upgrade once the old way — `python3 path/to/srs-dd/tools/srs_init.py
  path/to/your-project` — and from then on the project upgrades itself with
  `python3 tools/srs_upgrade.py`.
- That first upgrade does not add `framework_url` to your config: an
  upgrade never rewrites `specs/srs-config.json`. Without it the upgrader
  uses the framework's canonical address, which is right unless you install
  from a fork — in that case add the key by hand, pointing at your fork.

## [0.7.2] — 2026-08-08

### Added

- The specification is published: <https://crellia-s-l.github.io/srs-dd/>.
  The page is rendered on the default branch, only after the suites pass —
  a page is worth serving exactly when what it renders is valid — and its
  code links point at the commit it was built from rather than at a moving
  branch. FR-CI-040 is `implemented`.

### Changed

- Every GitHub Action moved to its current major: `checkout` v4 → v7,
  `setup-python` v5 → v7, `upload-artifact` v4 → v7, `configure-pages`
  v5 → v6, `upload-pages-artifact` v3 → v5, `deploy-pages` v4 → v5.
  GitHub already forces the Node 20 actions onto Node 24 and will stop
  doing so. `ci/github-workflow.yml` — the template installed into target
  projects — is bumped with them, including its commented Pages block.

### Upgrade notes

- If your project runs the `.github/workflows/srs.yml` this framework
  installed, its actions are on the retiring Node 20 runtime. That file is
  precious, so an upgrade will not touch it: refresh it with `--force`, or
  edit it by hand to `actions/checkout@v7`, `actions/setup-python@v7`,
  `actions/upload-artifact@v7`, `actions/configure-pages@v6`,
  `actions/upload-pages-artifact@v5`, `actions/deploy-pages@v5`.
  A GitLab project is unaffected.

## [0.7.1] — 2026-08-07

### Changed

- The repository moved to GitHub, and the canonical URLs moved with it:
  the clone command, and the raw entry point an agent is handed, now
  `raw.githubusercontent.com/CRELLIA-S-L/srs-dd/main/.claude/skills/srs-init/SKILL.md`.
  The `repo_url` in `specs/srs-config.json` moved too, so the code links
  on the rendered page point at the new host.
- `.github/workflows/srs.yml` is the framework's own pipeline;
  `.gitlab-ci.yml` is removed. The GitLab template for target projects
  (`ci/gitlab-ci.yml`) stays — a project on GitLab is still installed
  with one.
- `tools/ci_selftest.sh` no longer derives the local gate from a CI
  configuration. It parses the YAML of the pipeline and of the shipped
  templates, then runs `tests/*.sh` directly — the same scripts CI runs,
  so the two cannot drift apart, and the skip list it used to need is
  gone. Two consequences worth knowing: a machine without `ruby` now
  loses the YAML parse alone instead of skipping the whole run with a
  zero exit, and the parse happens first, because a suite fails routinely
  on a regenerated matrix that is not staged yet and that must not hide a
  broken template.
- FR-CI-040 stands at `partial`: the specification is rendered on every
  run and kept as a build artifact, but nothing serves it until GitHub
  Pages is enabled for the repository. The workflow carries the three
  steps for it, commented out — enabling them before the setting exists
  turns the pipeline red.

### Upgrade notes

- Nothing in a target changes: the checker, the viewer, the skills and
  the templates are byte-identical to 0.7.0 apart from the version
  string. Re-running the installer is optional.
- If you saved the old GitLab raw URL of `srs-init/SKILL.md` — in a
  runbook, a prompt, or an agent's memory — replace it with
  `https://raw.githubusercontent.com/CRELLIA-S-L/srs-dd/main/.claude/skills/srs-init/SKILL.md`.
  The old host no longer serves this project.

## [0.7.0] — 2026-08-07

### Added

- The framework now has a specification of its own: 54 requirements in
  `specs/` describing the checker, the viewer, the installer, the agent
  procedures and the gates, across six areas — `SPEC`, `CHK`, `VIEW`,
  `INIT`, `SKILL`, `CI`. Mined from the code with the `srs-harvest`
  procedure and approved in one batch. The repository is now an SRS-DD
  project like any other, which is also the framework's own example.
- `skeleton/` — the payload the installer copies into a target, separated
  from the framework's own files. Requirements about our tooling can no
  longer travel into somebody's project, which ART-070 of
  `specs/constitution.md` now states as a standing principle and
  `tests/installer-smoke.sh` asserts on every run.
- `tests/` — the four suites the pipeline runs (`spec-check`,
  `installer-smoke`, `adopt-smoke`, `view-smoke`), moved out of the CI
  configuration so requirements can cite them by path; the pipeline's
  jobs are one-line calls to them.
- A `pages` job renders this repository's own specification on the
  default branch.
- A worked example lives in its own repository,
  `srs-dd-example-urlshortener`: an ordinary product with eleven
  requirements, one of them superseded and kept for the record. The
  pipeline checks it as a downstream consumer (FR-CI-060, advisory), and
  its own CI runs against this framework's `main` — so a change that
  stops accepting a valid specification surfaces there rather than in a
  stranger's project.
- `docs/` — install, upgrade, agents, and a demonstration of a
  specification written in another language, moved out of the README.
- `specs/adr/` — five decisions that had been taken but never written
  down: the English-only framework with per-project lexicons, the
  committed traceability matrix, the standard-library-only rule, the
  `skeleton/` split, and the choice of a classic SRS over the agentic
  spec formats.

### Changed

- The root `AGENTS.md` and `CLAUDE.md` now describe the framework
  repository itself. The target-facing templates live in
  `skeleton/AGENTS.md` and `skeleton/CLAUDE.md`; the installer copies
  them from there. An agent handed this repository's URL no longer reads
  a guide meant for somebody else's project.
- `README.md` is a landing page: what the framework is for, what a
  requirement looks like, and how to install it. Reference material moved
  to `docs/`. The canonical clone and raw-skill URLs stay on it, marked
  with `canonical-url` comments.
- `specs/README.md` — the standard itself — remains the single canonical
  copy and still ships from `specs/`; only the starter files moved to
  `skeleton/`.
- The `srs-init` procedure now diffs a target's agent guides against
  `skeleton/`, not against this repository's root copies.
- The `srs-audit` procedure lists all four sections `--coverage` prints.

### Fixed

- `tools/srs_check.py` carried two example annotations in its own header
  comment without `srs-ignore`. In a target that put `tools` in
  `code_roots`, the shipped checker reported an error against itself
  (`annotation references unknown requirement FR-UI-020`). Both example
  lines are now exempt.
- `specs/README.md` pointed at "the repository README" for the viewer's
  modes — a file that does not exist in a target. It now points at
  `srs_view.py --help`.

### Upgrade notes

- Re-run the installer as usual; nothing in a target changes shape. The
  refreshed `tools/srs_check.py` no longer reports an annotation error
  against its own header comment, so a project that put `tools` in
  `code_roots` and worked around that can drop the workaround.
- If you script against a framework **clone**, note that the skeleton
  moved: `skeleton/specs/`, `skeleton/AGENTS.md`, `skeleton/CLAUDE.md`.
  Installed targets are unaffected.
- Two questions are recorded in `specs/91-open-issues.md` rather than
  silently resolved: the checker's individual rules have no rule-level
  tests, and an area holds at most 99 requirements because identifiers
  carry exactly three digits.

## [0.6.0] — 2026-08-06

### Added

- `--dry-run` for `tools/srs_init.py`: writes nothing at all and prints
  the created / refreshed / skipped list the real run would produce, in
  every mode. A maintainer — or an agent proposing an install — sees the
  change before it happens. In adopt mode the existing specification is
  not validated under `--dry-run` (that needs the checker running inside
  the target); the real run validates first and leaves the target
  byte-identical when validation fails.
- "Handing this to an agent" in `README.md`: the entry point for a
  coding agent given nothing but the repository URL. Points at
  `.claude/skills/srs-init/SKILL.md` as the procedure, gives the
  clone-and-run one-liner (`git` and `python3` are the only
  prerequisites), the release-pinning form, the exit codes, and states
  which two decisions — requirement areas and the lexicon — the agent
  must bring back to the maintainer instead of settling itself.

### Changed

- The pre-commit gate no longer assumes it owns `pre-commit`. The
  installer reads `core.hooksPath`, looks for an existing hook and for
  husky or the pre-commit framework, and when the repository already
  runs something it says so instead of advising the `core.hooksPath`
  switch — which would have silently disabled it. Your hook calls the
  gate (`sh .githooks/pre-commit || exit 1`); when
  `.githooks/pre-commit` is itself yours, the gate is installed beside it as
  `.githooks/pre-commit.srs-dd`. Existing hooks were never overwritten
  before either; what was missing was the advice not to shadow them.
- The README's first section says what the framework is for: codebases
  written with AI coding agents, without depending on one. The argument
  itself stays where it was, at the end.
- The `srs-init` skill runs the installer with `--dry-run` first and
  shows the file list before installing — the same approval shape it
  already required for the lexicon.

### Fixed

- `tools/srs_init.py` no longer writes `__pycache__` into the framework
  clone. A cached module is validated by modification time and size
  alone, so a version string that changes without changing the file
  size could be served stale — the installer then reported, and picked
  upgrade notes for, a version other than the one it was installing.

### Upgrade notes

- Nothing to do. `--dry-run` is a new flag; no existing command changes
  behavior, and the checker is untouched apart from its version string.
- If you were told to run `git config core.hooksPath .githooks` by an
  earlier version and your repository had a hook of its own, check
  `git config --get core.hooksPath` — that setting redirects every hook,
  so the old one has not been running since.

## [0.5.0] — 2026-08-06

### Added

- `tools/srs_view.py` — a viewer for the specification the checker
  validates, on the same dependency budget (standard library, Python
  ≥ 3.9) and sharing its parser. Read-only: it never writes into
  `specs/` and never gates anything.
  - Terminal: one requirement with every link resolved in both
    directions; `--list` with filters; `--code <path>` — which
    requirements describe a file, by the `code`/`tests` fields and by
    the file's own `implements:`/`verifies:` annotations; `--tree`;
    `--coverage`; `--json`.
  - `--html` — one self-contained page (default `.srs-site/index.html`,
    a directory that ignores itself): search, filters, clickable links,
    a status dashboard, and a layered graph of the derivation links.
    No CDN, no fonts, no network; opens from `file://`.
  - `--diff <rev>` — the working tree against a baseline revision,
    per requirement and per field, with a unified diff of the statement.
- `repo_url` in `specs/srs-config.json` (or `--repo-url`): the blob-URL
  prefix that turns `code` and `tests` paths into links to your forge.
  Viewer-only — the checker ignores keys it does not know.
- CI templates render the page: `spec-site` in `ci/gitlab-ci.yml` (one
  rename from GitLab Pages) and an artifact upload in
  `ci/github-workflow.yml` (a commented block switches it to Pages).

### Changed

- `tools/srs_check.py` gained `parse_text()` beside `parse_file()` and
  now records each requirement's rationale. Both are additive: the
  checks, the warnings and the generated matrix are unchanged
  byte-for-byte.

### Fixed

- A specification file that is not readable UTF-8 (an editor saving
  cp1251, say) is now reported as an error naming the file, in the
  checker, instead of ending the run with a decoding traceback. The
  viewer reports it as a problem and shows the remaining requirements.
- The installer ships only `.md`, `.json` and `.gitkeep` from `specs/`
  as skeleton content — anything a maintainer generates under `specs/`
  in their clone no longer travels into fresh targets.

### Upgrade notes

- Re-run the installer: `tools/srs_view.py` arrives beside the refreshed
  checker. The two must stay in step — the viewer uses the checker's
  parser and says so if it finds an older one.
- The new CI job and the `AGENTS.md` line about the viewer are in
  precious files: they reach an initialized project only with `--force`
  (CI) or a manual merge (`AGENTS.md`, or the guided `srs-init` upgrade).
  The skills carry the same advice and refresh on their own.
- `.srs-site/` writes a `.gitignore` that ignores the directory itself,
  so nothing needs adding to yours.

## [0.4.0] — 2026-08-05

### Added

- Planning in the `srs` skill: a "Planning multi-requirement work"
  section — dependency-ordered plans whose steps cite requirement IDs
  and constitution articles, `draft` requirements flagged as approval
  blockers (ART-020), plans kept in the conversation and never written
  into `specs/`.
- Test adequacy in the `srs-audit` skill: decompose an EARS statement
  into trigger, state, and constraint; derive the implied test cases
  (including property-style ones for quantified constraints); map them
  against the `tests` field and report gaps. `verification: T` only;
  on explicit request the skill may author the missing tests (the one
  exception to its read-only rule).
- Agent-doc merge in the `srs-init` skill: the guided upgrade now offers
  an LLM-performed merge of the target's `CLAUDE.md`/`AGENTS.md` with
  the framework versions — SRS-DD-marked files only, shown before
  applying, local content preserved.
- "Other coding agents" documentation: `AGENTS.md` is the cross-agent
  entry point (read natively by Cursor, Codex, Gemini CLI, Copilot);
  skills are plain markdown readable without a skill system; a two-line
  pointer snippet for tools that want their own rules file.

### Upgrade notes

- Re-run the installer — the enriched `srs` and `srs-audit` skills
  refresh automatically.
- `CLAUDE.md` and `AGENTS.md` are still not auto-refreshed: run the
  guided upgrade (`srs-init` skill, from a framework clone) to have the
  agent merge the doc changes, or merge manually. The framework copies
  gained a skills note (`AGENTS.md`) and updated skill mentions
  (`CLAUDE.md`).

## [0.3.0] — 2026-08-05

### Added

- Client pre-commit gate: the installer ships `ci/pre-commit` into
  targets as `.githooks/pre-commit` (all three modes, precious). It runs
  the checker and fails when the committed traceability matrix is
  stale — the same gate CI enforces, caught before the commit.
  Activation is one command, printed by the installer:
  `git config core.hooksPath .githooks`.

### Upgrade notes

- Re-run the installer to receive `.githooks/pre-commit`, then activate
  it once: `git config core.hooksPath .githooks`.

## [0.2.0] — 2026-08-05

### Added

- **Adopt mode** in `tools/srs_init.py`: installing into a project that
  already has an SRS-shaped specification. The spec is validated against
  the proposed configuration before anything changes; on failure the
  target is left untouched (exit 3). Only tooling and missing service
  files are installed. `--mode fresh|adopt` overrides detection.
- Upgrade mode prints the checker version transition
  (`checker 0.1.0 → 0.2.0`) and the relevant CHANGELOG upgrade notes.
- `srs-harvest` skill — mine a specification from an existing codebase
  as approved batches of `draft` requirements; shipped to targets.
- Lifecycle rule: a `draft` recorded for already-existing behavior is
  approved straight into `implemented`/`partial`.

### Changed

- In **upgrade and adopt** modes the checker and the skills refresh
  without `--force`. Fresh mode stays conservative; precious files
  (CI config, CLAUDE.md/AGENTS.md, .gitattributes) still require
  `--force` plus the SRS-DD marker.

### Upgrade notes

- Re-running the installer on an initialized target now refreshes
  `tools/srs_check.py` and the skills automatically — review the
  `refreshed:` list in its output.
- After upgrading, commit the refreshed tooling together with the
  regenerated `specs/90-traceability.md`, or the CI freshness gate will
  fail on the next push.

## [0.1.0] — 2026-08-05

First release of SRS-DD as a reusable framework.

### Added

- Normative specification rules (`specs/README.md`): ISO/IEC/IEEE 29148
  structure, EARS phrasing, MADR decision log; requirement lifecycle with
  `draft`; annotations (`implements:` / `verifies:`); baselines; project
  configuration with a language-independent lexicon.
- `tools/srs_check.py` — integrity checker and traceability generator:
  config-driven areas, roots, and lexicon; annotation cross-checking;
  `--strict` and `--no-write` flags.
- `tools/srs_init.py` — installer for target repositories with
  interactive and non-interactive modes, collision handling, and an
  upgrade mode for already-initialized targets.
- Agent integration: `AGENTS.md` (canonical), thin `CLAUDE.md`, skills
  `srs`, `srs-new`, `srs-init`, `srs-audit`.
- CI templates in `ci/` (GitHub Actions, GitLab CI) with a
  traceability-freshness gate; `.gitattributes` pinning the matrix to LF.
- `specs/constitution.md` v1.1.0 — standing engineering principles.

### Upgrade notes

- After updating `tools/srs_check.py` in a target project, regenerate
  `specs/90-traceability.md`: the status table gained `draft` and its
  rows now follow lifecycle order.
