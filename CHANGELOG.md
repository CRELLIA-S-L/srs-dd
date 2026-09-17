# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions are framework releases, tagged `vX.Y.Z`; the same number is embedded in `tools/srs_parse.py` as `__version__`, re-exported by both checkers, and stamped into every file the installer writes.

<!-- Format contract, relied upon by tools/srs_init.py when it reports an
     upgrade: a version section starts with `## [X.Y.Z]`; the lines after a `### <heading>` heading, up to the next `##`/`###`, belong to it.
     `### Upgrade notes` is printed in full; `### Added` and `### Changed` are printed one line per `- ` entry, so keep every entry's first sentence self-contained.
     Keep that shape. -->

## [0.16.0] — 2026-09-04

### Added

- The architecture layer is an optional register in `arch/`. Its records name the parts the system is cut into, the files each one carries and the requirements it holds; it is a sibling of `specs/` with its own standard, configuration and checker, and `ADR-0023` records why it is not a sixth requirement type and not an external model.
- `tools/srs_arch.py` reads that layer against the specification. It reports a file a requirement names and no element carries, a realized requirement no element carries, an element that answers to nothing, and an import crossing into another element the model does not declare; it regenerates `arch/90-map.md` on the same terms the grounds dashboard is regenerated.
- `srs_arch.py --drivers` ranks the requirements that drive structure. Incoming links decide the order and the type breaks ties, and it prints the few that lead as candidates for a person to accept.
- `srs_init.py --arch yes|no` installs the layer or declines it. `srs_upgrade.py --arch yes` adds it to a project that has none, and an upgrade refreshes the layer only where it already is.
- `srs_view.py --cite <ID>…` prints a citation ready to paste. It gives the identifier, the title, the file and the status, for several identifiers in one call.
- The `srs-arch` skill travels with the layer. The `srs` procedure gains a step beside the one it has for the grounds register: before changing a file, read which element carries it.
- A project's gate compares its architecture map. The CI templates regenerate `arch/90-map.md` and fail when the committed copy differs from it, on the same terms the grounds dashboard is already compared, and the step is inert in a project that keeps no layer; until now the map was generated and committed in every target and looked at again by nobody (`FR-ARCH-170`).
- Twenty-eight requirements in all, none removed. They are the `ARCH` area, `FR-VIEW-240`, `INV-SPEC-070` and `FR-INIT-200`.

### Changed

- A citation of a requirement carries its title, its file and its status. The line number is out of it, because a line moves with the next edit above it while the file and the status keep, and `srs_view.py --cite` prints the whole thing rather than leaving it to be typed (`FR-SKILL-200`).
- `specs/README.md` no longer tells a plan to name requirements by number. That instruction sat closer to the writing than the rule asking for the full name, so the rule lost every time; the `srs` procedure changed with it.
- Markdown written by hand is no longer wrapped to a width. A line breaks where the meaning breaks and never inside a sentence, because the renderer does the wrapping (`INV-SPEC-070`), and the specification, the guides and the standards were reflowed accordingly.
- A statement counts as different by its words, not by where its lines end. Comparing the raw text made that reflow report every statement as changed, which is the reading `srs_view.py --diff` exists to spare its reader (`FR-VIEW-050`).
- Three requirements now name every file they govern. `NFR-SPEC-010`, `CON-SPEC-030` and `FR-SKILL-020` quantify over all tools, all commands and all skills, and their `code` fields had stopped at the files that existed when each sentence was written — so asking what governed the architecture checker, its procedure or its standard answered as though no such rule reached them.
- Two statements name the architecture layer where the code already did. `FR-INIT-060` counts its standard among the files an upgrade replaces only with `--force`, and `FR-SKILL-100` names its checker among the checks a finished change calls for.
- `FR-CHK-100` names two configuration faults it always refused. An empty list where the checker needs one, and an area name no identifier could carry, both exited 2 already; the suite asserted the second of them, which made it a test proving what the specification did not say.
- The citation rule reaches every procedure that reports requirements. `srs-new`, `srs-harvest`, `srs-baseline`, `srs-bet`, `srs-arch` and `srs-release` now name what they found the way `AGENTS.md` asks; the rule bound them all along, and only the three carrying a reminder obeyed it. In `srs-release` it binds the difference shown to the maintainer and not the changelog section, where a citation would break the one-line print of an upgrade and record a status that moves (`FR-SKILL-200`).
- The overview, the standards and the landing page say what ships now. Each enumerated the parts of the system and had fallen behind the layer, the two suites it added and the requirement count; the overview names its commands rather than counting them.
- An upgrade refreshes the agent guides under `--force`. They were listed among the files it replaces with that flag and were replaced by nothing, because a guide is filled in rather than copied and an upgrade had no answers to fill it with; `specs/srs-config.json` now records the project's name beside the width it already kept, and a project installed before that falls back to its directory (`FR-INIT-200`).
- The pre-commit report names the bets on every file a commit changes. A requirement owns the files its `code` and `tests` fields name, and somebody changing one of those is exactly who the report was written for; it spoke only when a specification file moved, which is not the commit that matters (`FR-GND-310`).
- `FR-ARCH-060` says which requirements its rule speaks for. It reports a file no element carries for a requirement that is `implemented` or `partial`, which is what the checker filtered on from its first commit while the sentence left it out — and a rule narrower than its sentence fires correctly on everything anybody tries.
- The upgrade procedure says which standards it leaves alone. Its list of untouched files was written before the standards became precious in 0.14.0, so a maintainer who had edited one was never told that `--force` would replace it.

### Upgrade notes

- Your `AGENTS.md` and `CLAUDE.md` are now replaced by `--force`, and were not before. The flag always said so and the installer always declined; if you have edited either, run the upgrade without the flag first and read what it lists as skipped, and use the guided merge the `srs-init` skill offers rather than the flag. That is also how to take the new form of a citation, which changed in the guides this release ships.
- The map check does not reach a project that already has the layer. The CI template is a file a project may have edited, so an upgrade refreshes it only with `--force` (`FR-INIT-060`); to take the check, re-run the installer with `--force`, or copy the `arch/arch-config.json` block out of `ci/github-workflow.yml` or `ci/gitlab-ci.yml` by hand.
- The architecture layer is not added by an upgrade. To install it, run the upgrade with `--arch yes`; to be rid of one, delete `arch/`, `tools/srs_arch.py` and the `srs-arch` skill, and nothing else refers to them.
- A project that installs the layer starts with no elements and a map of none, which its own checker accepts. The ownership rule reports every file a requirement names until elements are written, so `arch/arch-config.json` is where that rule is lowered while the parts are being described.
- Markdown line width is this framework's own rule and reaches no target. Nothing reflows a project's files, and no gate looks at markdown in a target or here.

## [0.15.1] — 2026-08-31

### Changed

- The guides and procedures the framework ships cite no requirement number.
  Where one was illustrated with a number the shape `FR-<AREA>-<NNN>` stands instead: a project whose first area is `CORE` — the one a fresh install offers — could look `FR-CORE-020` up and find a requirement of its own under a title the guide never meant.
