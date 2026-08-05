#!/bin/sh
# Local CI self-test. Run manually or via the pre-commit hook
# (git config core.hooksPath .githooks).
#
# Two checks, each of which exists because it caught a real bug that
# reached the repository:
#   1. YAML syntax of .gitlab-ci.yml and ci/*.yml — shell quoting does
#      not protect ": " sequences from the YAML parser.
#   2. Every .gitlab-ci.yml job script, executed under the GitLab
#      runner's shell semantics (bash, set -eo pipefail) — an
#      interactive shell without set -e hides aborted-line bugs.
#
# This covers the specification gate (spec-check job) too: it runs the
# checker and fails when the committed traceability matrix is stale.
set -e
cd "$(dirname "$0")/.."

if ! command -v ruby >/dev/null 2>&1; then
    echo "ci-selftest: ruby not found — cannot parse YAML, skipping" >&2
    exit 0
fi

for f in .gitlab-ci.yml ci/*.yml; do
    ruby -ryaml -e "YAML.load_file('$f')" 2>/dev/null || {
        echo "ci-selftest: invalid YAML: $f" >&2
        ruby -ryaml -e "YAML.load_file('$f')" 2>&1 | head -3 >&2
        exit 1
    }
done
echo "ci-selftest: YAML valid"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -ryaml -e '
cfg = YAML.load_file(".gitlab-ci.yml")
cfg.each do |name, job|
  next unless job.is_a?(Hash) && job["script"].is_a?(Array)
  script = (["set -eo pipefail"] + job["script"]).join("\n") + "\n"
  File.write(File.join(ARGV[0], name + ".sh"), script)
end' "$tmpdir"

for script in "$tmpdir"/*.sh; do
    name=$(basename "$script" .sh)
    echo "ci-selftest: running job '$name' under set -eo pipefail"
    if ! bash "$script" >"$tmpdir/$name.log" 2>&1; then
        echo "ci-selftest: job '$name' FAILED; last output:" >&2
        tail -20 "$tmpdir/$name.log" >&2
        exit 1
    fi
done
echo "ci-selftest: all jobs pass"
