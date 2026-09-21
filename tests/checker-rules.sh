#!/usr/bin/env bash
# Every rule the checker enforces, one fixture each.
#
# The other suites prove that the checker accepts a valid specification and
# that the tools behave. None of them proved that a broken specification is
# *rejected*: a duplicate identifier, a dangling link, a cycle, a second
# modal verb could each have been deleted from srs_check.py and the pipeline
# would have stayed green. ART-050 does not allow a `verification: T`
# requirement to sit with an empty `tests` field, and ten FR-CHK-* did.
#
# Each fixture writes one broken specification into a throwaway project and
# asserts the exit code and the message. The message matters as much as the
# code: a rule that fires with the wrong explanation sends the reader
# looking in the wrong place.
set -eo pipefail

# implements: FR-CI-090
# A hook runs with GIT_INDEX_FILE and GIT_DIR pointing at the commit being
# prepared, and everything this suite starts inherits them — the fixture
# below makes a git target of its own, so without this the `git init` in it
# would land in this repository instead.
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

LAB=/tmp/srs-rules
rm -rf "$LAB"
mkdir -p "$LAB/tools" "$LAB/specs" "$LAB/src" "$LAB/t"
cp tools/srs_check.py tools/srs_parse.py "$LAB/tools/"

cat > "$LAB/specs/srs-config.json" <<'JSON'
{
  "areas": ["CORE"],
  "code_roots": ["src"],
  "test_roots": ["t"],
  "code_extensions": [".py"]
}
JSON

# The specification under test. Everything after the heading is whatever the
# fixture pipes in, so a fixture reads as the one thing it breaks.
spec() {
    { printf '# Functional requirements — core\n\n'; cat; } \
        > "$LAB/specs/10-fr-core.md"
}

# A requirement block: id, title, metadata lines, statement.
block() {
    local id=$1 title=$2 meta=$3 statement=$4
    printf '### %s — %s\n\n```yaml\n%s\n```\n\n%s\n\n' \
        "$id" "$title" "$meta" "$statement"
}

META='status: deferred
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []'

passes=0

# rule <name> <expected exit> <message fragment> [flags…]
rule() {
    local name=$1 want=$2 msg=$3; shift 3
    local rc=0
    ( cd "$LAB" && python3 tools/srs_check.py --no-write "$@" ) \
        > /tmp/srs-rules.log 2>&1 || rc=$?
    if [ "$rc" != "$want" ]; then
        echo "FAIL $name — exit $rc, expected $want"; cat /tmp/srs-rules.log
        exit 1
    fi
    if ! grep -qF "$msg" /tmp/srs-rules.log; then
        echo "FAIL $name — no message matching: $msg"; cat /tmp/srs-rules.log
        exit 1
    fi
    passes=$((passes + 1))
}

# silent <name> <expected exit> <fragment that must NOT appear>
silent() {
    local name=$1 want=$2 msg=$3 rc=0
    ( cd "$LAB" && python3 tools/srs_check.py --no-write ) \
        > /tmp/srs-rules.log 2>&1 || rc=$?
    if [ "$rc" != "$want" ]; then
        echo "FAIL $name — exit $rc, expected $want"; cat /tmp/srs-rules.log
        exit 1
    fi
    if grep -qF "$msg" /tmp/srs-rules.log; then
        echo "FAIL $name — said something it should not: $msg"
        cat /tmp/srs-rules.log; exit 1
    fi
    passes=$((passes + 1))
}

# --- verifies: FR-CHK-010 — identifiers are well-formed and unique.
spec < <(block FR-CORE-010 "First" "$META" 'The system **shall** act.'
         block FR-CORE-010 "Same number again" "$META" \
               'The system **shall** act twice.')
rule "FR-CHK-010 duplicate" 1 "is already used at"

spec < <(block FR-CORE-1 "Two digits short" "$META" 'The system **shall** act.')
rule "FR-CHK-010 malformed" 1 "identifier does not match"

# --- verifies: FR-CHK-020 — exactly one bolded modal verb.
spec < <(block FR-CORE-010 "No verb" "$META" 'The system acts, eventually.')
rule "FR-CHK-020 none" 1 "no bolded modal verb"

spec < <(block FR-CORE-010 "Two verbs" "$META" \
               'The system **shall** act and **should** also report.')
rule "FR-CHK-020 two" 1 "modal verbs, expected one"

# --- verifies: FR-CHK-030 — every link resolves.
spec < <(block FR-CORE-010 "Points at nothing" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-990]}" \
               'The system **shall** act.')
rule "FR-CHK-030 dangling" 1 "link to nonexistent requirement"

# The other half of the same statement: a link that names its own
# requirement. It resolves, so the dangling fixture above says nothing about
# it — the branch could have been deleted with this suite still green.
spec < <(block FR-CORE-010 "Depends on itself" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-010]}" \
               'The system **shall** act.')
rule "FR-CHK-030 self-link" 1 "requirement links to itself"

# And through `superseded_by`, which is checked apart from the link fields
# and so has a branch of its own to lose.
spec < <(block FR-CORE-010 "Superseded by itself" \
               "${META/status: deferred/status: superseded}
superseded_by: FR-CORE-010" 'The system **shall** act.')
rule "FR-CHK-030 self-supersession" 1 "requirement links to itself"

# --- verifies: FR-CHK-040 — no cycles in the derivation graph.
spec < <(block FR-CORE-010 "Derives from the other" \
               "${META/derives_from: \[\]/derives_from: [FR-CORE-020]}" \
               'The system **shall** act.'
         block FR-CORE-020 "Derives from the first" \
               "${META/derives_from: \[\]/derives_from: [FR-CORE-010]}" \
               'The system **shall** respond.')
rule "FR-CHK-040 cycle" 1 "cycle in derives_from links"

# --- verifies: FR-CHK-040 — the other kind of link the statement names. The
# --- rule walked both and only one was ever exercised, so narrowing it to
# --- `derives_from` would have kept this file green.
spec < <(block FR-CORE-010 "Refines the other" \
               "${META/refines: \[\]/refines: [FR-CORE-020]}" \
               'The system **shall** act.'
         block FR-CORE-020 "Refines the first" \
               "${META/refines: \[\]/refines: [FR-CORE-010]}" \
               'The system **shall** respond.')
rule "FR-CHK-040 cycle in refines" 1 "cycle in refines links"

# --- verifies: FR-CHK-040 — and a cycle drawn in both at once, which is the
# --- one two separate walks could not see: A exists because B does, and B is
# --- a special case of A. The message names both kinds it was drawn in.
spec < <(block FR-CORE-010 "Derives from the other" \
               "${META/derives_from: \[\]/derives_from: [FR-CORE-020]}" \
               'The system **shall** act.'
         block FR-CORE-020 "Refines the first" \
               "${META/refines: \[\]/refines: [FR-CORE-010]}" \
               'The system **shall** respond.')
rule "FR-CHK-040 cycle across both kinds" 1 \
     "cycle in derives_from/refines links"

# --- verifies: FR-CHK-240 — the other graph, walked on its own.
spec < <(block FR-CORE-010 "Meaningless without the other" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-020]}" \
               'The system **shall** act.'
         block FR-CORE-020 "Meaningless without the first" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-010]}" \
               'The system **shall** respond.')
rule "FR-CHK-240 cycle in depends_on" 1 "cycle in depends_on links"

# --- verifies: FR-CHK-240 — and the case the separate walks exist for: a
# --- path alternating between the two graphs is a circle in neither sense,
# --- so neither rule reports it. This is the whole content of the decision
# --- to keep the walks apart, and it reddens the day somebody folds
# --- `depends_on` into the derivation fields.
spec < <(block FR-CORE-010 "Derives from the other" \
               "${META/derives_from: \[\]/derives_from: [FR-CORE-020]}" \
               'The system **shall** act.'
         block FR-CORE-020 "Meaningless without the first" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-010]}" \
               'The system **shall** respond.')
silent "FR-CHK-240 mixed path is no cycle" 0 "cycle in"