- `CON-SPEC-020` no longer qualifies what may not travel by area.
  What it forbids is a citation of any requirement identifier, not only one of this framework's, and it says cite rather than contain; `FR-INIT-180` drops the same qualifier, which is what the installer's annotation removal always did.

### Fixed

- The advisory job that reads the example project takes its list of files to copy from the installer instead of a hand-written pair.
  That pair went stale when the checker was split from its parser, and the job had been failing on the missing file rather than on the specification it exists to read.
- The check that guards the payload reaches any area in the guides and skills it walks, and walks a target installed with both CI templates and the grounds register — neither was examined before, and the templates become a project's pipeline and hook.
- `CONTRIBUTING.md` no longer says a leaked identifier fails a stranger's checker, which it does not, and no longer tells contributors to keep annotations out of the shipped tooling, which `ADR-0022` reversed.

## [0.15.0] — 2026-08-28

### Added

- A grounds register records what the requirements stand on.
  It is optional, and a project that declines it receives none of what follows.
  `grounds/` holds five kinds of record — an ideology says who the product is for, a frame says what it will not do for anyone, a hypothesis says something about the world that could turn out false, a bet joins a requirement to the hypotheses it rests on, and a declaration says a requirement rests on nothing and why.
  `tools/srs_grounds.py` checks them and regenerates `grounds/90-dashboard.md`; the `srs-bet` skill is the procedure.
- A hypothesis is judged against its own arithmetic rather than by eye.
  The threshold is declared before the first measurement in a fixed grammar, and a verdict that disagrees with what the numbers compel is reported — including a value that crosses the threshold by less than a sample of that size can miss by, which has refuted nothing.
- The register reads its own history, not only its files.
  A threshold moved after the first measurement was recorded under it, an evidence row that once existed and no longer does, and a widening of what may move an ideology are each reported from the git history, and a history that cannot be read says so instead of passing in silence.
- A specification can be dated from its own history.
  `tools/srs_dates.py` fills the `created` field of every requirement that lacks one, reading the date from the commit that introduced it, and the installer offers this to a project adopting the framework with an undated specification.
- The rendered page explains its own notation.
  The verification method is drawn as a single letter and the page now says which letter means what, both in a legend above the list and on the mark itself.
- Authoring a requirement asks what it stands on.
  Where the project carries the register, the `srs-new` dialog asks whether a hypothesis already recorded carries the new requirement, whether it rests on none, or neither — and never invents a hypothesis to fill the gap.

### Changed

- The bet's `served_by_any` key is gone before it was ever released.
  It was declared in the standard and asked for by the procedure, and nothing read it — not the checker, not a requirement, not a test.
  The format may gain keys and may not lose them, so this was the last release that could take it back.

- The record shape is read by one parser instead of copied.
  `tools/srs_parse.py` is a new file, and `tools/srs_check.py`, `tools/srs_grounds.py` and `tools/srs_dates.py` all import it; none of the three works without it.
- The framework's version has one home.
  It lives in `tools/srs_parse.py`, the one file both checkers must have beside them, and each re-exports it;
  the release command bumps that file.
  The grounds checker used to carry a second copy that nothing bumped, which would have announced 0.14.0 from this release onwards.
- The tooling ships without this framework's identifiers.
  Its `implements:`/`verifies:` annotations are how this repository checks its requirements against its code, and the installer now removes them as it copies, leaving each line in place so line numbers still match.
  A project that declared one of this framework's requirement areas used to receive an annotation resolving to its own requirement under that number.
- An install can record the line width a project's code follows.
  The setup procedure reads it out of whatever the project already states it in — an `.editorconfig`, a formatter's configuration, a contributing guide — and confirms it before passing it on; the installer writes it to `line_width` in the configuration and names it in the agent guide.
  A project that states nothing gets no key and no line, and no gate checks source formatting: that is a linter's job, not this framework's.
- A run that could not read the history says so.
  One rule compares baseline tags against the log, and outside a repository — or with no git on the path — it could not run at all while the run still reported no errors.
  The checker now prints a note naming what went unchecked.
  A repository with no tags stays silent, because that answers the question rather than leaving it unasked.
- A hypothesis is put against the frames before it is admitted.
  The layer recorded frames and never applied them: nothing connected a frame to a hypothesis, so a claim a frame forbids could be recorded, staked on and built against in silence, and no procedure ever wrote a refusal into a frame's journal.
  The `srs-bet` dialog now asks, and a refusal takes a row in that frame's journal.
- Every copied tool says which release it came from.
  The version is stamped in the header of each one, so a tree copied by hand or left half-upgraded can be read rather than guessed at.
- The page compares every field the terminal's `--diff` does.
  Three of them — `conflicts_with`, `superseded_by` and `exempt` — were compared by the command and missing from the snapshots the page carries, so a pair of baselines differing in one of those alone read as changed in the terminal and unchanged on the page.
  The snapshots grow by three mostly empty fields and the two answers agree again.
- The graph's note names what was left out, not only how many.
  Past the node limit the page said how many nodes went undrawn and nothing about which, while the cut runs down the sorted identifiers and takes whole families at once — on this repository's own page every interface, every invariant and every non-functional requirement.
  The note now lists each family with its count.

### Fixed

- Freezing a baseline and cutting a release refused on different terms while every document said they refused on the same ones.
  The baseline command runs the checker plainly and the release runs it strictly, so a project carrying warnings can freeze and cannot ship; the two requirements, the Baselines section of the specification standard and both procedures now say which is which.
  Neither command changed.
- Three sentences in the specification standard stated a checker rule narrower than it fires.
  An empty `code` field is reported for `partial` as well as `implemented`; `superseded_by` is reported on anything but a `superseded` requirement, not only where a replacement is missing; and an annotation pointing at a withdrawn requirement is warned about as one pointing at a superseded requirement is.
  The rules were already doing all three.

### Upgrade notes

- The register standard says where the names of its rules come from, the way the specification standard already did: the checker lists them when you name one it does not know.
- The register standard states two limits it used to leave silent, and both are limits rather than changes: how a hypothesis is measured lives in its prose and no rule reads it, and where a measurement came from is not recorded at all — so several hypotheses measured off one stream read as well grounded as several measured separately, and only a person knows the difference.

- Upgrading rewrites more of `tools/` than a version bump would suggest.
  Every tool loses this framework's `implements:`/`verifies:` comments and gains a version stamp in its header, and the comments that cited a requirement by number now say the same thing in words.
  No executable line changed, and the removal keeps each annotation's line, so a traceback still names what it named in the framework's own copy of that release.
- The register is not added by upgrading.
  `python3 tools/srs_upgrade.py` refreshes the tooling and leaves your project exactly as opted-out as it was; `python3 tools/srs_upgrade.py --grounds yes` adds `grounds/`, its configuration and the `srs-bet` skill.
  Nothing about the specification changes either way, and no rule of this release requires a requirement to be named by a bet — that absence is the register's most useful reading and is protected rather than filled.
