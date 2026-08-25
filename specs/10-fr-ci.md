# Functional requirements — ci

The gates: what this repository runs on itself, and the templates a target
project gets.

### FR-CI-010 — The matrix is compared, not trusted

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [ci/gitlab-ci.yml, ci/github-workflow.yml, .github/workflows/srs.yml]
tests: [tests/spec-check.sh]
created: 2026-08-07
```

The specification gate **shall** regenerate the traceability matrix and fail
when the committed copy differs from it.

**Rationale.** The matrix is committed so it can be read and diffed in a
review; that is only safe if staleness is a build failure rather than a habit.

### FR-CI-020 — The same gate runs before a commit

```yaml
status: implemented
verification: I
derives_from: [FR-CI-010]
depends_on: []
refines: []
conflicts_with: []
code: [ci/pre-commit, .githooks/pre-commit, tools/ci_selftest.sh]
tests: []
created: 2026-08-07
```

The installed hook **shall** run the specification gate locally, so a stale
matrix is caught before it is pushed.

**Rationale.** A gate that only exists in CI teaches people to push and wait;
one that runs on commit is the difference between a habit and a chore.

### FR-CI-030 — The local self-test runs the real pipeline

```yaml
status: implemented
verification: I
derives_from: [FR-CI-020]
depends_on: []
refines: []
conflicts_with: []
code: [tools/ci_selftest.sh]
tests: []
created: 2026-08-07
```

The self-test **shall** run every suite in `tests/` and validate the YAML of
the pipeline and of the shipped templates, so that a green pre-commit and a
green pipeline mean the same thing.

**Rationale.** The suites are files, not fragments of a CI configuration, so
both the runner and the hook execute the same scripts and cannot drift
apart. What is deliberately not run here — publishing the page, reaching the
example over the network — verifies nothing about this repository. The YAML
check runs before the suites, because a suite fails routinely on a matrix
that has been regenerated but not staged, and a run that stops there must
not swallow a broken template; a missing parser costs that check alone
rather than turning the whole run into a green tick.

### FR-CI-040 — The rendered specification is published from the default branch

```yaml
status: implemented
verification: I
derives_from: []
depends_on: [FR-VIEW-060]
refines: []
conflicts_with: []
code: [ci/gitlab-ci.yml, .github/workflows/srs.yml]
tests: []
created: 2026-08-07
```

On the default branch the pipeline **shall** render the specification into a
published page with links back to the source at the built revision.

**Rationale.** The audience for a specification includes people who will
never clone the repository, and a page whose code links point at a moving
branch lies as soon as the branch moves.

### FR-CI-050 — A target gets a pipeline, not our pipeline

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-INIT-020]
refines: []
conflicts_with: []
code: [ci/gitlab-ci.yml, ci/github-workflow.yml, tools/srs_init.py]
tests: [tests/installer-smoke.sh]
created: 2026-08-07
```

The installer **shall** offer the CI templates for GitHub and GitLab and
install the chosen one, never this repository's own pipeline configuration.

**Rationale.** Our pipeline tests the framework: smoke-installing into
temporary directories would be meaningless noise in somebody else's project.

### FR-CI-060 — The example project is checked as a downstream consumer

```yaml
status: implemented
verification: I
derives_from: [FR-CI-010]
depends_on: []
refines: []
conflicts_with: []
code: [.github/workflows/srs.yml]
tests: []
created: 2026-08-07
```

The pipeline **shall** run the working tree's checker and viewer against the
published example project, without letting that result fail the pipeline.

**Rationale.** The example is a real target: a change that stops accepting a
specification which was valid shows up here rather than in a stranger's
repository. Advisory on purpose — an external repository, reachable only over
the network, must not be able to block a release.

### FR-CI-090 — A suite working on a target leaves this repository alone

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CI-020]
refines: []
conflicts_with: []
code: [tests/view-smoke.sh, tests/baseline-smoke.sh, tests/release-smoke.sh, tests/installer-smoke.sh, tests/adopt-smoke.sh, tests/upgrade-smoke.sh, tests/checker-rules.sh, tools/ci_selftest.sh]
tests: [tests/checker-rules.sh]
created: 2026-08-17
```

While a suite operates on a target it created, it **shall not** alter the
git state of the repository it was started from.

**Rationale.** The gate runs the suites from a pre-commit hook, and a hook
runs with `GIT_INDEX_FILE` and `GIT_DIR` set to the commit being prepared.
Those are inherited by everything the suites start, so a `git add -A` meant
for a throwaway target under `/tmp` writes that target's paths into the
index of the commit in progress. What comes out is a tree naming files this
repository does not have, pointing at blobs it never wrote: `git commit`
answers "invalid object … Error building trees" and the maintainer is left
with an operation that cannot complete and no hint why.

Measured rather than reasoned: with `GIT_INDEX_FILE` set, one run of
`tests/view-smoke.sh` adds `specs/10-fr-core.md` and `tests/probe.sh` — the
target's placeholder requirement and its fixture — to the index it was
handed.

The suites already own their targets: each creates one under `/tmp`, runs
`git init` in it, and works there. The defect is not what they intend but
what the environment hands them, which is why nothing in the suites reads
wrong and every one of them was affected.

`tests/spec-check.sh` is the exception the statement allows for by naming
targets: it has no target and deliberately works on this repository, staging
the matrix to compare it against what the checker generates. Running under
the hook's index is what makes that check ask about the commit being
prepared rather than the one before it.

Held in two halves, and the split is about cost. Each suite clears the
environment it inherited; `tools/ci_selftest.sh` compares the index after
every suite it runs, which is free because that is where they already run
and is the path a hook actually takes. A fixture that ran the six suites
again to check the same thing was written first and measured: it took the
local gate from twelve seconds to thirty-eight, to assert what the gate now
asserts on its own. What remains in `checker-rules.sh` is the mechanism —
the leak reproduced with the environment inherited, and stopped with it
cleared — which costs no suite runs at all.

### FR-CI-080 — An assertion that something is absent can fail

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CI-030]
refines: []
conflicts_with: []
code: [tools/test_lib.sh]
tests: [tests/checker-rules.sh]
created: 2026-08-17
```