# --- verifies: FR-CHK-055 — a path a requirement names exists.
spec < <(block FR-CORE-010 "Names a file that is not there" \
               "$(printf '%s' "${META/status: deferred/status: implemented}" \
                  | sed 's|^code: \[\]$|code: [src/absent.py]|')" \
               'The system **shall** act.')
rule "FR-CHK-055 missing path in code" 1 "points to a nonexistent path"

# Both fields, because a test that moved is as invisible as a source file
# that did, and one fixture would have let the other clause be deleted.
spec < <(block FR-CORE-010 "Names a test that is not there" \
               "$(printf '%s' "${META/status: deferred/status: implemented}" \
                  | sed 's|^code: \[\]$|code: [src/app.py]|' \
                  | sed 's|^tests: \[\]$|tests: [t/absent.sh]|')" \
               'The system **shall** act.')
printf 'x\n' > "$LAB/src/app.py"
rule "FR-CHK-055 missing path in tests" 1 "points to a nonexistent path"
rm -f "$LAB/src/app.py"

# --- verifies: FR-CHK-050 — a requirement being realized names where.
spec < <(block FR-CORE-010 "Realized without code" \
               "${META/status: deferred/status: implemented}" \
               'The system **shall** act.')
rule "FR-CHK-050 empty code" 1 "status implemented but the code field is empty"

# `partial` as well as `implemented`: the standard defines both as being
# realized, and with only one exercised the other could be dropped from the
# condition without this suite noticing.
spec < <(block FR-CORE-010 "Half-realized without code" \
               "${META/status: deferred/status: partial}" \
               'The system **shall** act.')
rule "FR-CHK-050 empty code at partial" 1 \
     "status partial but the code field is empty"

# And `deferred` is left alone — that is the state for approved and not yet
# begun, where an empty code field is the whole point.
spec < <(block FR-CORE-010 "Approved, not begun" "$META" \
               'The system **shall** act.')
silent "FR-CHK-050 spares a deferred requirement" 0 "the code field is empty"

# --- verifies: FR-CHK-060 — both halves: a `superseded` without its
# --- replacement, and a replacement named under any other status.
spec < <(block FR-CORE-010 "Superseded by nobody" \
               "${META/status: deferred/status: superseded}" \
               'The system **shall** act.')
rule "FR-CHK-060 superseded without replacement" 1 \
     "status superseded without superseded_by"

spec < <(block FR-CORE-010 "Replaced while still deferred" \
               "$META
superseded_by: FR-CORE-020" \
               'The system **shall** act.'
         block FR-CORE-020 "The replacement" "$META" \
               'The system **shall** replace.')
rule "FR-CHK-060 replacement under another status" 1 \
     "superseded_by present but status is"

# --- verifies: FR-CHK-070, FR-CHK-120 — implementation ahead of approval is
# --- a warning, and only --strict turns it into a failure. The strict half
# --- is exercised by every `rule … --strict` below as well; this is where a
# --- warning and its promotion are asserted on one and the same run.
printf '# implements: FR-CORE-010\n' > "$LAB/src/app.py"  # srs-ignore: a fixture, not our claim
spec < <(block FR-CORE-010 "Draft with code" \
               "$(printf '%s' "$META" \
                  | sed 's|^code: \[\]$|code: [src/app.py]|' \
                  | sed 's|^status: deferred$|status: draft|')" \
               'The system **shall** act.')
rule "FR-CHK-070 warns" 0 "implementation ahead of approval"
rule "FR-CHK-070 strict fails" 1 "treated as errors" --strict
# Each warning names what it is about. File and line locate a requirement
# and identify nothing: the number moves with the next edit above it, and a
# plan that references numbers cannot cite it.
rule "FR-CHK-070 names the requirement built early" 0 \
     "FR-CORE-010 is draft but the code field is not empty"

# --- verifies: FR-CHK-075 — a realized requirement resting on a draft. It had no
# --- fixture while it was the second half of FR-CHK-070's statement — the
# --- requirement read as verified because the other half was.
spec < <(block FR-CORE-010 "The unapproved parent" \
               "${META/status: deferred/status: draft}" \
               'The system **shall** be a draft.'
         block FR-CORE-020 "Built on it anyway" \
               "$(printf '%s' "$META" \
                  | sed 's|^status: deferred$|status: implemented|' \
                  | sed 's|^code: \[\]$|code: [src/app.py]|' \
                  | sed 's|^depends_on: \[\]$|depends_on: [FR-CORE-010]|')" \
               'The system **shall** act.'
         block FR-CORE-030 "Derives from it, and partly built" \
               "$(printf '%s' "$META" \
                  | sed 's|^status: deferred$|status: partial|' \
                  | sed 's|^code: \[\]$|code: [src/app.py]|' \
                  | sed 's|^derives_from: \[\]$|derives_from: [FR-CORE-010]|')" \
               'The system **shall** derive.'
         block FR-CORE-040 "Refines it" \
               "$(printf '%s' "$META" \
                  | sed 's|^status: deferred$|status: implemented|' \
                  | sed 's|^code: \[\]$|code: [src/app.py]|' \
                  | sed 's|^refines: \[\]$|refines: [FR-CORE-010]|')" \
               'The system **shall** narrow.')
printf 'x\n' > "$LAB/src/app.py"
# All three fields the statement names, and `partial` as well as
# `implemented`: with only one of them exercised, dropping the others from
# the condition would leave this suite green.
rule "FR-CHK-075 names both the dependant and the draft" 0 \
     "FR-CORE-020 is implemented and rests on draft FR-CORE-010 (depends_on)"
rule "FR-CHK-075 covers derives_from, at partial" 0 \
     "FR-CORE-030 is partial and rests on draft FR-CORE-010 (derives_from)"
rule "FR-CHK-075 covers refines" 0 \
     "FR-CORE-040 is implemented and rests on draft FR-CORE-010 (refines)"
rule "FR-CHK-075 strict fails" 1 "treated as errors" --strict

# --- verifies: FR-CHK-080 — annotations are cross-checked against the specification.
printf '# implements: FR-CORE-990\n' > "$LAB/src/app.py"  # srs-ignore: a fixture, not our claim
spec < <(block FR-CORE-010 "Nothing claims that number" "$META" \
               'The system **shall** act.')
rule "FR-CHK-080 unknown annotation" 1 "annotation references unknown"

# The other half of the same rule: a mismatch that is not an unknown
# requirement is a warning, not an error.
printf '# implements: FR-CORE-010\n' > "$LAB/src/app.py"  # srs-ignore: a fixture
spec < <(block FR-CORE-010 "Does not list the file back" "$META" \
               'The system **shall** act.')
rule "FR-CHK-080 unlisted file warns" 0 "but is not listed in that"

# An identifier of the right shape whose type or area nobody declared: also
# a warning, and a different one — this is far more often an example in a
# comment than a claim about a requirement, so the message says how to
# silence it.
printf '# implements: ZZ-NOPE-010\n' > "$LAB/src/app.py"  # srs-ignore: a fixture
spec < <(block FR-CORE-010 "Nothing declares that area" "$META" \
               'The system **shall** act.')
rule "FR-CHK-080 unknown type or area warns" 0 "unknown type or area"

# An annotation left pointing at a requirement that has been replaced. The
# reader is told that, and not that the file is missing from a field the
# requirement is past caring about.
printf '# implements: FR-CORE-010\n' > "$LAB/src/app.py"  # srs-ignore: a fixture
spec < <(block FR-CORE-010 "Replaced, and still pointed at" \
               "${META/status: deferred/status: superseded}
superseded_by: FR-CORE-020" 'The system **shall** act.'
         block FR-CORE-020 "The replacement" "$META" \
               'The system **shall** replace.')
rule "FR-CHK-080 annotation on a superseded requirement" 0 \
     "annotation points at superseded"
silent "FR-CHK-080 and says nothing about the listing" 0 "is not listed in that"