- `tools/srs_parse.py` must be present.
  Three of the shipped tools import it — the specification checker, the grounds checker and the dating command — so a project that copies tools by hand, one file at a time, has one more file to copy than in 0.14.0.
- Where you take the register, its findings are warnings and a `--strict` gate fails on them.
  Every rule name is a key under `rules` in `grounds/grounds-config.json` and can be lowered to `report` or silenced with `off`, the same way `specs/srs-config.json` tunes the specification checker.
- The corrected specification standard arrives only with `--force`.
  `specs/README.md` is one of the files an upgrade leaves alone unless asked, so a project keeps its own copy — including the Baselines paragraph this release corrected — until `python3 tools/srs_upgrade.py --yes --force` refreshes it, and then only where that copy still carries its `SRS-DD-<version>` marker.
  The skills are refreshed either way, so for one cycle the baseline procedure points at a paragraph the project has not received yet.

## [0.14.0] — 2026-08-18

### Added

- The annotation check works in both directions now.
  A file a requirement names in its `code` or `tests` field is expected to carry `implements:`
  or `verifies:` for that requirement, and a file neither the specification nor an annotation claims is reported by name.
  Both are warnings, `annotation-unpaired` and `annotation-absent`, so a project decides when to take the queue (FR-CHK-200, FR-CHK-210, ADR-0014).
- A path a requirement names is checked to exist by a rule of its own.
  It was stated inside the rule that obliges a realized requirement to name something, and a stale path turns the traceability matrix into fiction whether or not the field is empty (FR-CHK-055).
- The rendered page lists what outlived a cancelled requirement.
  A live requirement still deriving from it, a file its `code` field named that nothing live claims now, an annotation still naming it: three rules report these one line at a time to whoever ran the checker, and the reviewer being asked to approve the cancellation reads the page (FR-VIEW-210).
- The JSON the viewer emits is a published interface now.
  What is promised is every requirement with the fields of its block, where it was read from, and the reverse links computed for it; two suites already parsed it, one of them the guard that no requirement of this framework leaks into a target (IF-VIEW-010).
- Narrowing the list of requirements is stated rather than implemented.
  The viewer has filtered over metadata and over text since it was written, which made it the one behaviour here that could have been deleted without a requirement noticing (FR-VIEW-220).
- A rule name the checker has published keeps its meaning.
  It is never renamed and never given to a different rule: those names are a vocabulary other people's `specs/srs-config.json` and `exempt` fields are written in, and a rename breaks them by refusing to start (IF-SPEC-020).
- A requirement states exactly one obligation.
  The mechanical half is the two-verb rule the checker already enforces; the half no script reaches — one verb carrying a list of separable objects — is held by whoever writes and reviews a statement (INV-SPEC-060).
- A suite asserting something is absent has to be able to fail (FR-CI-080).
- A suite working on a target leaves its own repository's git state alone.
  What it creates under `/tmp` is its business; the repository it was started from is not (FR-CI-090).
- An observation is reported as a finding only once it is one.
  The procedure reporting it establishes what follows and says so with the finding, or drops it: an agent reading a specification notices far more than matters, and a list that mixes the two is skimmed entirely (FR-SKILL-170).

### Changed

- The installer refreshes the standard, `specs/README.md`, under `--force`.
  It moves with the framework now instead of staying at whatever version installed it, and it joins the files a project may already own rather than the tooling, because adopt deliberately keeps a project's own copy and refreshing without a flag would undo that at the first upgrade (FR-INIT-060).
- The marker on an installed file now carries the framework version.
  `SRS-DD-<version>`, matched as a pattern, because the bare name turns up in ordinary prose (FR-INIT-060).
- A `partial` requirement with an empty `code` field is now an error.
  It is what `implemented` already was: the two statuses differ by how much is built, not by whether anything is (FR-CHK-050).
- A cancelled requirement no longer hides the code its `code` field named.
  The proportion of source files no requirement references counts only requirements that have not been cancelled (FR-VIEW-040).
- The checker's exit codes state the condition for exiting 0. It is no error, and under `--strict` no warning either — which was true before and left implied (IF-CI-020).
- Links are recorded in one direction between two requirements.
  That is what the rule always meant and not what it said (INV-SPEC-020).
- The skills point at the standard rather than restating it.
  The requirement template went out of the `srs` skill, where it was a second copy of the markup rules that nothing referenced (FR-SKILL-020).
- The standard-library-only promise is made of every Python tool.
  It names all six, the three commands added since it was written included (NFR-SPEC-010).

### Fixed

- Ten assertions in the test suites could not fail.
  Each was written `! grep -q PATTERN file`, and POSIX exempts a command negated with `!`
  from `set -e`, so the suite walked past whether the pattern was there — including the checks that `--up` prints no downward subtree, that a shallow clone offers no baseline picker, and that a refused baseline left no row behind (FR-CI-080).
- The suites no longer write into the index of the commit being prepared.
  A pre-commit hook exports `GIT_INDEX_FILE` and `GIT_DIR`, every suite inherited them, and a `git add -A` meant for a throwaway target under `/tmp` staged that target's paths into this repository's commit; `git commit` then answered "invalid object … Error building trees" with no hint why (FR-CI-090).

### Upgrade notes

- Two new warnings may report on your project the first time you upgrade.
  `annotation-unpaired` names a requirement whose `code` or `tests` field points at a file that does not carry `implements:` or `verifies:` for it; `annotation-absent` names a file under your code or test roots that no requirement references and that claims nothing itself.
  Both are warnings, so only a `--strict` gate fails on them.
  Lower or silence either in `specs/srs-config.json` under `rules`, and excuse `annotation-unpaired` for one requirement with `exempt: [annotation-unpaired]` in its own block.
  A project that adopted the framework starts with `annotation-absent` set to `off`, because that rule fires on every unclaimed file in a codebase of thousands; switching it on is what finishing the adoption means.
- A requirement with status `partial` and an empty `code` field now fails the checker where it used to pass.
  Only `implemented` was an error before.
  Fill the field with the files carrying the part that is built, or move the requirement to `deferred`, which is the status for approved and not begun.
- `--force` does not recognize the files it installed in a project set up before this release, and says so: `.gitattributes`, `.githooks/pre-commit` and `specs/README.md` are reported as "no SRS-DD marker — not ours, merge manually" and left alone.
  The marker the installer looks for now carries a version and the files earlier releases wrote carry the bare name.
  To hand those files back: in `.gitattributes` and in `.githooks/pre-commit`, change `SRS-DD` to `SRS-DD-0.14.0` in the comment on the first lines; in `specs/README.md`, which earlier releases installed with no marker at all, insert `<!-- SRS-DD-0.14.0 — installed by the framework; --force overwrites local edits -->` as the second line.
  `--force` refreshes all three from then on and keeps the marker current by itself.
  Check what a refresh would overwrite with `--dry-run` first if you have edited any of them.

## [0.13.0] — 2026-08-12

### Added

- The metadata block declares which keys are required.
  `status` and `verification` are; everything else is optional, and a key the checker does not know stays a warning — which is what lets a later version add one without breaking a specification written against an earlier one (IF-SPEC-010, FR-CHK-170).
