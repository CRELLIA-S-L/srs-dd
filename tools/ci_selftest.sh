#!/bin/sh
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

for suite in tests/*.sh; do
    name=$(basename "$suite" .sh)
    echo "ci-selftest: running $name"
    if ! "$suite" >"$tmpdir/$name.log" 2>&1; then
        echo "ci-selftest: $name FAILED; last output:" >&2
        tail -20 "$tmpdir/$name.log" >&2
        exit 1
    fi
done
echo "ci-selftest: all suites pass"
