# Assertions the suites share, sourced rather than run — hence no shebang
# and no execute bit: there is nothing here to start.
#
# implements: FR-CI-080
#
# Not a suite: tools/ci_selftest.sh runs tests/*.sh, and this lives here so
# that it is neither run as one nor mistaken for one. Sourced as
# `. tools/test_lib.sh`, after the suite has already cd'd to the repository
# root — a path computed from `$0` breaks when a suite is started from
# inside tests/, because the cd has moved by then and `$0` has not.

# absent <pattern> <file> — the assertion `! grep` cannot make. POSIX
# exempts a command negated with `!` from `set -e`, so `! grep -q X f`
# walks past whether X is there or not; ten checks in these suites were
# written that way and none of them could report. `--` because a pattern
# beginning with a dash would otherwise be read as a flag, and grep would
# then wait on stdin — a suite that hangs rather than one that fails.
absent() {
    if grep -q -- "$1" "$2"; then
        echo "FAIL: $2 still contains: $1" >&2
        exit 1
    fi
}