- The `srs-check` skill names and runs the checks a change calls for.
  It reads the `verification` method and the `tests` field of every requirement the change touched, offers exactly those, and says in words what a person still has to look at (FR-SKILL-100).
- The `srs-page` skill renders the specification and opens it.
  It also says what the commands do not: the file is self-contained and can be sent to somebody, `--repo-url` is what makes its links to the code work, and CI may already publish the same page (FR-SKILL-110).
- Authoring a requirement and building it are two acts now.
  `srs-new` ends at the written requirement and the decision the discussion settled, and `srs` gained a second way in — from an approved requirement nobody has built yet, not only from a file about to change (FR-SKILL-090, ADR-0006).
- Whoever writes a statement judges what no checker reaches.
  One capability, verifiable, unambiguous, about behavior rather than implementation — no word list can do it, because what reads as vague depends on the sentence and a specification may be written in any language.
  It is asked of every procedure that puts a statement in the file, not only the authoring dialog: `srs-harvest` judges a mined batch before showing it, where a sentence read off an `if` sounds precise and says nothing testable, and `srs` judges a statement it rewords while closing the loop, which is where a repair quietly grows a second capability (FR-SKILL-120).
- The authoring dialog checks the verification method against the statement.
  `T` declared over a sentence no test could assert used to surface much later, when the requirement was built and somebody had to write a test that could not be written; the sentence and the method are on the table together in one step, which is where the question costs nothing (FR-SKILL-140).
- The baseline procedure offers an audit before it freezes.
  Scoped to the requirements the diff names, because auditing everything at every baseline is the step people stop taking (FR-SKILL-130).
- The graph draws every kind of link, told apart by its own form.
  Layers still come from `derives_from` and `refines` alone — a layer claims a level of abstraction, and a requirement must not sink because something it needs sits above it (FR-VIEW-160, ADR-0010).
- The graph can be narrowed to one requirement's surroundings.
  Pick a root and a distance, and the rest is hidden; a drawing of everything is the one view a specification of any size cannot use (FR-VIEW-150).
- `srs_view.py --open` renders the page and opens it.
  It implies `--html` when no path is given, so reading the specification is one word (FR-VIEW-140).
- A requirement that says it is verified by test and lists none is reported.
  Only where the method is `T` — one verified by inspection or analysis has no test by design, and reporting those would bury the ones that mean something (FR-CHK-140).
- A requirement no link touches is reported.
  Total isolation is the one case where a forgotten link shows: the checker can prove that what is written resolves, never that something was left out (FR-CHK-150).
- What a rule costs is the project's to set.
  Every rule short of an error now carries a name, and `rules` in `specs/srs-config.json` lowers one to a note that never fails `--strict`, or silences it; a single requirement excuses itself with `exempt: [rule-name]` in its own block, where the excuse is diffed in review and shows on the page (FR-CHK-160, ADR-0008).
- A retired key is reported by name.
  Where a later version of the format renames or withdraws one, the checker says which version did it and what replaced it; the framework never rewrites your specification, it tells you what to change (FR-CHK-180, ADR-0009).
- A requirement is reachable from every view of the page.
  Links in the dashboard and in a baseline comparison, and nodes in the graph, now open the requirement they name — switching to the view that renders it and clearing a filter that would hide it (FR-VIEW-130).
- A requirement can be withdrawn as well as replaced.
  `withdrawn` is the status for one cancelled with nothing to take its place: the record and its number stay dead as they do for `superseded`, and no successor is named or expected (INV-SPEC-050).
  Until now the only way out of the lifecycle demanded a replacement, so a dropped requirement stayed `deferred`, where it reads as approved and merely late.
- A requirement left standing on a withdrawn one is reported.
  Withdrawing is the one edit that breaks requirements it never touches, so the checker names both ends and what the dependant would have to become (FR-CHK-190).
  `conflicts_with` is not counted — a divergence from a withdrawn requirement has lost nothing it stood on.
- A kind of link can be left out of the graph.
  Every swatch in the link legend is a control now: press it and that relation goes from the drawing, wherever it runs.
  Drawing all four and subtracting is what FR-VIEW-160 argued for, and the subtracting half had never been built — a root and a radius, which cuts by distance rather than by kind, had been taken to satisfy it (FR-VIEW-150).
- The audit counts a test as proof only if it could fail.
  For each case it would call covered it names the change to the code that would turn that test red, because reading a test says what it mentions and not what it would catch.
  A statement carrying two obligations with a suite that exercises one, or a rule firing on several fields with a fixture for one, both read as covered and both stay green when the behaviour is deleted (FR-SKILL-160).
  Named, not run — the audit executes nothing.
- The `srs` skill gained a withdrawal procedure.
  It shows what points at the requirement, grouped by which field breaks, and offers eight ways to settle each dependant before the status changes (FR-SKILL-150, ADR-0013).

### Changed

- Both approval warnings now name the requirement they are about.
  A draft carrying code (FR-CHK-070) and a realized requirement resting on a draft (FR-CHK-075) were identified by file and line only — enough to open the file, not enough to grep a pipeline log or to cite in a plan that references numbers, and a line number moves with the next edit above it.
  FR-CHK-075 named the draft being rested on but not the requirement resting on it, so the one that had to change was the one the reader could not name.
- The two approval warnings are two requirements.
  FR-CHK-070 keeps the draft carrying code; a realized requirement resting on a draft is now FR-CHK-075. One statement covering both is why the second had no fixture while the first had two — the requirement read as verified because half of it was.
- The graph is grouped by area instead of layered by derivation.
  A column is an area and a row is a requirement's number, so a line crossing columns is a link that leaves its area; this specification's drawing goes from 8825 by 179 — a ribbon in which a node fitted to a screen is thirteen pixels wide — to about 1005 by 956. Sixty-five of its eighty-seven requirements have no derivation parent, so the axis the layers claimed was never there (FR-VIEW-060, ADR-0012, superseding ADR-0010).
- A node in the graph shows its status in colour, with a legend.
  The class had been on every node since the graph was drawn and a neutral stroke in the stylesheet painted over it, so the one view that could have shown the statuses was the one that did not (FR-VIEW-180).
- Dragging a node is now collapsing an area.
  A position means membership of an area and a place in its ordering, so a dragged node is a node lying about where it belongs; clicking a column's name folds it away, which is what pulling a node aside was for (FR-VIEW-110).
- The graph lights a node's links on hover, not on click.
  That leaves the click free to open the requirement the node names (FR-VIEW-110, FR-VIEW-130).

### Fixed

- The filters work again.
  The graph's transform function and the filters' were both called `apply`, and a function declared inside a block is also assigned to the enclosing function's binding of the same name — so every click on a status, type or area chip moved the graph a little and filtered nothing.
  Silently, in every page this framework has rendered.
- A wide layer is no longer folded into rows.
  Wrapping put the eleventh node under the first, nowhere near its parent, discarding the only thing the ordering pass computes; the canvas pans and zooms, so the drawing is free to be wide instead.