# Both ways of being cancelled, not `superseded` alone: INV-SPEC-050 added a
# second, and an annotation pointing at a `withdrawn` requirement read as
# live traceability to a decision to do nothing.
printf '# implements: FR-CORE-010\n' > "$LAB/src/app.py"  # srs-ignore: a fixture
spec < <(block FR-CORE-010 "Withdrawn, and still pointed at" \
               "$(printf '%s' "${META/status: deferred/status: withdrawn}" \
                  | sed 's|^code: \[\]$|code: [src/app.py]|')" \
               'The system **shall** have done something dropped.')
rule "FR-CHK-080 annotation on a withdrawn requirement" 0 \
     "annotation points at withdrawn requirement FR-CORE-010"

# A line saying `srs-ignore` is exempt from all of it — the standard says so
# under Annotations, and every file that documents the annotation grammar
# needs it, this checker included. Nothing exercised it: the exemption could
# be deleted outright and every suite stayed green.
printf '# implements: FR-CORE-990  srs-ignore\n' > "$LAB/src/app.py"
spec < <(block FR-CORE-010 "Nothing claims that number either" "$META" \
               'The system **shall** act.')
silent "FR-CHK-080 srs-ignore exempts the line" 0 "FR-CORE-990"

# And without it the same line is an error, or the exemption above would be
# passing for a checker that reads no annotations at all.
printf '# implements: FR-CORE-990\n' > "$LAB/src/app.py"  # srs-ignore: a fixture
rule "FR-CHK-080 and the same line without it is not" 1 \
     "annotation references unknown requirement FR-CORE-990"

# A file carrying no annotation is not this rule's business. It used to be
# unmentionable altogether; since ADR-0014 an unclaimed file is FR-CHK-210's
# to report, so what is asserted here is that FR-CHK-080 stays silent about
# it — by its message, not by the file name, which the other rule now says.
rm -f "$LAB/src/app.py"
printf 'print("no annotation here")\n' > "$LAB/src/quiet.py"
spec < <(block FR-CORE-010 "Names no file at all" "$META" \
               'The system **shall** act.')
silent "FR-CHK-080 silence on an unannotated file" 0 "is not listed in that"
rm -f "$LAB/src/quiet.py"