A suite asserting that something is absent **shall** fail when that thing is
present.

**Rationale.** Ten such assertions in this repository could not. They were
written `! grep -q PATTERN file`, and POSIX exempts a command negated with
`!` from `set -e`, so the suite walked past whether the pattern was there or
not — including the checks that `--up` prints no downward subtree, that a
shallow clone offers no baseline picker, and that a refused baseline left no
row behind. Every one of them read as a guard and was a comment.

The same family has bitten twice before. `grep -qv` inverts per line and
succeeds whenever any line differs, which `tests/installer-smoke.sh` carries
a note about; and a check that a file merely still exists says nothing about
whether an operation rewrote it. What they share is a shape that looks like
an assertion and cannot report.

This is FR-SKILL-160 turned on the harness. That one binds the audit — count
a test as proof only where the edit that would redden it can be named — and
says nothing about the suites themselves, where the same question is
answered by whether the assertion is capable of failing at all. A rule about
proof that exempts the machinery of proving is a rule with a hole in it.

Stated as behaviour of a suite rather than as "use this helper", because the
helper is one way to hold it. What matters is that the assertion reports;
where the shared function lives, and whether there is one, is the
implementation this leaves open.

### FR-CI-070 — Cutting a release is one command

```yaml
status: implemented
verification: T
derives_from: [INV-SPEC-030]
depends_on: []
refines: []
conflicts_with: []
code: [tools/srs_release.py]
tests: [tests/release-smoke.sh]
created: 2026-08-08
```

When cutting a release, the release command **shall** date the changelog
section, bump the framework's version and report what to commit — refusing
where the section is missing or already dated, or where the specification
does not pass the checker.

**Rationale.** A release was three files, two tags and an order that had to
be remembered, and the order is what went wrong twice. One command prepares
it, and it stops at the release: the baseline is its own act with its own
command, because the two are independent and this one used to mint a
baseline whether or not the specification had moved. It writes no prose: the
changelog section is written by a person, and its absence is what the
command refuses on. It commits and tags nothing (CON-SPEC-030) — the dated
section is what tells it the release was already cut.

It bumps one number, and the statement says whose: the framework's, not
the checker's. What a release versions is the delivery — the tools and
the standards one installer writes into a target and one upgrade command
refreshes — and the same number is stamped into every file that installer
writes, the grounds standard included. The number lives in
`tools/srs_parse.py`, the one file both checkers must have beside them,
and each re-exports it (ADR-0021). It used to live in the specification
checker, which left the grounds checker announcing a version nothing
bumped.

### FR-CI-100 — The gate refuses a source line nobody had to write long

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CI-020]
refines: []
conflicts_with: []
code: [tests/line-width.sh]
tests: [tests/checker-rules.sh]
created: 2026-08-23
```

The local gate **shall** refuse a source line wider than 120 columns whose
width does not come from a string literal on it.

**Rationale.** `CONTRIBUTING.md` has said 120 columns in code and none in
markdown since before this requirement, and prose is where a rule of this
kind goes to be ignored — an agent that never opens the file applies whatever
width it inferred from how the files look, which is how markdown got reflowed
to a limit the same document explicitly denies. A rule nothing enforces is a
rule read only by whoever already follows it.

The exemption is the hard half and it is why this is not a linter setting. A
line that cannot be split without changing what it produces is left alone
whatever its length: a `printf` whose argument is a whole fixture document, a
CSS declaration inside a page the viewer emits, a single string literal.
Those are not defects and marking them up is worse than leaving them — a
marker inside the CSS would change the bytes the page ships.

So width is measured after the string literals on the line are removed, and
a line inside a Python triple-quoted block is skipped entirely, being literal
throughout. That covers the exemption as `CONTRIBUTING.md` lists it and no
further: an unsplittable run outside a literal — a long URL in a comment — is
refused, and there is no line like that in this repository today. Widening the
rule to recognise one costs a heuristic about what a token is, and the price
is paid only when such a line is actually wanted. What survives is the width somebody chose: a compound command, a
long call, a chain of conditions — the cases where splitting costs nothing
and changes nothing. Eight lines in this repository exceed 120 columns today
and the rule clears all eight; the one it caught was a subshell running three
commands in a row.

Markdown is not looked at, in this repository or in any target. A line break
inside a paragraph renders as a space — `tools/srs_view.py` joins them with
`p.replace("\n", " ")` — so where a line ends is invisible to every reader
and matters only to `git diff`.