- The graph's node order is settled by sweeping in both directions and swapping adjacent pairs, as `dot` does.
  One downward sweep left every lower layer at the mercy of whatever the upper one happened to be.
- The rendered page is a text file again.
  Its comparison script joined values on a unicode escape for NUL, written for JavaScript and eaten by the Python string that carries the script, so every page shipped with real NUL bytes in it — enough for grep, diff and an editor to call it binary.
- Omitting a required key is answered by naming it.
  `verification` left out used to be reported as `method '' is not one of T/D/I/A`, which describes the symptom and hides the cause (FR-CHK-170).
- Clicking a graph node does something again.
  Cancelling `pointerdown` suppressed the compatibility mouse events, and with them every click the graph relied on, so neither the highlight nor the jump to a requirement had been firing (FR-VIEW-110).

### Upgrade notes

- Two skills arrive with this upgrade, `srs-check` and `srs-page`.
  Ask an agent to check a finished change or to show you the specification, and they are what answers.
- Two new rules may report on your specification the first time you upgrade:
  a requirement claiming `verification: T` with an empty `tests` field, and one no link touches.
  Both are warnings, so only a `--strict` gate fails on them.
  Fill the field or the link where the report is right, and where it is not, lower the rule in `specs/srs-config.json` or excuse the one requirement with `exempt: [test-missing]` or `exempt: [unlinked]` in its own block.
- A cancelled requirement is no longer reported as touching no link.
  The `unlinked` rule spared `superseded` only by accident — its `superseded_by` counts as a link, and one is mandatory — and would have fired on every `withdrawn` requirement, turning a `--strict` gate red for having cancelled something nothing pointed at.
  Both are outside the rule now, on purpose (FR-CHK-150).
  Nothing changes for a specification you already have: the only case the rule could newly reach arrives with this release.
- One new rule may report on your specification: a requirement that derives from, depends on or refines a `withdrawn` one (`rests-on-withdrawn`).
  It is a warning, so only a `--strict` gate fails on it, and like every other it can be lowered in `specs/srs-config.json` or excused per requirement with `exempt: [rests-on-withdrawn]`.
- The `withdrawn` status arrives with this upgrade, and upgrading is what has to come first.
  A status the checker does not know is a hard error, not a warning, so a specification that uses `withdrawn` is rejected outright by any older copy of `srs_check.py` — including one still running in a pipeline that was not upgraded with your working copy.
  Nothing you already have changes meaning: `superseded` keeps demanding its `superseded_by`, and every existing requirement is untouched.

## [0.11.1] — 2026-08-09

### Changed

- The CI templates check out the whole history.
  The page compares baselines by reading the commits they name, and both templates asked for the shallow clone their platform gives by default.

### Fixed

- A baseline is no longer reported from a checkout that cannot hold it.
  Given a shallow clone — or a history that was squashed or imported — `srs_view.py` answered every baseline with the one commit it had, so the page showed six baselines agreeing that nothing had ever changed between any two of them; it now names only the states its repository actually holds, and says how many it could not reach (FR-VIEW-090, INV-SPEC-040).
- The page reads the current baseline from the log rather than from the snapshots it managed to load, so it names one even where the history to compare against is absent (FR-VIEW-090).

### Upgrade notes

- Your rendered page shows baselines only where CI checks out the whole history.
  Refresh the shipped CI template with `python3 tools/srs_upgrade.py --force`, or add it by hand: `fetch-depth: 0` under `actions/checkout` on GitHub, `GIT_DEPTH: 0` in the job's `variables:`
  on GitLab.
- If your page has been showing baselines that all report no changes, that is this defect and not your specification.

## [0.11.0] — 2026-08-09

### Added

- `tools/srs_baseline.py` freezes the specification with one command.
  It writes the row into `specs/92-baselines.md` — version, date, and what changed since the previous baseline — and stops there; it ships with the framework, because every project baselines its own specification (FR-SPEC-010).

- The `srs-baseline` skill installs into every project.
  It is the way to ask for a baseline by name: it reads what changed, proposes the version for you to confirm, runs the command, and hands back the commit (FR-SKILL-080).

### Changed

- A baseline is the row in the log, not the tag.
  The commit that adds the row is the baseline, a `spec/vX.Y.Z` tag is an optional bookmark, and where there is none the baseline is found by that commit (INV-SPEC-040).
- No command commits, tags or pushes any more.
  `srs_release.py` and `srs_baseline.py` prepare files and report what to commit, so neither needs a console git set up (CON-SPEC-030).
- `tools/srs_release.py` cuts no baseline any more.
  It dates the changelog section, bumps the checker's version and stops; freezing the specification is its own command with its own number (FR-CI-070).
- `srs_view.py --diff` accepts a baseline version, not only a revision.
  Asked for `0.9.0` it finds that baseline whether or not anybody tagged it (FR-VIEW-050).

### Upgrade notes

- A release and a baseline are independent from now on (INV-SPEC-030): they need not share a number, neither implies the other, and one command each prepares them.
- `tools/srs_baseline.py` and the `srs-baseline` skill arrive with this upgrade.
  Ask an agent for a baseline, or run `python3 tools/srs_baseline.py X.Y.Z` yourself, then commit the row it writes — that commit is the baseline, and a `spec/v*` tag on it is optional from here on.
- Nothing in the framework runs `git commit` or `git tag` for you.
  If you drive git through an application rather than the console, the commands now stop where that application takes over.
- A `spec/v*` tag with no row in `specs/92-baselines.md` is no longer a baseline, and drops off the rendered page.
  The checker has been warning about exactly those tags; where your log fell behind them, `python3 tools/srs_baseline.py X.Y.Z` writes each missing row from the tagged revision, so nothing has to be retagged or deleted.

## [0.10.0]

### Added

- `tools/srs_release.py` cuts a release in one command.
  It dates the changelog section, bumps the checker's version, adds the baseline row, commits those files and creates both tags — refusing before it touches anything if the tree is dirty, the section is missing, a tag exists or the checker does not pass.
  It writes no prose and does not push (FR-CI-070).
- The `srs-release` procedure carries what the command will not decide.
  Which number the release takes is a claim about compatibility and belongs to the maintainer; the changelog section an agent may draft, provided it knows that the first sentence of every entry stands alone, because an upgrade prints that sentence and cuts the rest.
  Framework-only, like `srs-init` (FR-SKILL-070).
- `srs_view.py --baseline X.Y.Z` prints the baseline row, ready to paste.
  It carries the version, the date, the tag and what changed since the previous baseline.
  Four rows of this project's own log were reduced by hand from a matrix and a diff — mechanical work that invites a wrong count nobody would ever notice (FR-VIEW-120).

### Changed

- Closing the loop now includes re-reading the statement.
  The `srs` procedure asked for a requirement before the code and, at the end, only for bookkeeping — status, `code`, `tests` — so nothing ever asked whether the statement still described what had been built.
  A change that starts as a fix needs no new requirement, and that exemption covers whatever else is added along the way: it is how a control reached the rendered page with no statement mentioning it (FR-SKILL-010).