# --- verifies: FR-CHK-110 — a fenced code block is opaque. The standard itself
# --- documents the format with example requirements inside fences; without
# --- this rule each of them would become a requirement of its own.
spec < <(block FR-CORE-010 "Documents the format" "$META" \
               'The system **shall** act.

````markdown
### FR-CORE-020 — An example inside a fence

The system **shall** never be counted.
````')
rule "FR-CHK-110 opaque fence" 0 "Requirements: 1"

# --- The same rule at the two edges CommonMark draws, neither of which the
# --- fixture above reaches: a backtick run shorter than the opener does not
# --- close the block, and a run carrying an info string never closes one at
# --- all. Both were unguarded — a mutation of the fence walk passed all 96
# --- fixtures. What catches them is the ghost requirement that surfaces the
# --- moment a block ends a line too early: it has no metadata block, so the
# --- count moves and the run turns red together.
spec < <(block FR-CORE-010 "Opened with four, three inside" "$META" \
               'The system **shall** act.

````markdown
The next line is a bare run of three, and closes nothing:
```
### FR-CORE-020 — Exposed if a shorter run closed the block
````')
rule "FR-CHK-110 short closer" 0 "Requirements: 1"

spec < <(block FR-CORE-010 "An info string opens and never closes" "$META" \
               'The system **shall** act.

```text
```python
### FR-CORE-030 — Exposed if an info string closed the block
```')
rule "FR-CHK-110 info-string closer" 0 "Requirements: 1"

# --- The optional `created` date the standard declares. Declaring a key in
# --- the standard is not enough on its own: the checker keeps its own set,
# --- and a key missing from it is reported as unknown on every requirement
# --- that carries one — which is every requirement, once a specification
# --- has been dated.
spec < <(block FR-CORE-010 "Dated" "$META
created: 2026-01-15" 'The system **shall** act.')
silent "created is a known key" 0 "unknown field"

spec < <(block FR-CORE-010 "Undated" "$META" 'The system **shall** act.')
silent "created is not demanded" 0 "created"

# --- verifies: FR-CHK-100 — a broken configuration is refused by name, exit 2.
spec < <(block FR-CORE-010 "Valid" "$META" 'The system **shall** act.')
cp "$LAB/specs/srs-config.json" "$LAB/specs/srs-config.json.bak"
printf '{"areas": "CORE"}\n' > "$LAB/specs/srs-config.json"
rule "FR-CHK-100 bad type" 2 "areas must be a list of non-empty strings"
printf '{"areas": ["core"]}\n' > "$LAB/specs/srs-config.json"
rule "FR-CHK-100 bad area" 2 "must match"
# A list of non-empty strings that holds none is still a list of non-empty
# strings, so the check above passes it. The rule fires on three keys and
# had a fixture for one, which is the shape this whole file exists to
# refuse: a list exercised at a single entry is a list that can lose the
# others without anybody hearing. Each of the three is something the
# checker cannot work without — the identifier grammar is built from the
# areas, and a statement is recognized by its modal verb and its rationale
# marker — so an empty one matches nothing anybody could write.
for key in areas modal_verbs rationale_markers; do
    python3 - "$LAB/specs/srs-config.json" "$key" <<'PY2'
import json
import sys
cfg = {"areas": ["CORE"], "code_roots": ["src"], "test_roots": ["t"],
       "code_extensions": [".py"]}
cfg[sys.argv[2]] = []
with open(sys.argv[1], "w", encoding="utf-8") as handle:
    handle.write(json.dumps(cfg) + "\n")
PY2
    rule "FR-CHK-100 empty $key" 2 "$key must not be empty"
done
printf 'not json at all\n' > "$LAB/specs/srs-config.json"
rule "FR-CHK-100 unparsable" 2 "invalid JSON"
# Valid JSON of the wrong shape: every key lookup below would fail on it, so
# the file is refused as a whole rather than one key at a time.
printf '["areas", "code_roots"]\n' > "$LAB/specs/srs-config.json"
rule "FR-CHK-100 not an object" 2 "the top level must be a JSON object"
mv "$LAB/specs/srs-config.json.bak" "$LAB/specs/srs-config.json"

# --- verifies: FR-CHK-170 — a key that is absent is named as absent, not reported
# --- through the value it does not have.
spec < <(block FR-CORE-010 "No verification method" \
               "${META/verification: I/}" 'The system **shall** act.')
rule "FR-CHK-170 names the missing key" 1 \
     "required key 'verification' is missing"
silent "FR-CHK-170 does not blame the value" 1 "method '' is not one of"

# Both required keys, not whichever one the fixture happened to drop: the
# rule reads a list, and a list exercised at one entry is a list that can
# lose the others quietly.
spec < <(block FR-CORE-010 "No status either" \
               "${META/status: deferred/}" 'The system **shall** act.')
rule "FR-CHK-170 names the other required key" 1 \
     "required key 'status' is missing"

# --- verifies: FR-CHK-180 — a key a later version of the format retired is an error
# --- naming what replaced it and when. The table is empty until the format
# --- first moves, so the fixture supplies an entry and runs the real path.
spec < <(block FR-CORE-010 "Uses a key that was renamed" \
               "$META
depends: [FR-CORE-020]" 'The system **shall** act.'
         block FR-CORE-020 "The other one" "$META" \
               'The system **shall** respond.')
rc=0
( cd "$LAB" && python3 -c "
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import srs_check
srs_check.RETIRED_FIELDS['depends'] = ('depends_on', '9.9.9')
sys.exit(srs_check.main())
" --no-write ) > /tmp/srs-rules.log 2>&1 || rc=$?
test "$rc" -eq 1 || { echo "FAIL FR-CHK-180 — exit $rc, expected 1"
                      cat /tmp/srs-rules.log; exit 1; }
grep -qF "key 'depends' was renamed to 'depends_on' in 9.9.9" \
     /tmp/srs-rules.log || { echo "FAIL FR-CHK-180 — wrong message"
                             cat /tmp/srs-rules.log; exit 1; }
# A retired key is an error, so it must not also be reported as merely
# unknown — the reader would be told two different things about one key.
grep -qF "unknown field 'depends'" /tmp/srs-rules.log \
    && { echo "FAIL FR-CHK-180 — also called it unknown"; exit 1; }
passes=$((passes + 2))

# A key that was withdrawn without a replacement says so instead of naming
# one that does not exist.
rc=0
( cd "$LAB" && python3 -c "
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import srs_check
srs_check.RETIRED_FIELDS['depends'] = (None, '9.9.9')
sys.exit(srs_check.main())
" --no-write ) > /tmp/srs-rules.log 2>&1 || rc=$?
grep -qF "key 'depends' was withdrawn in 9.9.9" /tmp/srs-rules.log \
    || { echo "FAIL FR-CHK-180 withdrawn — wrong message"
         cat /tmp/srs-rules.log; exit 1; }
passes=$((passes + 1))

# --- verifies: FR-CHK-140 — only a requirement that says it is verified by test and
# --- lists none. Two requirements in one specification, because judging
# --- them all by one method is exactly how this went wrong once: the check
# --- sat in a loop that rebinds the requirement but not the method, so a
# --- single stale value was applied to all eighty-five.
# `code` is filled because a requirement being realized must name where
# (FR-CHK-050); what these fixtures are about is the `tests` field.
printf 'x\n' > "$LAB/src/app.py"
PARTIAL='status: partial
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [src/app.py]
tests: []'

spec < <(block FR-CORE-010 "Inspected, and lists no test" "$PARTIAL" \
               'The system **shall** act.'
         block FR-CORE-020 "Tested, and lists none" \
               "${PARTIAL/verification: I/verification: T}" \
               'The system **shall** respond.')
rule "FR-CHK-140 names the tested one" 0 \
     "FR-CORE-020 says verification T and lists no test"
silent "FR-CHK-140 leaves the inspected one alone" 0 \
     "FR-CORE-010 says verification T"

# A test listed is a rule satisfied.
spec < <(block FR-CORE-010 "Tested and says so" \
               "$(printf '%s' "${PARTIAL/verification: I/verification: T}" \
                  | sed 's|^tests: \[\]$|tests: [t/probe.sh]|')" \
               'The system **shall** act.')
printf 'true\n' > "$LAB/t/probe.sh"
silent "FR-CHK-140 silent when a test is listed" 0 "lists no test"
# Both files go: the fixtures below run on a lab with nothing under the
# roots, and a file left behind is one FR-CHK-210 would report.
rm -f "$LAB/t/probe.sh" "$LAB/src/app.py"

# --- verifies: FR-CHK-150 — only total isolation. A requirement at either end of a
# --- link is not isolated, which is what keeps the rule from firing on
# --- most of a healthy specification.
spec < <(block FR-CORE-010 "Points at the other" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-020]}" \
               'The system **shall** act.'
         block FR-CORE-020 "Pointed at" "$META" \
               'The system **shall** respond.'
         block FR-CORE-030 "Touched by nothing" "$META" \
               'The system **shall** stand alone.')
rule "FR-CHK-150 names the isolated one" 0 \
     "FR-CORE-030 is linked to nothing"
silent "FR-CHK-150 spares the source of a link" 0 "FR-CORE-010 is linked to"
silent "FR-CHK-150 spares the target of a link" 0 "FR-CORE-020 is linked to"

# --- verifies: FR-CHK-150 — a cancelled requirement is outside the rule, both ways of
# --- being cancelled. `superseded` used to escape only because its
# --- `superseded_by` counts as a link; `withdrawn` names no successor and
# --- so tripped a warning for having done what was intended.
spec < <(block FR-CORE-010 "Withdrawn and isolated" \
               "${META/status: deferred/status: withdrawn}" \
               'The system **shall** have done something dropped.')
silent "FR-CHK-150 spares a withdrawn requirement" 0 \
       "FR-CORE-010 is linked to nothing"

# --- verifies: FR-CHK-190 — a live requirement resting on a withdrawn one, at every
# --- live status rather than the built ones alone, and not through
# --- `conflicts_with`.
spec < <(block FR-CORE-010 "Withdrawn ground" \
               "${META/status: deferred/status: withdrawn}" \
               'The system **shall** have done something dropped.'
         block FR-CORE-020 "Deferred, and standing on it" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-010]}" \
               'The system **shall** act.'
         block FR-CORE-030 "Diverging from it on purpose" \
               "${META/conflicts_with: \[\]/conflicts_with: [FR-CORE-010]}" \
               'The system **shall** differ.'
         block FR-CORE-040 "Derives from it" \
               "${META/derives_from: \[\]/derives_from: [FR-CORE-010]}" \
               'The system **shall** derive.'
         block FR-CORE-050 "Refines it" \
               "${META/refines: \[\]/refines: [FR-CORE-010]}" \
               'The system **shall** narrow.')
# All three fields the statement names. One of them alone would let the
# other two be dropped from the condition without this suite noticing.
rule "FR-CHK-190 names the dependant and the withdrawn one" 0 \
     "FR-CORE-020 is deferred and rests on withdrawn FR-CORE-010 (depends_on)"
rule "FR-CHK-190 covers derives_from" 0 \
     "FR-CORE-040 is deferred and rests on withdrawn FR-CORE-010 (derives_from)"
rule "FR-CHK-190 covers refines" 0 \
     "FR-CORE-050 is deferred and rests on withdrawn FR-CORE-010 (refines)"
rule "FR-CHK-190 strict fails" 1 "treated as errors" --strict
silent "FR-CHK-190 ignores conflicts_with" 0 "FR-CORE-030 is deferred"

# --- verifies: FR-CHK-160 — what a rule costs is the project's to set. The rule used
# --- throughout is `unknown-key`, because it needs nothing but a key.
UNKNOWN='status: deferred
verification: I
depends_on: [FR-CORE-020]
bogus: [x]'

# The partner exists only so that neither requirement is isolated: the
# `unlinked` rule would otherwise add a warning of its own and the strict
# runs below would be judging the wrong thing.
PARTNER='status: deferred
verification: I'

config() { printf '%s\n' "$1" > "$LAB/specs/srs-config.json"; }
BASE='"areas": ["CORE"], "code_roots": ["src"], "test_roots": ["t"]'

spec < <(block FR-CORE-010 "Carries a key nobody knows" "$UNKNOWN" \
               'The system **shall** act.'
         block FR-CORE-020 "The partner" "$PARTNER" \
               'The system **shall** respond.')
config "{$BASE}"
rule "FR-CHK-160 warns by default" 0 "warning: "
rule "FR-CHK-160 and fails a strict gate" 1 "treated as errors" --strict

config "{$BASE, \"rules\": {\"unknown-key\": \"report\"}}"
rule "FR-CHK-160 lowered to a report" 0 "note: "
# The point of lowering: the gate survives it.
rule "FR-CHK-160 a report does not fail --strict" 0 "note: " --strict

config "{$BASE, \"rules\": {\"unknown-key\": \"off\"}}"
silent "FR-CHK-160 silenced says nothing" 0 "unknown field"

# One requirement may excuse itself while the rule stays on for the rest.
config "{$BASE}"
spec < <(block FR-CORE-010 "Excuses itself by name" \
               "$UNKNOWN
exempt: [unknown-key]" 'The system **shall** act.'
         block FR-CORE-020 "The partner" "$PARTNER" \
               'The system **shall** respond.')
silent "FR-CHK-160 exempt in the block" 0 "unknown field"

# The shape is a list, and the advice names a rule rather than a
# requirement — the field holds rule names, and a suggestion pointing at the
# wrong vocabulary sends the reader to the wrong page of the standard.
spec < <(block FR-CORE-010 "Exempt is not a list" \
               "$UNKNOWN
exempt: unknown-key" 'The system **shall** act.'
         block FR-CORE-020 "The partner" "$PARTNER" \
               'The system **shall** respond.')
rule "FR-CHK-160 exempt must be a list" 1 \
     "exempt must be a bracketed list, e.g. [unknown-key]"

# A name nobody knows is refused rather than ignored — in the block…
spec < <(block FR-CORE-010 "Excuses itself from nothing" \
               "$UNKNOWN
exempt: [no-such-rule]" 'The system **shall** act.'
         block FR-CORE-020 "The partner" "$PARTNER" \
               'The system **shall** respond.')
rule "FR-CHK-160 unknown name in exempt" 1 "exempt names an unknown rule"

# …and in the configuration, where it is a refusal to start at all.
spec < <(block FR-CORE-010 "Valid" "$META" 'The system **shall** act.')
config "{$BASE, \"rules\": {\"no-such-rule\": \"off\"}}"
rule "FR-CHK-160 unknown name in config" 2 "names an unknown rule"
config "{$BASE, \"rules\": {\"unknown-key\": \"loud\"}}"
rule "FR-CHK-160 unknown severity" 2 "must be one of"
config "{$BASE, \"rules\": []}"
rule "FR-CHK-160 rules is not an object" 2 "rules must be an object"
config "{$BASE}"

# --- The refusal carries the reasons. The verdict goes to stderr and the
# --- checker's findings to stdout, so a caller redirecting one of the two
# --- used to be told that something was wrong and never what.
LAB2=/tmp/srs-refusal
rm -rf "$LAB2"; mkdir -p "$LAB2/tools" "$LAB2/specs"
cp tools/srs_baseline.py tools/srs_view.py tools/srs_check.py \
   tools/srs_parse.py "$LAB2/tools/"
cp "$LAB/specs/srs-config.json" "$LAB2/specs/"
printf '# Baselines\n\n| Version | Date | Tag | What changed |\n|---|---|---|---|\n' \
    > "$LAB2/specs/92-baselines.md"
printf '### FR-CORE-010 — No metadata at all\n' > "$LAB2/specs/10-fr-core.md"
rc=0
( cd "$LAB2" && python3 tools/srs_baseline.py 1.0.0 ) \
    > /dev/null 2> /tmp/srs-refusal.log || rc=$?
test "$rc" -eq 2 || { echo "FAIL refusal — exit $rc, expected 2"
                      cat /tmp/srs-refusal.log; exit 1; }
grep -qF "the checker does not pass" /tmp/srs-refusal.log \
    || { echo "FAIL refusal — no verdict"; cat /tmp/srs-refusal.log; exit 1; }
grep -qF "no metadata block" /tmp/srs-refusal.log \
    || { echo "FAIL refusal — verdict without the reason"
         cat /tmp/srs-refusal.log; exit 1; }
rm -rf "$LAB2"
passes=$((passes + 3))

# --- verifies: FR-CHK-200 — a file a requirement names says so. The forward half of
# --- this link has been checked from the start; nothing checked that the
# --- file agrees, which is the half that decays.
REALIZED='status: implemented
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [src/app.py]
tests: []'

printf 'print("no claim here")\n' > "$LAB/src/app.py"
spec < <(block FR-CORE-010 "Names a file that stays silent about it" \
               "$REALIZED" 'The system **shall** act.')
rule "FR-CHK-200 names both ends" 0 \
     "FR-CORE-010 names src/app.py in code and the file does not carry"
rule "FR-CHK-200 strict fails" 1 "treated as errors" --strict

# Annotated, and the rule goes quiet. Both keywords, because `implements`
# pairs with `code` and `verifies` with `tests`, and a rule that checked one
# of the two would leave the other half of every project unguarded.
printf '# implements: FR-CORE-010\n' > "$LAB/src/app.py"  # srs-ignore: a fixture
silent "FR-CHK-200 silent once the file claims it" 0 "does not carry"

printf 'print("no claim here")\n' > "$LAB/t/probe.py"
spec < <(block FR-CORE-010 "Names a test that stays silent about it" \
               "$(printf '%s' "$REALIZED" \
                  | sed 's|^tests: \[\]$|tests: [t/probe.py]|')" \
               'The system **shall** act.')
rule "FR-CHK-200 covers the tests field too" 0 \
     "names t/probe.py in tests and the file does not carry \`verifies:"

# A draft carrying code is a harvested proposal, and a harvest that must be
# annotated before anybody has approved it is a harvest nobody finishes.
spec < <(block FR-CORE-010 "Harvested, not yet approved" \
               "${REALIZED/status: implemented/status: draft}" \
               'The system **shall** act.')
printf 'print("no claim here")\n' > "$LAB/src/app.py"
silent "FR-CHK-200 spares a draft" 0 "does not carry"

# --- verifies: FR-CHK-210 — a file neither end claims.
spec < <(block FR-CORE-010 "Names nothing at all" "$META" \
               'The system **shall** act.')
printf 'print("nobody wants me")\n' > "$LAB/src/orphan.py"
rule "FR-CHK-210 names the unclaimed file" 0 \
     "src/orphan.py — no requirement names this file and it claims none"
rule "FR-CHK-210 strict fails" 1 "treated as errors" --strict

# Claimed from either end and it goes quiet — the field alone is enough,
# because pairing is FR-CHK-200's business and not this rule's.
printf '# implements: FR-CORE-010\n' > "$LAB/src/orphan.py"  # srs-ignore: a fixture
silent "FR-CHK-210 silent when the file claims a requirement" 0 \
       "orphan.py — no requirement names"

# A cancelled requirement counts for neither end. Its `code` field records
# what it once pointed at; treated as a claim, a withdrawal would be the
# quietest way to take code out of sight.
rm -f "$LAB/src/orphan.py"
printf 'print("left behind")\n' > "$LAB/src/dropped.py"
spec < <(block FR-CORE-010 "Withdrawn, and its file stayed" \
               "$(printf '%s' "${META/status: deferred/status: withdrawn}" \
                  | sed 's|^code: \[\]$|code: [src/dropped.py]|')" \
               'The system **shall** have done something dropped.')
rule "FR-CHK-210 a file only a withdrawn requirement names" 0 \
     "src/dropped.py — no requirement names this file"

# --- verifies: FR-CHK-230 — and the matrix says the same about that file.
# --- The generated section had no fixture at all: every run in this suite
# --- passes --no-write, so the one place three tools could disagree was the
# --- one place nothing looked. Counted from every requirement, the withdrawn
# --- one above covered src/dropped.py and the matrix called it referenced
# --- while the rule above called it unclaimed, in the same run.
( cd "$LAB" && python3 tools/srs_check.py ) > /tmp/srs-rules.log 2>&1 \
    || { echo "FAIL FR-CHK-230 — the checker refused the fixture, so no"
         echo "matrix was written and the assertions below have nothing to"
         echo "read"; cat /tmp/srs-rules.log; exit 1; }
grep -qF -- "- \`src/dropped.py\`" "$LAB/specs/90-traceability.md" \
    || { echo "FAIL FR-CHK-230 — a file only a cancelled requirement names is"
         echo "missing from the matrix's list of unreferenced files"
         sed -n '/Code files outside/,$p' "$LAB/specs/90-traceability.md"
         exit 1; }
# Two, because src/app.py from the FR-CHK-200 block above is still here and
# nothing live names it either. Before the change the withdrawn requirement
# covered src/dropped.py and this line read "1 of 2".
grep -qF "No requirement references them: 2 of 2." \
     "$LAB/specs/90-traceability.md" \
    || { echo "FAIL FR-CHK-230 — the count is not over the live requirements"
         sed -n '/Code files outside/,$p' "$LAB/specs/90-traceability.md"
         exit 1; }
passes=$((passes + 2))
rm -f "$LAB/specs/90-traceability.md"

# Superseded is the other way of being over, and the same answer.
spec < <(block FR-CORE-010 "Replaced, and its file stayed" \
               "$(printf '%s' "${META/status: deferred/status: superseded}" \
                  | sed 's|^code: \[\]$|code: [src/dropped.py]|')
superseded_by: FR-CORE-020" 'The system **shall** have done something.'
         block FR-CORE-020 "The replacement" "$META" \
               'The system **shall** replace.')
rule "FR-CHK-210 a file only a superseded requirement names" 0 \
     "src/dropped.py — no requirement names this file"

# But an annotation the file carries is something it said about itself, and
# FR-CHK-080 has answered it with the line and the identifier. Saying it
# again here would put two findings on one file, the second claiming it
# says nothing while the first quotes what it says. Both ways an annotation
# fails to resolve, because the rule turns on there being one at all.
printf '# implements: FR-CORE-010\n' > "$LAB/src/dropped.py"  # srs-ignore: a fixture
rule "FR-CHK-210 leaves a dead annotation to FR-CHK-080" 0 \
     "annotation points at superseded"
silent "FR-CHK-210 and does not name the file twice" 0 \
       "dropped.py — no requirement names"

printf '# implements: FR-CORE-990\n' > "$LAB/src/dropped.py"  # srs-ignore: a fixture
rule "FR-CHK-210 leaves an unknown annotation to FR-CHK-080" 1 \
     "annotation references unknown requirement FR-CORE-990"
silent "FR-CHK-210 does not call a claiming file unclaimed" 1 \
       "dropped.py — no requirement names"
rm -f "$LAB/src/dropped.py" "$LAB/src/app.py" "$LAB/t/probe.py"

# The other end of the same line, and the one the rule was written around:
# a file a live requirement names is FR-CHK-200's business however bare it
# is. Saying "no requirement names this file" of a file a requirement names
# would be the doubled finding again, and this half of it false. Worth a
# fixture of its own because the state is not exotic — it is every project's
# before its annotations are written, and was this repository's for 174
# pairs until ADR-0014. It runs after the clean-up above: the fixture before
# it leaves an unresolvable annotation behind, which makes the checker exit
# 1 over something this one is not about.
printf 'x = 1\n' > "$LAB/src/named.py"
spec < <(block FR-CORE-010 "Names a file that stays bare" \
               "$(printf '%s' "${META/status: deferred/status: implemented}" \
                  | sed 's|^code: \[\]$|code: [src/named.py]|')" \
               'The system **shall** act.')
rule "FR-CHK-210 leaves a named file to FR-CHK-200" 0 \
     "FR-CORE-010 names src/named.py in code and the file does not carry"
silent "FR-CHK-210 does not call a named file unclaimed" 0 \
       "src/named.py — no requirement names this file"
rm -f "$LAB/src/named.py"

# --- verifies: IF-SPEC-020 — a published rule name keeps its meaning. The names are
# --- written into somebody else's `specs/srs-config.json` and into `exempt`
# --- fields in their requirements, and a renamed one has no retired table to
# --- be found through the way a metadata key does — the checker refuses to
# --- start and lists what it knows. A promise about the future cannot be
# --- tested; what can is the past, listed here so a rename has to walk past
# --- it. Written out rather than read from RULES, which would compare the
# --- tuple with itself and never fail.
( cd "$LAB" && python3 -c "
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import srs_check

published = (
    'unknown-key', 'draft-with-code', 'rests-on-draft', 'rests-on-withdrawn',
    'test-missing', 'unlinked', 'annotation-unknown-area',
    'annotation-superseded', 'annotation-unlisted', 'annotation-unpaired',
    'annotation-absent', 'baseline-without-row', 'file-range',
)
gone = [name for name in published if name not in srs_check.RULES]
if gone:
    sys.stderr.write('rule names withdrawn or renamed: %s\n' % ', '.join(gone))
    sys.exit(1)
" ) > /tmp/srs-rules.log 2>&1 || { echo "FAIL IF-SPEC-020 — a published rule name is gone"
                                  cat /tmp/srs-rules.log; exit 1; }
passes=$((passes + 1))

# --- verifies: IF-CI-020 — the exit codes are what other people's pipelines bind to.
# --- Every fixture above proves 1 and 2 for a specification that was read;
# --- what nothing proved is the two refusals that happen before one ever is.
# The flag is judged before the configuration and before any file, so
# whatever the lab holds at this point is beside the point.
rule "IF-CI-020 unknown flag" 2 "unknown flag(s): --bogus" --bogus

# And a checker started where there is no specification to read. Its own
# directory: the lab above has a specs/ by construction, and the helper
# always runs inside it.
LAB3=/tmp/srs-nospecs
rm -rf "$LAB3"; mkdir -p "$LAB3/tools"
cp tools/srs_check.py tools/srs_parse.py "$LAB3/tools/"
rc=0
( cd "$LAB3" && python3 tools/srs_check.py --no-write ) \
    > /tmp/srs-rules.log 2>&1 || rc=$?
test "$rc" -eq 2 || { echo "FAIL IF-CI-020 no specs — exit $rc, expected 2"
                      cat /tmp/srs-rules.log; exit 1; }
grep -qF "specs/ directory not found" /tmp/srs-rules.log \
    || { echo "FAIL IF-CI-020 no specs — wrong message"
         cat /tmp/srs-rules.log; exit 1; }
rm -rf "$LAB3"
passes=$((passes + 2))

# --- verifies: FR-CI-080 — the shared assertion reports. `absent` is the
# --- one thing in these suites whose whole job is to fail, so it is the one
# --- thing that has to be watched failing: run in a subshell, because a
# --- working `absent` exits, and this fixture is here to see it do that.
. tools/test_lib.sh
printf 'the needle is here\n' > "$LAB/haystack.txt"
rc=0
( absent "needle" "$LAB/haystack.txt" ) > /tmp/srs-rules.log 2>&1 || rc=$?
test "$rc" -eq 1 || { echo "FAIL FR-CI-080 — absent did not fail on a match"
                      cat /tmp/srs-rules.log; exit 1; }
grep -qF "still contains: needle" /tmp/srs-rules.log \
    || { echo "FAIL FR-CI-080 — absent failed without saying what it found"
         cat /tmp/srs-rules.log; exit 1; }
# And it is silent when the thing really is absent, or every suite using it
# would be red for the wrong reason.
absent "no such string" "$LAB/haystack.txt"
# A pattern beginning with a dash is a pattern, not a flag. The haystack
# holds the literal `-e`, so a working `absent` must fail on it. Without
# `--`, grep reads `-e` as its own flag and takes the path as the pattern,
# then waits on stdin — hence the redirect, which turns what would be a
# hung suite into a wrong answer this can see.
printf -- '-e is in here too\n' >> "$LAB/haystack.txt"
rc=0
( absent "-e" "$LAB/haystack.txt" < /dev/null ) > /tmp/srs-rules.log 2>&1 || rc=$?
test "$rc" -eq 1 || { echo "FAIL FR-CI-080 — a dash-leading pattern was read as a flag"
                      cat /tmp/srs-rules.log; exit 1; }
rm -f "$LAB/haystack.txt"
passes=$((passes + 3))

# --- verifies: FR-CI-090 — a suite working on a target leaves this
# --- repository alone. What the target-making suites do about it is a
# --- line clearing the git environment they inherited; this proves that
# --- line is what stands between a target's `git add` and the index the
# --- hook handed down. The suites themselves are compared against that
# --- index where they already run, in tools/ci_selftest.sh — running them
# --- again here would triple the gate to assert what it already asserts.
LAB4=/tmp/srs-gitenv
rm -rf "$LAB4"; mkdir -p "$LAB4/target"
( cd "$LAB4/target" && git init -q . && printf 'x\n' > only-here.txt )
git rev-parse --git-dir >/dev/null 2>&1 \
    || { echo "FAIL FR-CI-090 — not a git repository"; exit 1; }
# A repository is not enough: `git init` writes no index until something is
# staged, and this fixture needs a real one to hand down. Without the guard
# the `cp` below fails under `set -e` and the suite dies saying only
# "No such file or directory" — an assertion that cannot report, which is
# the shape FR-CI-080 exists to forbid.
stand_in="$(git rev-parse --git-dir)/index"
[ -f "$stand_in" ] \
    || { echo "FAIL FR-CI-090 — no index to hand down; stage something first"
         exit 1; }
cp "$stand_in" "$LAB4/index"
cksum < "$LAB4/index" > "$LAB4/before"

# Inherited, as a hook leaves it: the target's file lands in the index it
# was handed. This is the defect, reproduced.
( cd "$LAB4/target" && GIT_INDEX_FILE="$LAB4/index" git add -A ) >/dev/null 2>&1
cksum < "$LAB4/index" > "$LAB4/after"
cmp -s "$LAB4/before" "$LAB4/after" \
    && { echo "FAIL FR-CI-090 — the fixture no longer reproduces the leak"
         exit 1; }

# Cleared, as every target-making suite does before it starts: the same
# command cannot reach it.
cp "$(git rev-parse --git-dir)/index" "$LAB4/index"
cksum < "$LAB4/index" > "$LAB4/before"
( cd "$LAB4/target" \
  && unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY \
  && git add -A ) >/dev/null 2>&1
cksum < "$LAB4/index" > "$LAB4/after"
cmp -s "$LAB4/before" "$LAB4/after" \
    || { echo "FAIL FR-CI-090 — clearing the environment did not protect the index"
         exit 1; }

# And every suite that makes a target carries that line, or the protection
# above is a property of this fixture rather than of the suites.
#
# The list comes out of the requirement's own `code` field. Written out
# here it was nine names while the field held ten, and the tenth —
# `grounds-check` — could have lost its `unset` with this suite green;
# before that `dates-smoke` and `grounds-rules` were the missing ones.
# Nothing else would catch it: tools/ci_selftest.sh compares the index
# around each suite, and without a hook there is no inherited
# GIT_INDEX_FILE for the leak to travel through, which is exactly the run
# CI makes. That file is named by the field too and carries no `unset`,
# and must not: it is the gate that runs the suites, not a suite working
# on a target of its own.
suites=$(python3 - <<'FIELD'
import re
text = open('specs/10-fr-ci.md', encoding='utf-8').read()
block = text[text.index('### FR-CI-090'):]
field = re.search(r'^code: \[(.*?)\]', block, re.M).group(1)
for name in (part.strip() for part in field.split(',')):
    if name.startswith('tests/') and name.endswith('.sh'):
        print(name)
FIELD
)
test -n "$suites" \
    || { echo "FAIL FR-CI-090 — the code field of FR-CI-090 names no suite"
         exit 1; }
for suite in $suites; do
    grep -q "^unset GIT_INDEX_FILE" "$suite" \
        || { echo "FAIL FR-CI-090 — $suite does not clear the environment"
             exit 1; }
done
rm -rf "$LAB4"
passes=$((passes + 3))

# The backdrop itself has to pass — and pass a strict gate, or "valid"
# would mean "valid apart from what we stopped looking at". Two
# requirements, linked, because one on its own is isolated by definition.
spec < <(block FR-CORE-010 "Valid, and points at the other" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-020]}" \
               'The system **shall** act.'
         block FR-CORE-020 "Valid, and pointed at" "$META" \
               'The system **shall** respond.')
