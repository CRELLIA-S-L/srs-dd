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
cd "$(dirname "$0")/.."

LAB=/tmp/srs-rules
rm -rf "$LAB"
mkdir -p "$LAB/tools" "$LAB/specs" "$LAB/src" "$LAB/t"
cp tools/srs_check.py "$LAB/tools/"

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

# --- FR-CHK-010: identifiers are well-formed and unique.
spec < <(block FR-CORE-010 "First" "$META" 'The system **shall** act.'
         block FR-CORE-010 "Same number again" "$META" \
               'The system **shall** act twice.')
rule "FR-CHK-010 duplicate" 1 "is already used at"

spec < <(block FR-CORE-1 "Two digits short" "$META" 'The system **shall** act.')
rule "FR-CHK-010 malformed" 1 "identifier does not match"

# --- FR-CHK-020: exactly one bolded modal verb.
spec < <(block FR-CORE-010 "No verb" "$META" 'The system acts, eventually.')
rule "FR-CHK-020 none" 1 "no bolded modal verb"

spec < <(block FR-CORE-010 "Two verbs" "$META" \
               'The system **shall** act and **should** also report.')
rule "FR-CHK-020 two" 1 "modal verbs, expected one"

# --- FR-CHK-030: every link resolves.
spec < <(block FR-CORE-010 "Points at nothing" \
               "${META/depends_on: \[\]/depends_on: [FR-CORE-990]}" \
               'The system **shall** act.')
rule "FR-CHK-030 dangling" 1 "link to nonexistent requirement"

# --- FR-CHK-040: no cycles in the derivation graph.
spec < <(block FR-CORE-010 "Derives from the other" \
               "${META/derives_from: \[\]/derives_from: [FR-CORE-020]}" \
               'The system **shall** act.'
         block FR-CORE-020 "Derives from the first" \
               "${META/derives_from: \[\]/derives_from: [FR-CORE-010]}" \
               'The system **shall** respond.')
rule "FR-CHK-040 cycle" 1 "cycle in"

# --- FR-CHK-050: a realized requirement points at code that exists.
spec < <(block FR-CORE-010 "Names a file that is not there" \
               "$(printf '%s' "${META/status: deferred/status: implemented}" \
                  | sed 's|^code: \[\]$|code: [src/absent.py]|')" \
               'The system **shall** act.')
rule "FR-CHK-050 missing path" 1 "points to a nonexistent path"

spec < <(block FR-CORE-010 "Realized without code" \
               "${META/status: deferred/status: implemented}" \
               'The system **shall** act.')
rule "FR-CHK-050 empty code" 1 "status implemented but the code field is empty"

# --- FR-CHK-060: both halves — a `superseded` without its replacement, and
# --- a replacement named under any other status.
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

# --- FR-CHK-070: implementation ahead of approval is a warning, and only
# --- --strict (FR-CHK-120) turns it into a failure.
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

# --- FR-CHK-075: a realized requirement resting on a draft. It had no
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

# --- FR-CHK-080: annotations are cross-checked against the specification.
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

# And the clause that is easiest to break by accident: a file carrying no
# annotation at all is never mentioned.
rm -f "$LAB/src/app.py"
printf 'print("no annotation here")\n' > "$LAB/src/quiet.py"
silent "FR-CHK-080 silence on an unannotated file" 0 "quiet.py"
rm -f "$LAB/src/quiet.py"

# --- FR-CHK-110: a fenced code block is opaque. The standard itself
# --- documents the format with example requirements inside fences; without
# --- this rule each of them would become a requirement of its own.
spec < <(block FR-CORE-010 "Documents the format" "$META" \
               'The system **shall** act.

````markdown
### FR-CORE-020 — An example inside a fence

The system **shall** never be counted.
````')
rule "FR-CHK-110 opaque fence" 0 "Requirements: 1"

# --- FR-CHK-100: a broken configuration is refused by name, exit 2.
spec < <(block FR-CORE-010 "Valid" "$META" 'The system **shall** act.')
cp "$LAB/specs/srs-config.json" "$LAB/specs/srs-config.json.bak"
printf '{"areas": "CORE"}\n' > "$LAB/specs/srs-config.json"
rule "FR-CHK-100 bad type" 2 "areas must be a list of non-empty strings"
printf '{"areas": ["core"]}\n' > "$LAB/specs/srs-config.json"
rule "FR-CHK-100 bad area" 2 "must match"
printf 'not json at all\n' > "$LAB/specs/srs-config.json"
rule "FR-CHK-100 unparsable" 2 "invalid JSON"
mv "$LAB/specs/srs-config.json.bak" "$LAB/specs/srs-config.json"

# --- FR-CHK-170: a key that is absent is named as absent, not reported
# --- through the value it does not have.
spec < <(block FR-CORE-010 "No verification method" \
               "${META/verification: I/}" 'The system **shall** act.')
rule "FR-CHK-170 names the missing key" 1 \
     "required key 'verification' is missing"
silent "FR-CHK-170 does not blame the value" 1 "method '' is not one of"

# --- FR-CHK-180: a key a later version of the format retired is an error
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

# --- FR-CHK-140: only a requirement that says it is verified by test and
# --- lists none. Two requirements in one specification, because judging
# --- them all by one method is exactly how this went wrong once: the check
# --- sat in a loop that rebinds the requirement but not the method, so a
# --- single stale value was applied to all eighty-five.
PARTIAL='status: partial
verification: I
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
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
rm -f "$LAB/t/probe.sh"

# --- FR-CHK-150: only total isolation. A requirement at either end of a
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

# --- FR-CHK-150: a cancelled requirement is outside the rule, both ways of
# --- being cancelled. `superseded` used to escape only because its
# --- `superseded_by` counts as a link; `withdrawn` names no successor and
# --- so tripped a warning for having done what was intended.
spec < <(block FR-CORE-010 "Withdrawn and isolated" \
               "${META/status: deferred/status: withdrawn}" \
               'The system **shall** have done something dropped.')
silent "FR-CHK-150 spares a withdrawn requirement" 0 \
       "FR-CORE-010 is linked to nothing"

# --- FR-CHK-190: a live requirement resting on a withdrawn one, at every
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

# --- FR-CHK-160: what a rule costs is the project's to set. The rule used
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
cp tools/srs_baseline.py tools/srs_view.py tools/srs_check.py "$LAB2/tools/"
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

echo "checker-rules: $passes fixtures pass"