- The Baselines procedure in the standard now writes the row before the tag.
  Tagging first leaves the tag pointing at a state the log does not describe until a later commit fixes it — and that later commit is the one that gets forgotten, three times here.
  Written in this order there is no gap to forget.

### Fixed

- The graph now fills its panel.
  Its canvas used to be sized from the drawing, so a small specification got a postage stamp to drag nodes around in, and a node left it at the first tug; the panel is the canvas now, the drawing is fitted into it, and a reset control brings back whatever was dragged out of sight.
  The gestures convert screen pixels into the drawing's own units, which they never had to while an unstretched canvas made the two the same by accident — and zooming converts a point rather than a distance, so it also accounts for the margin a centred drawing leaves inside its panel.
  FR-VIEW-110 says both now: the graph fills its area, and the view can be returned to where it started.

### Upgrade notes

- An upgrade brings three things into a project.
  `tools/srs_view.py` gains `--baseline X.Y.Z`, which prints the row for your own baseline log.
  The `srs` skill gains a step: closing the loop now means re-reading the statement and asking whether it describes what you built.
  And the release command is framework-only — nothing of it is installed.
- What an upgrade does not bring is the standard itself: `specs/README.md` is yours once installed, and this release reordered its Baselines procedure to write the log row before the tag.
  Copy that paragraph over if you want the order that keeps a tag from ever pointing at a state the log does not describe; a project that keeps tagging first loses nothing but the guarantee.

## [0.9.0] — 2026-08-08

### Added

- The checker reports a `spec/vX.Y.Z` tag the baseline log has no row for.
  Cutting a baseline is a tag and a row, in that order and so in separate commits — the gap between them is where it gets forgotten, twice in this repository already.
  A warning, which `--strict` turns into a failed build; silent where git or the tags are absent (FR-CHK-130).
- The rendered page says which baseline it shows and what rendered it.
  A page lives at a stable address and outlives a dozen releases; a reader arriving from a bookmark could not tell a fresh one from a six-month-old one (FR-VIEW-090).
- The graph can be explored.
  Pan it, zoom around the pointer, pull a node aside with its edges following, and click one to light what it links to and what links to it while the rest dims.
  Written in the page's own script: the layout is layered, which is the right shape for a derivation DAG and not what a force layout gives, so a graph library would have been paid for in every reader's download and every installed project in exchange for panning (FR-VIEW-110).
- Nodes within a layer are ordered by the barycentre of what they derive from.
  Edges run down the page instead of across it — three crossings became none in this repository's own graph — and the order is still computed the same way on every run, so the page stays byte-identical.
- The page compares any two baselines.
  It carries a snapshot of the specification at each, so a reader picks a pair and sees what was added, removed, or changed — without a clone and without the network.
  Statements travel as fingerprints: a reworded statement shows up as a change, and the page does not grow by the length of the whole specification per baseline (FR-VIEW-100).

### Upgrade notes

- A project that already cut baselines will see a warning for every tag its `92-baselines.md` has no row for.
  That is the point; write the rows or, if the log is not how the project records them, the warning is harmless outside `--strict`.
- The page carries the specification at every baseline: the oldest in full, each later one as its change.
  Sixty requirements and three baselines cost 14 KB, and the cost grows with what changes rather than with the size of the specification.

## [0.8.0] — 2026-08-08

### Added

- `tools/srs_upgrade.py` ships with every project.
  One command picks up a new framework version: it fetches the framework the project was installed from, prints the version transition, the upgrade notes and the file list, asks, and then applies — removing what it fetched either way.
  No clone to keep around, no address to look up.
  `--ref` pins a release, `--from` uses a clone already on disk and never touches the network, `--yes` is required where there is no terminal to confirm at (FR-INIT-120, FR-INIT-130).
- The `srs-upgrade` skill ships with it.
  An agent working inside an installed project can now upgrade without being handed the framework's address — which until now it had to be, because nothing in a project mentioned upgrading at all (FR-SKILL-060).
- A fresh install ends with the first steps, agent procedures first.
  It names every skill it just installed and what each is for, then where the first requirement goes, what validates the specification, what renders it as a page, and how the framework is upgraded later — the two lines it printed before said none of that.
  The skills lead because they are the point: the framework exists so that code written with agents still has requirements behind it (FR-INIT-150).
- An upgrade reports what arrived, not only what to do about it.
  The versions it crosses are summarized one line per changelog entry, marked `+` for added and `~` for changed, above the upgrade notes and with a pointer to the full text.
  Somebody who upgrades across three versions used to learn nothing about a new tool or skill, and so never used it (FR-INIT-160).
- `framework_url` in `specs/srs-config.json` records where to upgrade from.
  It is written at install time from the installing clone's own remote, SSH rewritten to HTTPS.
  A fork or a mirror sends its projects back to itself; a project installed before this field existed falls back to the framework's canonical address (FR-INIT-140).

### Upgrade notes

- Upgrade once the old way — `python3 path/to/srs-dd/tools/srs_init.py path/to/your-project` — and from then on the project upgrades itself with `python3 tools/srs_upgrade.py`.
- That first upgrade does not add `framework_url` to your config: an upgrade never rewrites `specs/srs-config.json`.
  Without it the upgrader uses the framework's canonical address, which is right unless you install from a fork — in that case add the key by hand, pointing at your fork.

## [0.7.2] — 2026-08-08

### Added

- The specification is published: <https://crellia-s-l.github.io/srs-dd/>.
  The page is rendered on the default branch, only after the suites pass — a page is worth serving exactly when what it renders is valid — and its code links point at the commit it was built from rather than at a moving branch.
  FR-CI-040 is `implemented`.

### Changed

- Every GitHub Action moved to its current major: `checkout` v4 → v7, `setup-python` v5 → v7, `upload-artifact` v4 → v7, `configure-pages` v5 → v6, `upload-pages-artifact` v3 → v5, `deploy-pages` v4 → v5.
  GitHub already forces the Node 20 actions onto Node 24 and will stop doing so.
  `ci/github-workflow.yml` — the template installed into target projects — is bumped with them, including its commented Pages block.

### Upgrade notes

- If your project runs the `.github/workflows/srs.yml` this framework installed, its actions are on the retiring Node 20 runtime.
  That file is precious, so an upgrade will not touch it: refresh it with `--force`, or edit it by hand to `actions/checkout@v7`, `actions/setup-python@v7`, `actions/upload-artifact@v7`, `actions/configure-pages@v6`, `actions/upload-pages-artifact@v5`, `actions/deploy-pages@v5`.
  A GitLab project is unaffected.

## [0.7.1] — 2026-08-07

### Changed

- The repository moved to GitHub, and the canonical URLs moved with it:
  the clone command, and the raw entry point an agent is handed, now `raw.githubusercontent.com/CRELLIA-S-L/srs-dd/main/.claude/skills/srs-init/SKILL.md`.
  The `repo_url` in `specs/srs-config.json` moved too, so the code links on the rendered page point at the new host.