rule "the valid specification passes" 0 "Requirements: 2"
rule "and passes a strict gate" 0 "Requirements: 2" --strict

# --- verifies: FR-CI-100 — the gate refuses a line nobody had to write
# long, and leaves alone the one that cannot be split.
#
# Run against a target of its own rather than this repository: a fixture
# asserting "the repository passes" proves only that today's repository
# passes, and would keep passing if the rule were deleted.
LAB5=/tmp/srs-width
rm -rf "$LAB5"; mkdir -p "$LAB5/tools" "$LAB5/tests"

# A compound command, wide because somebody wrote it that way.
printf 'x() { :; }\n( cd /tmp && echo %s && echo %s && echo %s && echo %s )\n' \
    "$(printf 'a%.0s' {1..40})" "$(printf 'b%.0s' {1..40})" \
    "$(printf 'c%.0s' {1..40})" "$(printf 'd%.0s' {1..40})" \
    > "$LAB5/tests/wide.sh"
bash tests/line-width.sh "$LAB5" >/dev/null 2>"$LAB5/err" \
    && { echo "FAIL FR-CI-100 — a splittable 120+ line was accepted"; exit 1; }
grep -q "columns wide" "$LAB5/err" \
    || { echo "FAIL FR-CI-100 — refused without saying the width"; exit 1; }

