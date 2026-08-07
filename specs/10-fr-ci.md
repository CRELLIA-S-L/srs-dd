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
```

The pipeline **shall** run the working tree's checker and viewer against the
published example project, without letting that result fail the pipeline.

**Rationale.** The example is a real target: a change that stops accepting a
specification which was valid shows up here rather than in a stranger's
repository. Advisory on purpose — an external repository, reachable only over
the network, must not be able to block a release.
