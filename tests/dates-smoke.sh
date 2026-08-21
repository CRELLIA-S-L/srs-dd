#!/usr/bin/env bash
# tools/srs_dates.py: the one command that writes requirement blocks.
#
# verifies: FR-SPEC-020
#
# It is run by a person, on purpose, once — so what matters is that it
# writes the date the history holds and not today's, that a second run
# costs nothing, and that it refuses rather than inventing a date where
# the history cannot be read.
set -eo pipefail

unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."
. tools/test_lib.sh

LAB=/tmp/srs-dates
rm -rf "$LAB"; mkdir -p "$LAB/tools" "$LAB/specs"
cp tools/srs_dates.py tools/srs_check.py tools/srs_parse.py "$LAB/tools/"
printf '{"areas": ["CORE"], "code_roots": ["src"], "test_roots": ["t"]}\n' \
    > "$LAB/specs/srs-config.json"

block() {   # block <id> <title>
    printf '\n### %s — %s\n\n```yaml\nstatus: deferred\nverification: T\nderives_from: []\ndepends_on: []\nrefines: []\nconflicts_with: []\ncode: []\ntests: []\n```\n\nThe system **shall** act.\n' "$1" "$2"
}

( cd "$LAB" && git init -q . && git config user.email t@t && git config user.name t )
{ printf '# core\n'; block FR-CORE-010 "First"; } > "$LAB/specs/10-fr-core.md"
( cd "$LAB" && git add -A && git commit -qm first --date=2026-01-15T10:00:00 \
  && GIT_COMMITTER_DATE=2026-01-15T10:00:00 git commit -q --amend --no-edit --date=2026-01-15T10:00:00 )
{ printf '# core\n'; block FR-CORE-010 "First"; block FR-CORE-020 "Second"; } \
    > "$LAB/specs/10-fr-core.md"
( cd "$LAB" && git add -A && GIT_COMMITTER_DATE=2026-06-20T10:00:00 \
  git commit -q -m second --date=2026-06-20T10:00:00 )

# --dry-run writes nothing at all.
before=$(cksum < "$LAB/specs/10-fr-core.md")
( cd "$LAB" && python3 tools/srs_dates.py --dry-run ) > /tmp/dates-dry.log 2>&1
[ "$(cksum < "$LAB/specs/10-fr-core.md")" = "$before" ] \
    || { echo "FAIL FR-SPEC-020 — --dry-run wrote to the specification"; exit 1; }
grep -qF "FR-CORE-010 created 2026-01-15" /tmp/dates-dry.log \
    || { echo "FAIL FR-SPEC-020 — the dry run did not name the date"
         cat /tmp/dates-dry.log; exit 1; }

# The real run writes the date each identifier first appeared — not today's,
# which is the whole point: a date invented now makes everything look new.
( cd "$LAB" && python3 tools/srs_dates.py ) > /tmp/dates.log 2>&1
grep -qF "created: 2026-01-15" "$LAB/specs/10-fr-core.md" \
    || { echo "FAIL FR-SPEC-020 — the first requirement was not dated"
         cat "$LAB/specs/10-fr-core.md"; exit 1; }
grep -qF "created: 2026-06-20" "$LAB/specs/10-fr-core.md" \
    || { echo "FAIL FR-SPEC-020 — the second requirement got the wrong date"
         cat "$LAB/specs/10-fr-core.md"; exit 1; }
absent "created: $(date +%Y-%m-%d)" "$LAB/specs/10-fr-core.md"

# And the specification still parses.
( cd "$LAB" && python3 tools/srs_check.py --no-write ) > /tmp/dates-check.log 2>&1 \
    || { echo "FAIL FR-SPEC-020 — the dated specification does not parse"
         cat /tmp/dates-check.log; exit 1; }

# A second run costs nothing, so nobody has to remember whether it was done.
after=$(cksum < "$LAB/specs/10-fr-core.md")
( cd "$LAB" && python3 tools/srs_dates.py ) > /tmp/dates-again.log 2>&1
[ "$(cksum < "$LAB/specs/10-fr-core.md")" = "$after" ] \
    || { echo "FAIL FR-SPEC-020 — a second run rewrote what was already dated"
         exit 1; }
grep -qF "0 requirement(s) dated" /tmp/dates-again.log \
    || { echo "FAIL FR-SPEC-020 — a second run claims to have dated something"
         cat /tmp/dates-again.log; exit 1; }

# A file may document the format with an example requirement inside a
# fence, and that example is not a requirement. A tool that edits the same
# files the checker reads has to treat fences the way the checker does, or
# it edits documentation.
cat >> "$LAB/specs/10-fr-core.md" <<'MD'

**Rationale.** The format, by example:

````markdown
### FR-CORE-999 — Not a requirement at all

```yaml
status: deferred
verification: T
```

The system **shall** never be counted.
````
MD
( cd "$LAB" && git add -A && GIT_COMMITTER_DATE=2026-07-01T10:00:00   git commit -q -m documented --date=2026-07-01T10:00:00 )
( cd "$LAB" && python3 tools/srs_dates.py ) > /tmp/dates-fence.log 2>&1
python3 - "$LAB/specs/10-fr-core.md" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
start = text.index("````markdown")
fenced = text[start:text.index("````", start + 12)]
assert "created:" not in fenced, \
    "the dating tool wrote into a fenced example, which is documentation"
PY

# Where the history cannot be read it refuses, rather than inventing a date
# from today — which would be wrong in the direction that makes every
# requirement look new.
NOGIT=/tmp/srs-dates-nogit
rm -rf "$NOGIT"; mkdir -p "$NOGIT/tools" "$NOGIT/specs"
cp tools/srs_dates.py tools/srs_check.py tools/srs_parse.py "$NOGIT/tools/"
cp "$LAB/specs/srs-config.json" "$NOGIT/specs/"
{ printf '# core\n'; block FR-CORE-010 "First"; } > "$NOGIT/specs/10-fr-core.md"
rc=0
( cd "$NOGIT" && python3 tools/srs_dates.py ) > /tmp/dates-nogit.log 2>&1 || rc=$?
[ "$rc" = 2 ] || { echo "FAIL FR-SPEC-020 — no history, exit $rc, expected 2"
                   cat /tmp/dates-nogit.log; exit 1; }
absent "created:" "$NOGIT/specs/10-fr-core.md"

echo "dates-smoke: a specification is dated from its own history, once"