# The same width, all of it inside one literal: left alone, whatever it is.
rm "$LAB5/tests/wide.sh"
printf "printf '%s'\n" "$(printf 'z%.0s' {1..200})" > "$LAB5/tests/long.sh"
bash tests/line-width.sh "$LAB5" >/dev/null 2>&1 \
    || { echo "FAIL FR-CI-100 — an unsplittable literal was refused"; exit 1; }
rm -rf "$LAB5"
passes=$((passes + 2))

# --- verifies: FR-CHK-220 — the one rule that reads history meets a
# --- checkout that is not a repository. The lab has no .git, so the only
# --- thing needed is the log the rule reads first; without it the rule
# --- returns before git is asked at all, which is why the other fixtures
# --- never see this note.
# Two linked requirements, so the run is clean and --strict below has
# nothing but the note to react to.
spec < <(block FR-CORE-010 "A requirement" "$META" 'The system **shall** act.'
         block FR-CORE-020 "What it rests on" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-010]}" \
               'The system **shall** rest.')
printf '# Baselines\n\n| Version | Date | Tag | What changed |\n|---|---|---|---|\n' \
    > "$LAB/specs/92-baselines.md"
rule "FR-CHK-220 unreadable history is said to be unread" 0 \
     "no readable history"

# A note and not a warning: --strict must not fail for want of git, which
# this framework does not require of a project.
( cd "$LAB" && python3 tools/srs_check.py --no-write --strict ) \
    > /tmp/srs-rules-nogit.log 2>&1
