#!/bin/sh
# implements: FR-CI-020, FR-CI-030
# Local gate. Run manually or via the pre-commit hook
# (git config core.hooksPath .githooks).
#
# Two checks:
#   1. YAML syntax of the pipeline and of the templates shipped to target
#      projects — shell quoting does not protect ": " sequences from a
#      YAML parser, and a broken template is a stranger's problem.
#   2. Every suite in tests/ — the same scripts the pipeline runs, so a
#      green pre-commit and a green pipeline mean the same thing. Each
#      suite sets its own shell semantics (bash, set -eo pipefail); an
#      interactive shell without set -e hides aborted-line bugs.
#
# The suites include the specification gate: it runs the checker and
# fails when the committed traceability matrix is stale.
#
# The jobs that are not suites — publishing the rendered page, and the
# advisory run against the example project — are deliberately not run
# here: the first would leave a rendered site in the working tree on
# every commit, the second reaches the network, and neither verifies
# anything about this repository.
set -e
cd "$(dirname "$0")/.."

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# YAML first: the suites fail routinely on a regenerated matrix that is
# not staged yet, and a run that stops there must not swallow a broken
# template — that one ships to other people. Missing ruby costs this
# check and nothing else; the pipeline performs it regardless.
if command -v ruby >/dev/null 2>&1; then
    for f in .github/workflows/srs.yml ci/*.yml; do
        [ -e "$f" ] || continue
        ruby -ryaml -e "YAML.load_file('$f')" 2>/dev/null || {
            echo "ci-selftest: invalid YAML: $f" >&2
            ruby -ryaml -e "YAML.load_file('$f')" 2>&1 | head -3 >&2
            exit 1
        }
    done
    echo "ci-selftest: YAML valid"
else
    echo "ci-selftest: ruby not found — skipping the YAML checks" >&2
fi

# implements: FR-CI-090
# The index is compared after every suite, here rather than in a fixture of
# its own: this is where the suites already run, so the check costs nothing,
# and it is the path that carries the danger — a hook hands its index down
# and a suite doing `git add` in its target would write into the commit
# being prepared. spec-check is exempt by design; it has no target and
# stages the matrix on purpose, which is what its whole check is.
# Whatever index this run was handed, which under a hook is not .git/index
# — and a hook is the case that matters, since that is where the leak goes.
index=${GIT_INDEX_FILE:-$(git rev-parse --git-dir 2>/dev/null)/index}

for suite in tests/*.sh; do
    name=$(basename "$suite" .sh)
    echo "ci-selftest: running $name"
    # Taken per suite, not once before the loop: spec-check stages the
    # matrix on purpose, so a single snapshot would leave every suite after
    # it comparing against a state that legitimately moved.
    [ -f "$index" ] && cksum < "$index" > "$tmpdir/index.before"
    if ! "$suite" >"$tmpdir/$name.log" 2>&1; then
        echo "ci-selftest: $name FAILED; last output:" >&2
        tail -20 "$tmpdir/$name.log" >&2
        exit 1
    fi
    if [ -f "$tmpdir/index.before" ] && [ "$name" != "spec-check" ]; then
        cksum < "$index" > "$tmpdir/index.after"
        if ! cmp -s "$tmpdir/index.before" "$tmpdir/index.after"; then
            echo "ci-selftest: $name altered this repository's index" >&2
            exit 1
        fi
    fi
done
echo "ci-selftest: all suites pass"