- `.github/workflows/srs.yml` is the framework's own pipeline;
  `.gitlab-ci.yml` is removed.
  The GitLab template for target projects (`ci/gitlab-ci.yml`) stays — a project on GitLab is still installed with one.
- `tools/ci_selftest.sh` no longer derives the local gate from a CI configuration.
  It parses the YAML of the pipeline and of the shipped templates, then runs `tests/*.sh` directly — the same scripts CI runs, so the two cannot drift apart, and the skip list it used to need is gone.
  Two consequences worth knowing: a machine without `ruby` now loses the YAML parse alone instead of skipping the whole run with a zero exit, and the parse happens first, because a suite fails routinely on a regenerated matrix that is not staged yet and that must not hide a broken template.
- FR-CI-040 stands at `partial`: the specification is rendered on every run and kept as a build artifact, but nothing serves it until GitHub Pages is enabled for the repository.
  The workflow carries the three steps for it, commented out — enabling them before the setting exists turns the pipeline red.

### Upgrade notes

- Nothing in a target changes: the checker, the viewer, the skills and the templates are byte-identical to 0.7.0 apart from the version string.
  Re-running the installer is optional.
- If you saved the old GitLab raw URL of `srs-init/SKILL.md` — in a runbook, a prompt, or an agent's memory — replace it with `https://raw.githubusercontent.com/CRELLIA-S-L/srs-dd/main/.claude/skills/srs-init/SKILL.md`.
  The old host no longer serves this project.

## [0.7.0] — 2026-08-07

### Added

- The framework now has a specification of its own: 54 requirements in `specs/` describing the checker, the viewer, the installer, the agent procedures and the gates, across six areas — `SPEC`, `CHK`, `VIEW`, `INIT`, `SKILL`, `CI`.
  Mined from the code with the `srs-harvest` procedure and approved in one batch.
  The repository is now an SRS-DD project like any other, which is also the framework's own example.
- `skeleton/` — the payload the installer copies into a target, separated from the framework's own files.
  Requirements about our tooling can no longer travel into somebody's project, which ART-070 of `specs/constitution.md` now states as a standing principle and `tests/installer-smoke.sh` asserts on every run.
- `tests/` — the four suites the pipeline runs (`spec-check`, `installer-smoke`, `adopt-smoke`, `view-smoke`), moved out of the CI configuration so requirements can cite them by path; the pipeline's jobs are one-line calls to them.
- A `pages` job renders this repository's own specification on the default branch.
- A worked example lives in its own repository, `srs-dd-example-urlshortener`: an ordinary product with eleven requirements, one of them superseded and kept for the record.
  The pipeline checks it as a downstream consumer (FR-CI-060, advisory), and its own CI runs against this framework's `main` — so a change that stops accepting a valid specification surfaces there rather than in a stranger's project.
- `docs/` — install, upgrade, agents, and a demonstration of a specification written in another language, moved out of the README.
- `specs/adr/` — five decisions that had been taken but never written down: the English-only framework with per-project lexicons, the committed traceability matrix, the standard-library-only rule, the `skeleton/` split, and the choice of a classic SRS over the agentic spec formats.

### Changed

- The root `AGENTS.md` and `CLAUDE.md` now describe the framework repository itself.
  The target-facing templates live in `skeleton/AGENTS.md` and `skeleton/CLAUDE.md`; the installer copies them from there.
  An agent handed this repository's URL no longer reads a guide meant for somebody else's project.
- `README.md` is a landing page: what the framework is for, what a requirement looks like, and how to install it.
  Reference material moved to `docs/`.
  The canonical clone and raw-skill URLs stay on it, marked with `canonical-url` comments.
- `specs/README.md` — the standard itself — remains the single canonical copy and still ships from `specs/`; only the starter files moved to `skeleton/`.
- The `srs-init` procedure now diffs a target's agent guides against `skeleton/`, not against this repository's root copies.
- The `srs-audit` procedure lists all four sections `--coverage` prints.

### Fixed

- `tools/srs_check.py` carried two example annotations in its own header comment without `srs-ignore`.
  In a target that put `tools` in `code_roots`, the shipped checker reported an error against itself (`annotation references unknown requirement FR-UI-020`).
  Both example lines are now exempt.
- `specs/README.md` pointed at "the repository README" for the viewer's modes — a file that does not exist in a target.
  It now points at `srs_view.py --help`.

### Upgrade notes

- Re-run the installer as usual; nothing in a target changes shape.
  The refreshed `tools/srs_check.py` no longer reports an annotation error against its own header comment, so a project that put `tools` in `code_roots` and worked around that can drop the workaround.
- If you script against a framework **clone**, note that the skeleton moved: `skeleton/specs/`, `skeleton/AGENTS.md`, `skeleton/CLAUDE.md`.
  Installed targets are unaffected.
- Two questions are recorded in `specs/91-open-issues.md` rather than silently resolved: the checker's individual rules have no rule-level tests, and an area holds at most 99 requirements because identifiers carry exactly three digits.

## [0.6.0] — 2026-08-06

### Added

- `--dry-run` for `tools/srs_init.py`: writes nothing at all and prints the created / refreshed / skipped list the real run would produce, in every mode.
  A maintainer — or an agent proposing an install — sees the change before it happens.
  In adopt mode the existing specification is not validated under `--dry-run` (that needs the checker running inside the target); the real run validates first and leaves the target byte-identical when validation fails.
- "Handing this to an agent" in `README.md`: the entry point for a coding agent given nothing but the repository URL.
  Points at `.claude/skills/srs-init/SKILL.md` as the procedure, gives the clone-and-run one-liner (`git` and `python3` are the only prerequisites), the release-pinning form, the exit codes, and states which two decisions — requirement areas and the lexicon — the agent must bring back to the maintainer instead of settling itself.

### Changed

- The pre-commit gate no longer assumes it owns `pre-commit`.
  The installer reads `core.hooksPath`, looks for an existing hook and for husky or the pre-commit framework, and when the repository already runs something it says so instead of advising the `core.hooksPath` switch — which would have silently disabled it.
  Your hook calls the gate (`sh .githooks/pre-commit || exit 1`); when `.githooks/pre-commit` is itself yours, the gate is installed beside it as `.githooks/pre-commit.srs-dd`.
  Existing hooks were never overwritten before either; what was missing was the advice not to shadow them.
- The README's first section says what the framework is for: codebases written with AI coding agents, without depending on one.
  The argument itself stays where it was, at the end.
- The `srs-init` skill runs the installer with `--dry-run` first and shows the file list before installing — the same approval shape it already required for the lexicon.

### Fixed

- `tools/srs_init.py` no longer writes `__pycache__` into the framework clone.
  A cached module is validated by modification time and size alone, so a version string that changes without changing the file size could be served stale — the installer then reported, and picked upgrade notes for, a version other than the one it was installing.

### Upgrade notes

- Nothing to do.
  `--dry-run` is a new flag; no existing command changes behavior, and the checker is untouched apart from its version string.