grep -q "no readable history" /tmp/srs-rules-nogit.log \
    || { echo "FAIL FR-CHK-220 — --strict lost the note"; exit 1; }
absent "strict mode" /tmp/srs-rules-nogit.log

# The other half of the same rule, and the half nothing proved: git answers,
# there are no tags, so there is nothing to say. Told apart from the note
# above only by how git exits, which is why the note being made
# unconditional would leave every fixture in this file green.
#
# Runs before the log below is taken away: without specs/92-baselines.md the
# rule returns before git is asked at all, and the fixture would pass for a
# reason that has nothing to do with what it asserts.
( cd "$LAB" && git init -q . ) > /dev/null 2>&1
silent "FR-CHK-220 a repository with no tags stays silent" 0 \
       "no readable history"

# --- verifies: FR-CHK-130 — a log that is not there has a row for nothing,
# --- which is the condition this rule reports, satisfied for every tag at
# --- once. It used to return before git was asked, so the most complete form
# --- of the defect was the one form answered with silence. Runs here because
# --- it is the one point where git still answers and the log can be taken
# --- away; the tag needs a commit under it, or HEAD does not resolve.
rm -f "$LAB/specs/92-baselines.md"
( cd "$LAB" && git add -A \
  && git -c user.email=ci@example.com -c user.name=CI commit -qm base \
  && git tag spec/v0.1.0 ) > /dev/null 2>&1 \
    || { echo "FAIL FR-CHK-130 — could not put a commit and a tag in the lab,"
         echo "so the rule below would be asserted against no tag"; exit 1; }
rule "FR-CHK-130 a tag with no log at all" 0 \
     "no row for baseline tag spec/v0.1.0"
rule "FR-CHK-130 and it fails a strict gate" 1 "treated as errors" --strict
rm -rf "$LAB/.git"

rm -f "$LAB/specs/92-baselines.md"
passes=$((passes + 2))

# --- verifies: INV-SPEC-080 — a number widens, and nothing is renamed: three
# --- digits or more, no leading zero beyond the third. FR-CORE-1000 is an
# --- identifier and FR-CORE-0100 is not; the two link so that neither is
# --- isolated and the run judges the grammar alone.
config "{$BASE}"
WIDE='status: deferred
verification: I
depends_on: [FR-CORE-020]'
spec < <(block FR-CORE-1000 "The thousandth" "$WIDE" 'The system **shall** go on.'
         block FR-CORE-020 "The partner" "$PARTNER" 'The system **shall** respond.')
silent "INV-SPEC-080 four digits accepted" 0 "identifier does not match"
spec < <(block FR-CORE-0100 "A leading zero" "$WIDE" 'The system **shall** not be.'
         block FR-CORE-020 "The partner" "$PARTNER" 'The system **shall** respond.')