- If you were told to run `git config core.hooksPath .githooks` by an earlier version and your repository had a hook of its own, check `git config --get core.hooksPath` — that setting redirects every hook, so the old one has not been running since.

## [0.5.0] — 2026-08-06

### Added

- `tools/srs_view.py` — a viewer for the specification the checker validates, on the same dependency budget (standard library, Python ≥ 3.9) and sharing its parser.
  Read-only: it never writes into `specs/` and never gates anything.
  - Terminal: one requirement with every link resolved in both directions; `--list` with filters; `--code <path>` — which requirements describe a file, by the `code`/`tests` fields and by the file's own `implements:`/`verifies:` annotations; `--tree`;
    `--coverage`; `--json`.
  - `--html` — one self-contained page (default `.srs-site/index.html`, a directory that ignores itself): search, filters, clickable links, a status dashboard, and a layered graph of the derivation links.
    No CDN, no fonts, no network; opens from `file://`.
  - `--diff <rev>` — the working tree against a baseline revision, per requirement and per field, with a unified diff of the statement.
- `repo_url` in `specs/srs-config.json` (or `--repo-url`): the blob-URL prefix that turns `code` and `tests` paths into links to your forge.
  Viewer-only — the checker ignores keys it does not know.
- CI templates render the page: `spec-site` in `ci/gitlab-ci.yml` (one rename from GitLab Pages) and an artifact upload in `ci/github-workflow.yml` (a commented block switches it to Pages).

### Changed

- `tools/srs_check.py` gained `parse_text()` beside `parse_file()` and now records each requirement's rationale.
  Both are additive: the checks, the warnings and the generated matrix are unchanged byte-for-byte.

### Fixed

- A specification file that is not readable UTF-8 (an editor saving cp1251, say) is now reported as an error naming the file, in the checker, instead of ending the run with a decoding traceback.
  The viewer reports it as a problem and shows the remaining requirements.
- The installer ships only `.md`, `.json` and `.gitkeep` from `specs/` as skeleton content — anything a maintainer generates under `specs/` in their clone no longer travels into fresh targets.

### Upgrade notes

- Re-run the installer: `tools/srs_view.py` arrives beside the refreshed checker.
  The two must stay in step — the viewer uses the checker's parser and says so if it finds an older one.
- The new CI job and the `AGENTS.md` line about the viewer are in precious files: they reach an initialized project only with `--force` (CI) or a manual merge (`AGENTS.md`, or the guided `srs-init` upgrade).
  The skills carry the same advice and refresh on their own.
- `.srs-site/` writes a `.gitignore` that ignores the directory itself, so nothing needs adding to yours.

## [0.4.0] — 2026-08-05

### Added

- Planning in the `srs` skill: a "Planning multi-requirement work" section — dependency-ordered plans whose steps cite requirement IDs and constitution articles, `draft` requirements flagged as approval blockers (ART-020), plans kept in the conversation and never written into `specs/`.
- Test adequacy in the `srs-audit` skill: decompose an EARS statement into trigger, state, and constraint; derive the implied test cases (including property-style ones for quantified constraints); map them against the `tests` field and report gaps.
  `verification: T` only;
  on explicit request the skill may author the missing tests (the one exception to its read-only rule).
- Agent-doc merge in the `srs-init` skill: the guided upgrade now offers an LLM-performed merge of the target's `CLAUDE.md`/`AGENTS.md` with the framework versions — SRS-DD-marked files only, shown before applying, local content preserved.
- "Other coding agents" documentation: `AGENTS.md` is the cross-agent entry point (read natively by Cursor, Codex, Gemini CLI, Copilot);
  skills are plain markdown readable without a skill system; a two-line pointer snippet for tools that want their own rules file.

### Upgrade notes

- Re-run the installer — the enriched `srs` and `srs-audit` skills refresh automatically.
- `CLAUDE.md` and `AGENTS.md` are still not auto-refreshed: run the guided upgrade (`srs-init` skill, from a framework clone) to have the agent merge the doc changes, or merge manually.
  The framework copies gained a skills note (`AGENTS.md`) and updated skill mentions (`CLAUDE.md`).

## [0.3.0] — 2026-08-05

### Added

- Client pre-commit gate: the installer ships `ci/pre-commit` into targets as `.githooks/pre-commit` (all three modes, precious).
  It runs the checker and fails when the committed traceability matrix is stale — the same gate CI enforces, caught before the commit.
  Activation is one command, printed by the installer:
  `git config core.hooksPath .githooks`.

### Upgrade notes

- Re-run the installer to receive `.githooks/pre-commit`, then activate it once: `git config core.hooksPath .githooks`.

## [0.2.0] — 2026-08-05

### Added

- **Adopt mode** in `tools/srs_init.py`: installing into a project that already has an SRS-shaped specification.
  The spec is validated against the proposed configuration before anything changes; on failure the target is left untouched (exit 3).
  Only tooling and missing service files are installed.
  `--mode fresh|adopt` overrides detection.
- Upgrade mode prints the checker version transition (`checker 0.1.0 → 0.2.0`) and the relevant CHANGELOG upgrade notes.
- `srs-harvest` skill — mine a specification from an existing codebase as approved batches of `draft` requirements; shipped to targets.
- Lifecycle rule: a `draft` recorded for already-existing behavior is approved straight into `implemented`/`partial`.

### Changed

- In **upgrade and adopt** modes the checker and the skills refresh without `--force`.
  Fresh mode stays conservative; precious files (CI config, CLAUDE.md/AGENTS.md, .gitattributes) still require `--force` plus the SRS-DD marker.

### Upgrade notes

- Re-running the installer on an initialized target now refreshes `tools/srs_check.py` and the skills automatically — review the `refreshed:` list in its output.
- After upgrading, commit the refreshed tooling together with the regenerated `specs/90-traceability.md`, or the CI freshness gate will fail on the next push.

## [0.1.0] — 2026-08-05

First release of SRS-DD as a reusable framework.

### Added

- Normative specification rules (`specs/README.md`): ISO/IEC/IEEE 29148 structure, EARS phrasing, MADR decision log; requirement lifecycle with `draft`; annotations (`implements:` / `verifies:`); baselines; project configuration with a language-independent lexicon.
- `tools/srs_check.py` — integrity checker and traceability generator:
  config-driven areas, roots, and lexicon; annotation cross-checking;
  `--strict` and `--no-write` flags.
- `tools/srs_init.py` — installer for target repositories with interactive and non-interactive modes, collision handling, and an upgrade mode for already-initialized targets.
- Agent integration: `AGENTS.md` (canonical), thin `CLAUDE.md`, skills `srs`, `srs-new`, `srs-init`, `srs-audit`.
- CI templates in `ci/` (GitHub Actions, GitLab CI) with a traceability-freshness gate; `.gitattributes` pinning the matrix to LF.
- `specs/constitution.md` v1.1.0 — standing engineering principles.

### Upgrade notes

- After updating `tools/srs_check.py` in a target project, regenerate `specs/90-traceability.md`: the status table gained `draft` and its rows now follow lifecycle order.