rule "INV-SPEC-080 leading zero refused" 1 "identifier does not match"
# An annotation reaches a wide number too, and stops at the digit boundary:
# `FR-CORE-1000` annotated is not `FR-CORE-100` with a stray digit.
spec < <(block FR-CORE-1000 "The thousandth" "$WIDE" 'The system **shall** go on.'
         block FR-CORE-020 "The partner" "$PARTNER" 'The system **shall** respond.')
printf '# implements: FR-CORE-1000\n' > "$LAB/src/wide.py"    # srs-ignore
python3 - "$LAB" <<'PY' || { echo "FAIL INV-SPEC-080 — the annotation grammar did not read a wide number whole"; exit 1; }
import os, sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(sys.argv[1], "tools"))
import srs_check
found = srs_check.read_annotations(os.path.join(sys.argv[1], "src/wide.py"))
assert found == [(1, "implements", "FR-CORE-1000")], found
PY
rm -f "$LAB/src/wide.py"
passes=$((passes + 1))

# --- verifies: INV-SPEC-090 — identifiers are ordered by their number wherever
# --- a tool orders them: in the matrix FR-CORE-1000 follows FR-CORE-990 and
# --- not FR-CORE-100, in the table, in the incoming links and in the
# --- coverage list. The one-line-per-row grep is what a review tool reads.
printf 'x = 1\n' > "$LAB/src/a.py"
spec < <(block FR-CORE-100 "Hundred" "$PARTNER" 'The system **shall** a.'
         block FR-CORE-1000 "Thousand" 'status: implemented
verification: T
depends_on: [FR-CORE-100]
code: [src/a.py]' 'The system **shall** b.'
         block FR-CORE-990 "Nine ninety" 'status: implemented
verification: T
depends_on: [FR-CORE-100]
code: [src/a.py]' 'The system **shall** c.')
( cd "$LAB" && python3 tools/srs_check.py ) > /tmp/srs-rules.log 2>&1 \
    || { echo "FAIL INV-SPEC-090 — the fixture does not pass the checker"; cat /tmp/srs-rules.log; exit 1; }
python3 - "$LAB/specs/90-traceability.md" <<'PY' || { echo "FAIL INV-SPEC-090 — the matrix orders identifiers as strings"; exit 1; }
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
rows = re.findall(r"^\| \*\*(FR-CORE-\d+)\*\* ", text, re.M)
assert rows[:3] == ["FR-CORE-100", "FR-CORE-990", "FR-CORE-1000"], rows
incoming = re.search(r"\| \*\*FR-CORE-100\*\* \| (.*?) \|", text).group(1)
assert incoming == "FR-CORE-990 (depends_on), FR-CORE-1000 (depends_on)", incoming
untested = re.findall(r"^- \*\*(FR-CORE-\d+)\*\*", text, re.M)
assert untested == ["FR-CORE-990", "FR-CORE-1000"], untested
PY
rm -f "$LAB/src/a.py"
passes=$((passes + 1))

# --- verifies: FR-CHK-250 — an area is read from a file or a directory alike:
# --- requirements under specs/10-fr-core/ at any depth are the area's, a
# --- README.md inside is not read, and the listing names each file.
rm -f "$LAB/specs/10-fr-core.md"
mkdir -p "$LAB/specs/10-fr-core/deeper"
{ printf '# Core — the first thousand\n\n'
  block FR-CORE-010 "In the first file" "$PARTNER" 'The system **shall** a.'; } > "$LAB/specs/10-fr-core/000-999.md"
{ printf '# Core — the second thousand\n\n'
  block FR-CORE-1000 "In the second file" 'status: deferred
verification: I
depends_on: [FR-CORE-010]' 'The system **shall** b.'; } > "$LAB/specs/10-fr-core/1000-1999.md"
{ printf '# Core — deeper\n\n'
  block FR-CORE-020 "Deeper still" 'status: deferred
verification: I
depends_on: [FR-CORE-010]' 'The system **shall** c.'; } > "$LAB/specs/10-fr-core/deeper/notes.md"
{ printf '# About this directory\n\n'
  block FR-CORE-030 "Must not be read" "$PARTNER" 'The system **shall** hide.'; } > "$LAB/specs/10-fr-core/README.md"
( cd "$LAB" && python3 tools/srs_check.py ) > /tmp/srs-rules.log 2>&1 \
    || { echo "FAIL FR-CHK-250 — a directory area does not pass the checker"; cat /tmp/srs-rules.log; exit 1; }
grep -q "Requirements: 3\." /tmp/srs-rules.log \
    || { echo "FAIL FR-CHK-250 — a directory area was not read as three requirements"; cat /tmp/srs-rules.log; exit 1; }
grep -q "FR-CORE-030" "$LAB/specs/90-traceability.md" \
    && { echo "FAIL FR-CHK-250 — a README.md inside the area was read as requirements"; exit 1; }
# The file each requirement is written in is the viewer's to print (FR-VIEW-320);
# the viewer is copied in for this one fixture.
cp tools/srs_view.py "$LAB/tools/"
( cd "$LAB" && python3 tools/srs_view.py --list ) > /tmp/srs-rules-list.log 2>&1
grep -q "FR-CORE-1000 .*specs/10-fr-core/1000-1999.md" /tmp/srs-rules-list.log \
    && grep -q "FR-CORE-020 .*specs/10-fr-core/deeper/notes.md" /tmp/srs-rules-list.log \
    || { echo "FAIL FR-CHK-250 — the listing does not name the files of a directory area"; cat /tmp/srs-rules-list.log; exit 1; }
rm -f "$LAB/tools/srs_view.py"
passes=$((passes + 1))

# --- verifies: FR-CHK-260 — a number outside its file's range is a warning
# --- named file-range, saying where the number belongs. Three fixtures: the
# --- plain file's first number past 999 (the move is in the message), a
# --- range-named file holding a number outside its range, and a file whose
# --- name is no range, which is bound by nothing. Then the rule turned off.
rm -rf "$LAB/specs/10-fr-core"
spec < <(block FR-CORE-1000 "Past the thousand" "$WIDE" 'The system **shall** go on.'
         block FR-CORE-020 "The partner" "$PARTNER" 'The system **shall** respond.')
rule "FR-CHK-260 plain file past 999" 0 "FR-CORE-1000 is past the thousand this file holds; move the file whole to specs/10-fr-core/000-999.md and open 1000-1999.md there"
rule "FR-CHK-260 fails a strict gate" 1 "treated as errors" --strict
rm -f "$LAB/specs/10-fr-core.md"
mkdir -p "$LAB/specs/10-fr-core"
{ printf '# Core\n\n'; block FR-CORE-020 "Filed in the wrong thousand" "$PARTNER" 'The system **shall** a.'
  block FR-CORE-1000 "Filed right" "$WIDE" 'The system **shall** b.'; } > "$LAB/specs/10-fr-core/1000-1999.md"
rule "FR-CHK-260 named file, wrong number" 0 "FR-CORE-020 is outside the range this file's name states (1000-1999); it belongs in 000-999.md beside it"
silent "FR-CHK-260 named file, right number, says nothing of it" 0 "FR-CORE-1000 is"
rm -rf "$LAB/specs/10-fr-core"; mkdir -p "$LAB/specs/10-fr-core"
{ printf '# Core — by subject\n\n'; block FR-CORE-020 "Any number" "$PARTNER" 'The system **shall** a.'
  block FR-CORE-1000 "Any number too" "$WIDE" 'The system **shall** b.'; } > "$LAB/specs/10-fr-core/storage.md"
silent "FR-CHK-260 a file named by subject is bound by nothing" 0 "file-range"
rm -rf "$LAB/specs/10-fr-core"
spec < <(block FR-CORE-1000 "Past the thousand" "$WIDE" 'The system **shall** go on.'
         block FR-CORE-020 "The partner" "$PARTNER" 'The system **shall** respond.')
config "{$BASE, \"rules\": {\"file-range\": \"off\"}}"
silent "FR-CHK-260 turned off says nothing" 0 "file-range"
config "{$BASE}"

echo "checker-rules: $passes fixtures pass"
