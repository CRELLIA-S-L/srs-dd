#!/usr/bin/env bash
# One fixture per rule of the grounds checker, each breaking exactly one
# thing, so a failure names the rule that stopped working.
#
# verifies: FR-GND-020, FR-GND-030, FR-GND-040, FR-GND-050, FR-GND-060,
# verifies: FR-GND-070, FR-GND-080, FR-GND-090, FR-GND-100, FR-GND-110,
# verifies: FR-GND-120, FR-GND-390, FR-GND-400, IF-GND-020, INV-GND-030
# verifies: CON-GND-020, FR-GND-130, FR-GND-220, FR-GND-240
# verifies: FR-GND-260, FR-GND-010, IF-GND-030, FR-GND-250
# verifies: CON-GND-010, FR-GND-190, FR-GND-200, FR-GND-210
# verifies: FR-GND-270, FR-GND-410, FR-GND-420, FR-GND-430
#
# Three of these pass silently if the rule underneath them is deleted, and
# they are the reason this file exists rather than a smoke test: a
# requirement claimed by nobody must stay quiet and non-fatal, two bets on
# one requirement must speak, and a lowered rule must stop failing without
# stopping being computed.
set -eo pipefail

# The lab below is a git-free tree of its own; a hook's environment would
# otherwise follow us into it.
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."
. tools/test_lib.sh

LAB=/tmp/srs-grounds
rm -rf "$LAB"
mkdir -p "$LAB/tools" "$LAB/specs" "$LAB/grounds"
cp tools/srs_grounds.py tools/srs_parse.py tools/srs_check.py \
   tools/srs_view.py "$LAB/tools/"

cat > "$LAB/specs/srs-config.json" <<'JSON'
{
  "areas": ["CORE"],
  "code_roots": ["src"],
  "test_roots": ["t"],
  "code_extensions": [".py"],
  "rules": {"unlinked": "off", "test-missing": "off"}
}
JSON

# Two requirements the bets can point at, one of them cancelled.
cat > "$LAB/specs/10-fr-core.md" <<'MD'
# Functional requirements — core

### FR-CORE-010 — The system acts

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
```

The system **shall** act.

### FR-CORE-020 — Cancelled with nothing to replace it

```yaml
status: withdrawn
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
```

The system **shall** have done something nobody wants now.

**Rationale.** Withdrawn so a bet can stand on a cancelled requirement.
MD

printf '{\n  "rules": {}\n}\n' > "$LAB/grounds/grounds-config.json"

# The register under test. Everything after the heading is whatever the
# fixture pipes in, so a fixture reads as the one thing it breaks.
ground() {
    { printf '# Grounds under test\n\n'; cat; } > "$LAB/grounds/10-h-test.md"
}

# A record: id, title, metadata lines, statement.
rec() {
    printf '### %s — %s\n\n```yaml\n%s\n```\n\n%s\n\n' "$1" "$2" "$3" "$4"
}

HYP='status: assumed
class: III
population: studios of five to fifty people
refuted_if: proportion < 0.25 at n >= 200
expires: 2099-01-01
owner: @someone
impact: about a third of the 2027 plan'

passes=0

# rule <name> <expected exit> <message fragment> [flags…]
rule() {
    local name=$1 want=$2 msg=$3; shift 3
    local rc=0
    ( cd "$LAB" && python3 tools/srs_grounds.py --no-write "$@" ) \
        > /tmp/srs-grounds.log 2>&1 || rc=$?
    if [ "$rc" != "$want" ]; then
        echo "FAIL $name — exit $rc, expected $want"; cat /tmp/srs-grounds.log
        exit 1
    fi
    if ! grep -qF "$msg" /tmp/srs-grounds.log; then
        echo "FAIL $name — no message matching: $msg"; cat /tmp/srs-grounds.log
        exit 1
    fi
    passes=$((passes + 1))
}

# silent <name> <expected exit> <fragment that must NOT appear>
silent() {
    local name=$1 want=$2 msg=$3 rc=0
    ( cd "$LAB" && python3 tools/srs_grounds.py --no-write ) \
        > /tmp/srs-grounds.log 2>&1 || rc=$?
    if [ "$rc" != "$want" ]; then
        echo "FAIL $name — exit $rc, expected $want"; cat /tmp/srs-grounds.log
        exit 1
    fi
    if grep -qF "$msg" /tmp/srs-grounds.log; then
        echo "FAIL $name — said something it should not: $msg"
        cat /tmp/srs-grounds.log; exit 1
    fi
    passes=$((passes + 1))
}

# --- verifies: FR-GND-020 — identifiers are well-formed and unique.
ground < <(rec H-1 "Two digits short" "$HYP" 'Studios export weekly.')
rule "FR-GND-020 malformed" 1 "identifier does not match <KIND>-<NNN>"

ground < <(rec X-010 "A kind the standard does not define" "$HYP" 'Studios export.')
rule "FR-GND-020 unknown kind" 1 "identifier does not match <KIND>-<NNN>"

ground < <(rec H-010 "First" "$HYP" 'Studios export weekly.'
           rec H-010 "Same number again" "$HYP" 'Studios import weekly.')
rule "FR-GND-020 duplicate" 1 "H-010 is already used at"

# --- verifies: FR-GND-030 — a missing required key is named as missing.
ground < <(rec H-010 "No impact declared" "${HYP/impact: about a third of the 2027 plan/}" \
               'Studios export weekly.')
rule "FR-GND-030 missing key" 1 "is missing the required key 'impact'"

# --- verifies: FR-GND-390 — a status the format does not define.
ground < <(rec H-010 "Status from nowhere" "${HYP/status: assumed/status: probably}" \
               'Studios export weekly.')
rule "FR-GND-390 bad status" 1 "carries status 'probably'"

# A class the format does not define is the quietest of the three: the core
# is reported by class, so the hypothesis vanishes from every row while the
# register plainly holds it.
ground < <(rec H-010 "Class from nowhere" \
               "${HYP/class: III/class: 4}" 'Studios export weekly.')
rule "FR-GND-390 bad class" 1 "carries class '4'"

# Shaped like a date, impossible as one. Before this was checked it did not
# report anything — it raised, which is neither a finding nor an exit code.
ground < <(rec H-010 "A date that cannot exist" \
               "${HYP/expires: 2099-01-01/expires: 2026-13-45}" \
               'Studios export weekly.')
rule "FR-GND-390 impossible date" 1 "carries expires '2026-13-45'"

# One identifier where the format defines one. A bracketed list here used to
# reach a dict as a key and raise, which is not an exit code.
ground < <(rec H-010 "Ground" "$HYP" 'Studios export weekly.'
           rec B-010 "A bracketed requirement" 'status: active
requirement: [FR-CORE-010]
all_of: [H-010]' 'Something rests on H-010.')
rule "FR-GND-390 requirement is not a list" 1 "not a list"

# A threshold nobody can apply twice the same way. Nothing in phase one
# reads this field, which is exactly why it needs guarding: a malformed one
# would lie in the register untouched until the day something depends on it.
ground < <(rec H-010 "A threshold in prose" \
               "${HYP/refuted_if: proportion < 0.25 at n >= 200/refuted_if: fewer than a quarter of them}" \
               'Studios export weekly.')
rule "FR-GND-390 threshold grammar" 1 "is not the grammar the format defines"

ground < <(rec H-010 "A comparison the format does not name" \
               "${HYP/proportion < 0.25 at n >= 200/proportion = 0.25 at n >= 200}" \
               'Studios export weekly.')
rule "FR-GND-390 threshold operator" 1 "is not the grammar the format defines"

# --- verifies: FR-GND-410 — a row carries the columns its heading declares.
# --- Within a row position is all there is, so a missing cell shifts the
# --- rest: before this, such a row was silently skipped and the author whose
# --- verdict fell out stopped appearing in the count of reversals.
ground < <(rec H-010 "One cell short" "$HYP" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-02-14 | 0.38 | 42 | supported |')
rule "FR-GND-410 short row" 1 "has a table row with 4 cell(s) where its heading declares 5"

# --- verifies: FR-GND-040 — a bet resolves into the requirement model.
ground < <(rec H-010 "Ground" "$HYP" 'Studios export weekly.'
           rec B-010 "Points outside the model" \
               'status: active
requirement: FR-CORE-990
all_of: [H-010]' 'FR-CORE-990 rests on H-010.')
rule "FR-GND-040 absent requirement" 1 "which is not in the requirement model"

# --- verifies: FR-GND-400 — and into the register.
ground < <(rec H-010 "Ground" "$HYP" 'Studios export weekly.'
           rec B-010 "Points at no hypothesis" \
               'status: active
requirement: FR-CORE-010
all_of: [H-990]' 'FR-CORE-010 rests on H-990.')
rule "FR-GND-400 absent hypothesis" 1 "names hypothesis H-990"

# The other half of FR-GND-040: a declaration names a requirement too, and
# one pointing at nothing says a requirement rests on nothing while there is
# no such requirement — which reads from outside exactly like the honest
# declaration this layer exists to encourage.
ground < <(printf '### U-010 — Points at nothing\n\n```yaml\nstatus: active\nrequirement: FR-CORE-999\n```\n\nNobody could name a ground for this.\n\n')
rule "FR-GND-040 declaration points outside" 1 "U-010 names requirement FR-CORE-999"

# --- verifies: FR-GND-050 — a bet on a cancelled requirement, and it is a
# --- warning: the requirement's cancellation is not the register's error.
ground < <(rec H-010 "Ground" "$HYP" 'Studios export weekly.'
           rec B-010 "Stands on a withdrawn requirement" \
               'status: active
requirement: FR-CORE-020
all_of: [H-010]' 'FR-CORE-020 rests on H-010.')
rule "FR-GND-050 cancelled" 0 "which is withdrawn"
rule "FR-GND-050 fails under strict" 1 "which is withdrawn" --strict

# --- verifies: FR-GND-060 — a hypothesis past its term.
ground < <(rec H-010 "Term ran out" "${HYP/expires: 2099-01-01/expires: 2020-01-01}" \
               'Studios export weekly.')
rule "FR-GND-060 expired" 0 "ran out of term on 2020-01-01"

# --- verifies: FR-GND-080 — two bets on one requirement.
ground < <(rec H-010 "One" "$HYP" 'Studios export weekly.'
           rec H-020 "Two" "$HYP" 'Studios import weekly.'
           rec B-010 "First set" 'status: active
requirement: FR-CORE-010
any_of: [H-010]' 'FR-CORE-010 rests on H-010.'
           rec B-020 "Second set" 'status: active
requirement: FR-CORE-010
any_of: [H-020]' 'FR-CORE-010 also rests on H-020.')
rule "FR-GND-080 two bets" 0 "is named by more than one bet"
grep -E "^warning: grounds/10-h-test\.md:[0-9]+ .*named by more than one bet" \
     /tmp/srs-grounds.log > /dev/null \
    || { echo "FAIL FR-GND-080 — the finding points at no record"
         cat /tmp/srs-grounds.log; exit 1; }
passes=$((passes + 1))

# --- A register file saved in some other encoding is a defect to report,
# --- not a stack trace to decipher. The same answer the specification
# --- checker gives, and the reason this is asserted: it used to raise.
printf '# g\n\n### H-010 \xff\xfe Latin-1 in a heading\n\n' \
    > "$LAB/grounds/10-h-test.md"
rule "FR-GND-010 unreadable encoding" 1 "cannot read the file"

# --- verifies: FR-GND-010 — every record, and a register that grows a
# --- folder is not exempt. A file one directory down used to be invisible:
# --- two records and a duplicate identifier read as "Records: 0".
rm -f "$LAB/grounds/10-h-test.md"
mkdir -p "$LAB/grounds/product"
{ printf '# deeper\n\n'
  rec H-010 "One directory down" "$HYP" 'Studios export weekly.'
} > "$LAB/grounds/product/10-h-deep.md"
rule "FR-GND-010 reads a subdirectory" 0 "Records: 1"
rm -rf "$LAB/grounds/product"

# --- verifies: FR-GND-090 — a declaration carries a reason.
ground < <(printf '### U-010 — No reason given\n\n```yaml\nstatus: active\nrequirement: FR-CORE-010\n```\n\n')
rule "FR-GND-090 no reason" 1 "gives no reason"

# --- verifies: FR-GND-100 — and retires itself when a bet turns up.
ground < <(rec H-010 "Ground" "$HYP" 'Studios export weekly.'
           rec B-010 "A real bet" 'status: active
requirement: FR-CORE-010
all_of: [H-010]' 'FR-CORE-010 rests on H-010.'
           rec U-010 "Says it rests on nothing" \
               'status: active
requirement: FR-CORE-010' 'Nobody could name a ground for this.')
rule "FR-GND-100 superfluous" 0 "declares FR-CORE-010 unclaimed, and B-010 names it"

# --- verifies: FR-GND-420 — the status says nobody relies on it and a bet
# --- says otherwise. The direction matters: `untested` is outside the debt
# --- count and `assumed` is inside it, so the mislabelling always reads as
# --- less debt than there is.
ground < <(rec H-010 "Nobody relies on it, allegedly" \
               "${HYP/status: assumed/status: untested}" 'Studios export.'
           rec B-010 "Except this" 'status: active
requirement: FR-CORE-010
all_of: [H-010]' 'FR-CORE-010 rests on H-010.')
rule "FR-GND-420 relied on while untested" 0 "which says nobody relies on it"

# --- And an `assumed` hypothesis with the same bet says nothing: that is
# --- the honest state, not a defect.
ground < <(rec H-010 "Taken on faith, openly" "$HYP" 'Studios export.'
           rec B-010 "The bet" 'status: active
requirement: FR-CORE-010
all_of: [H-010]' 'FR-CORE-010 rests on H-010.')
silent "FR-GND-420 assumed is honest" 0 "which says nobody relies on it"

# --- verifies: FR-GND-430 — built on, term passed, never measured at all.
# --- Distinct from the expiry rule: that one cannot tell "measured long
# --- ago" from "never measured", and the two are answered differently.
ground < <(rec H-010 "Nobody ever checked" \
               "${HYP/expires: 2099-01-01/expires: 2020-01-01}" 'Studios export.'
           rec B-010 "Built anyway" 'status: active
requirement: FR-CORE-010
all_of: [H-010]' 'FR-CORE-010 rests on H-010.')
rule "FR-GND-430 never measured" 0 "with no measurement recorded at all"
# One record, one line: the expiry rule steps aside for the more specific
# one rather than saying the same thing first.
absent "ran out of term on 2020-01-01" /tmp/srs-grounds.log
passes=$((passes + 1))

# But the lever must not silence both. A project that turned off the
# specific rule has not turned off the general one.
printf '{"rules": {"never-measured": "off"}}\n' > "$LAB/grounds/grounds-config.json"
rule "FR-GND-430 silenced, expiry returns" 0 "ran out of term on 2020-01-01"
printf '{\n  "rules": {}\n}\n' > "$LAB/grounds/grounds-config.json"

# --- The same hypothesis measured once, long ago, is the other case: past
# --- its term and reported as such, but not as never measured.
ground < <(rec H-010 "Measured once, long ago" \
               "${HYP/expires: 2099-01-01/expires: 2020-01-01}" \
               'Studios export.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2019-06-01 | 0.38 | 42 | supported | @kira |'
           rec B-010 "Built on it" 'status: active
requirement: FR-CORE-010
all_of: [H-010]' 'FR-CORE-010 rests on H-010.')
silent "FR-GND-430 measured once is not never" 0 "with no measurement recorded at all"

# --- verifies: INV-GND-030 — a requirement no bet names is not an error and
# --- not a warning. This fixture passes if the rule protecting it is
# --- deleted, which is exactly why it is written down: the load-bearing
# --- detector of this layer is the requirement standing on nothing, and a
# --- layer that demanded a bet would destroy it.
ground < <(rec H-010 "Ground for nothing in particular" "$HYP" 'Studios export weekly.')
silent "INV-GND-030 unclaimed is not a defect" 0 "FR-CORE-010"

# --- verifies: FR-GND-070 — the weakest necessary hypothesis decides, and
# --- the strongest alternative does. The reduction is visible only on the
# --- dashboard, so these two write one and read the answer back out.
SUPPORTED="${HYP/status: assumed/status: supported}"
REFUTED="${HYP/status: assumed/status: refuted}"

reduce() {   # reduce <field> -> the status the dashboard says decides
    ground < <(rec H-010 "Holds" "$SUPPORTED" 'Studios export weekly.'
               rec H-020 "Does not" "$REFUTED" 'Studios import weekly.'
               rec B-010 "The bet" "status: active
requirement: FR-CORE-010
$1: [H-010, H-020]" 'FR-CORE-010 rests on both.')
    ( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
    grep -F "| FR-CORE-010 |" "$LAB/grounds/90-dashboard.md" | head -1
}

got=$(reduce all_of)
case "$got" in
    *refuted*) passes=$((passes + 1)) ;;
    *) echo "FAIL FR-GND-070 all_of — the weakest must decide, got: $got"
       exit 1 ;;
esac

got=$(reduce any_of)
case "$got" in
    *supported*) passes=$((passes + 1)) ;;
    *) echo "FAIL FR-GND-070 any_of — the strongest must decide, got: $got"
       exit 1 ;;
esac

# --- verifies: CON-GND-020 — the dashboard is produced by the checker, and
# --- --no-write leaves it exactly as it was.
before=$(cksum < "$LAB/grounds/90-dashboard.md")
ground < <(rec H-030 "A record the dashboard has never seen" "$HYP" 'Studios archive.')
( cd "$LAB" && python3 tools/srs_grounds.py --no-write ) > /dev/null 2>&1
[ "$(cksum < "$LAB/grounds/90-dashboard.md")" = "$before" ] \
    || { echo "FAIL CON-GND-020 — --no-write rewrote the dashboard"; exit 1; }
( cd "$LAB" && python3 tools/srs_grounds.py ) > /dev/null 2>&1
[ "$(cksum < "$LAB/grounds/90-dashboard.md")" != "$before" ] \
    || { echo "FAIL CON-GND-020 — a write left the dashboard unchanged"; exit 1; }
passes=$((passes + 2))
rm -f "$LAB/grounds/90-dashboard.md"

# --- verifies: FR-GND-110 — what a rule costs is the project's to set.
ground < <(rec H-010 "Term ran out" "${HYP/expires: 2099-01-01/expires: 2020-01-01}" \
               'Studios export weekly.')
printf '{"rules": {"hypothesis-expired": "report"}}\n' > "$LAB/grounds/grounds-config.json"
rule "FR-GND-110 lowered to report" 0 "report: " --strict
printf '{"rules": {"hypothesis-expired": "off"}}\n' > "$LAB/grounds/grounds-config.json"
silent "FR-GND-110 silenced" 0 "ran out of term"
printf '{"rules": {"no-such-rule": "warn"}}\n' > "$LAB/grounds/grounds-config.json"
rule "FR-GND-110 unknown rule" 2 "known rules are"
printf '{"rules": {"hypothesis-expired": "loud"}}\n' > "$LAB/grounds/grounds-config.json"
rule "FR-GND-110 unknown severity" 2 "severity must be one of"
printf '{\n  "rules": {}\n}\n' > "$LAB/grounds/grounds-config.json"

# --- verifies: FR-GND-130 — the debt, as a share and not just a list. The
# --- share passed every fixture in this file while it was hard-coded to
# --- zero, which is what a number nobody asserts is worth.
ground < <(rec H-010 "Held" "${HYP/status: assumed/status: supported}" 'Studios export.'
           rec H-020 "Did not" "${HYP/status: assumed/status: refuted}" 'Studios import.'
           rec B-010 "On the one that held" 'status: active
requirement: FR-CORE-010
all_of: [H-010]' 'FR-CORE-010 rests on H-010.'
           rec B-020 "On the one that did not" 'status: active
requirement: FR-CORE-020
all_of: [H-020]' 'FR-CORE-020 rests on H-020.')
( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
grep -qF "2 rest on hypotheses" "$LAB/grounds/90-dashboard.md" \
    && { echo "FAIL FR-GND-130 — a supported ground was counted as debt"
         cat "$LAB/grounds/90-dashboard.md"; exit 1; }
grep -qF "1 rest on hypotheses" "$LAB/grounds/90-dashboard.md" \
    || { echo "FAIL FR-GND-130 — the debt count is wrong"
         cat "$LAB/grounds/90-dashboard.md"; exit 1; }
grep -qF "\`assumed\` — 50%." "$LAB/grounds/90-dashboard.md" \
    || { echo "FAIL FR-GND-130 — the debt share is wrong"
         cat "$LAB/grounds/90-dashboard.md"; exit 1; }
passes=$((passes + 3))
rm -f "$LAB/grounds/90-dashboard.md"

# --- verifies: FR-GND-240, FR-GND-260, FR-GND-220 — the readings the
# --- dashboard exists for. Generated output that nothing reads is output
# --- that drifts, and each of these is a number somebody would act on.
ground < <(rec I-010 "For studios" 'status: active
admissible_arguments: [a cohort measurement, a frame refusal]' \
               'We are for studios of five to fifty people.'
           rec I-020 "And for their clients" 'status: active
admissible_arguments: [a cohort measurement]' \
               'We are also for the people who receive their reports.'
           rec H-010 "Measured twice" "${HYP/status: assumed/status: supported}" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-02-14 | 0.38 | 42 | supported | @kira |
| 2026-08-01 | 0.41 | 210 | supported | telemetry |')
( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
D="$LAB/grounds/90-dashboard.md"

grep -qF "Ideologies: 2." "$D" \
    || { echo "FAIL FR-GND-260 — the ideology count is wrong"; cat "$D"; exit 1; }
passes=$((passes + 1))

grep -qF "| III | 1 | 2026-02-14 | 2026-08-01 |" "$D" \
    || { echo "FAIL FR-GND-240 — the core's confirmations by class are wrong"
         cat "$D"; exit 1; }
passes=$((passes + 1))

# Nothing is staked here, so every requirement rests on nothing — which is
# the honest reading of a register with no bets in it, not an empty list.
grep -qF "2 of 2 requirements" "$D" \
    || { echo "FAIL FR-GND-220 — the unclaimed count is wrong"; cat "$D"; exit 1; }
grep -qE "^\| FR-CORE-010 \| [0-9]+ \| [0-9]+ \| [0-9]+ \|$" "$D" \
    || { echo "FAIL FR-GND-220 — no weight row for FR-CORE-010"; cat "$D"; exit 1; }
passes=$((passes + 2))
rm -f "$D"

# --- verifies: FR-GND-250 — a frame's whole value is in what it turned
# --- down, and the second table proves the rule that tables are found by
# --- their heading: the amendment table is written first on purpose.
ground < <(printf '### F-010 — No regulatory surface we cannot staff\n\n```yaml\nstatus: active\n```\n\nWe do not take on what we cannot support.\n\n| date | what changed | why | territory it opens |\n|---|---|---|---|\n| 2026-06-01 | narrowed to payroll | one refusal | nothing yet |\n\n| date | what was refused | who asked |\n|---|---|---|\n| 2026-05-02 | selling timing data to tool vendors | growth |\n\n'
           printf '### F-020 — Nothing has tested this one\n\n```yaml\nstatus: active\n```\n\nWe do not grow by making the thing worse.\n\n')
( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
D="$LAB/grounds/90-dashboard.md"
grep -qF "selling timing data to tool vendors" "$D" \
    || { echo "FAIL FR-GND-250 — the refusal journal is not on the dashboard"
         cat "$D"; exit 1; }
absent "narrowed to payroll" "$D"
grep -qF "Nothing recorded." "$D" \
    || { echo "FAIL FR-GND-250 — a frame that refused nothing says nothing"
         cat "$D"; exit 1; }
passes=$((passes + 3))

# --- verifies: CON-GND-010 — the layer writes nowhere else. Every file is
# --- weighed before and after a run that does write, and the dashboard is
# --- the only one allowed to move.
# ---
# --- In a tree the checker has never run in, and that is the whole point:
# --- weighed inside the lab above, a file left behind by an earlier
# --- fixture's run sits in both snapshots and the assertion cannot fail.
LAB4=/tmp/srs-grounds-write
rm -rf "$LAB4"; mkdir -p "$LAB4/tools" "$LAB4/specs" "$LAB4/grounds"
cp tools/srs_grounds.py tools/srs_parse.py tools/srs_check.py \
   tools/srs_view.py "$LAB4/tools/"
cp "$LAB/specs/srs-config.json" "$LAB/specs/10-fr-core.md" "$LAB4/specs/"
cp "$LAB/grounds/grounds-config.json" "$LAB4/grounds/"
{ printf '# g\n\n'; rec H-010 "Ground" "$HYP" 'Studios export weekly.'
} > "$LAB4/grounds/10-h-test.md"
weigh() { ( cd "$LAB4" && find . -type f ! -name 90-dashboard.md \
            -exec cksum {} \; | sort ); }
weigh > /tmp/srs-grounds-before
( cd "$LAB4" && python3 tools/srs_grounds.py ) > /dev/null 2>&1
[ -f "$LAB4/grounds/90-dashboard.md" ] \
    || { echo "FAIL CON-GND-010 — the run wrote no dashboard, so this"
         echo "assertion would hold for a checker that did nothing"; exit 1; }
weigh > /tmp/srs-grounds-after
cmp -s /tmp/srs-grounds-before /tmp/srs-grounds-after \
    || { echo "FAIL CON-GND-010 — a run touched something outside the register"
         diff /tmp/srs-grounds-before /tmp/srs-grounds-after | head -10; exit 1; }
passes=$((passes + 2))
rm -f "$D"

# --- verifies: FR-GND-210 — how often an author's verdict was reversed,
# --- read from the evidence table and not from history.
ground < <(rec H-010 "Measured twice, differently" \
               "${HYP/status: assumed/status: refuted}" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-02-14 | 0.38 | 42 | supported | @kira |
| 2026-08-01 | 0.09 | 210 | refuted | telemetry |')
( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
D="$LAB/grounds/90-dashboard.md"
grep -qF "| @kira | 1 | 1 |" "$D" \
    || { echo "FAIL FR-GND-210 — the reversed verdict was not counted"
         cat "$D"; exit 1; }
grep -qF "| telemetry | 1 | 0 |" "$D" \
    || { echo "FAIL FR-GND-210 — the last verdict counts as reversed"
         cat "$D"; exit 1; }
passes=$((passes + 2))
rm -f "$D"

# --- verifies: FR-GND-270 — a rule that needs history and cannot read it
# --- says so rather than passing. This lab is deliberately not a
# --- repository, so the two history rules meet that wall here.
ground < <(rec H-010 "Ground" "$HYP" 'Studios export weekly.')
rule "FR-GND-270 no history" 0 "did not run, which is not the same as passing"

# --- verifies: FR-GND-190, FR-GND-200 — the two rules that read the
# --- register's history. A lab of their own, because they need one.
HLAB=/tmp/srs-grounds-history
rm -rf "$HLAB"; mkdir -p "$HLAB/tools" "$HLAB/specs" "$HLAB/grounds"
cp tools/srs_grounds.py tools/srs_parse.py tools/srs_check.py \
   tools/srs_view.py "$HLAB/tools/"
cp "$LAB/specs/srs-config.json" "$LAB/specs/10-fr-core.md" "$HLAB/specs/"
cp "$LAB/grounds/grounds-config.json" "$HLAB/grounds/"
( cd "$HLAB" && git init -q . && git config user.email t@t \
  && git config user.name t )

hyp_at() {   # hyp_at <threshold> <evidence rows…>
    { printf '### H-010 — Studios lose time\n\n```yaml\nstatus: assumed\nclass: III\npopulation: studios of five to fifty people\nrefuted_if: %s\nexpires: 2099-01-01\nowner: @kira\nimpact: a third of the plan\n```\n\nStudios export weekly.\n\n' "$1"
      shift
      if [ "$#" -gt 0 ]; then
          printf '| date | value | n | verdict | by |\n|---|---|---|---|---|\n'
          for row in "$@"; do printf '%s\n' "$row"; done
      fi
    } > "$HLAB/grounds/10-h-test.md"
}
commit_lab() { ( cd "$HLAB" && git add -A && git commit -qm "$1" ); }
history_run() {
    ( cd "$HLAB" && python3 tools/srs_grounds.py --no-write ) \
        > /tmp/srs-history.log 2>&1 || true
}

# A threshold declared, then a measurement under it, then the threshold
# moved: the ordering only exists in the history.
hyp_at "proportion < 0.25 at n >= 200"; commit_lab "declared"
hyp_at "proportion < 0.25 at n >= 200" "| 2026-02-14 | 0.38 | 42 | supported | @kira |"
commit_lab "measured"
hyp_at "proportion < 0.05 at n >= 200" "| 2026-02-14 | 0.38 | 42 | supported | @kira |"
commit_lab "moved"
history_run
grep -qF "had its threshold changed after the first measurement" /tmp/srs-history.log \
    || { echo "FAIL FR-GND-190 — a threshold moved after the first"
         echo "measurement was not reported"; cat /tmp/srs-history.log; exit 1; }
passes=$((passes + 1))

# The same edit made before any measurement is not that. This is the
# assertion the rule would pass without: reporting every threshold that
# ever changed would satisfy the one above and mean nothing.
rm -rf "$HLAB/.git"; ( cd "$HLAB" && git init -q . && git config user.email t@t \
  && git config user.name t )
hyp_at "proportion < 0.25 at n >= 200"; commit_lab "declared"
hyp_at "proportion < 0.10 at n >= 200"; commit_lab "reconsidered before measuring"
hyp_at "proportion < 0.10 at n >= 200" "| 2026-02-14 | 0.38 | 42 | supported | @kira |"
commit_lab "measured"
history_run
grep -qF "had its threshold changed after" /tmp/srs-history.log \
    && { echo "FAIL FR-GND-190 — a threshold settled before the first"
         echo "measurement was reported anyway"; cat /tmp/srs-history.log; exit 1; }
passes=$((passes + 1))

# Moved in the very commit that records the first measurement: the same
# abuse in one step instead of two. Inside a commit there is no ordering,
# so this has to count as "after".
rm -rf "$HLAB/.git"; ( cd "$HLAB" && git init -q . && git config user.email t@t \
  && git config user.name t )
hyp_at "proportion < 0.25 at n >= 200"; commit_lab "declared"
hyp_at "proportion < 0.05 at n >= 200" "| 2026-02-14 | 0.38 | 42 | supported | @kira |"
commit_lab "measured and moved in one go"
history_run
grep -qF "had its threshold changed after" /tmp/srs-history.log \
    || { echo "FAIL FR-GND-190 — a threshold moved in the commit that"
         echo "records the first measurement was not reported"
         cat /tmp/srs-history.log; exit 1; }
passes=$((passes + 1))

# And a hypothesis born with its first measurement is not that: declaring a
# threshold is not moving one, and without this the rule above would fire on
# every hypothesis whose first commit carries a result.
rm -rf "$HLAB/.git"; ( cd "$HLAB" && git init -q . && git config user.email t@t \
  && git config user.name t )
hyp_at "proportion < 0.25 at n >= 200" "| 2026-02-14 | 0.38 | 42 | supported | @kira |"
commit_lab "born measured"
history_run
grep -qF "had its threshold changed after" /tmp/srs-history.log \
    && { echo "FAIL FR-GND-190 — a hypothesis born with its first"
         echo "measurement was reported as having moved its threshold"
         cat /tmp/srs-history.log; exit 1; }
passes=$((passes + 1))

# A measurement that was recorded and is not there now.
hyp_at "proportion < 0.10 at n >= 200" \
    "| 2026-02-14 | 0.38 | 42 | supported | @kira |" \
    "| 2026-08-01 | 0.09 | 210 | refuted | telemetry |"
commit_lab "measured twice"
hyp_at "proportion < 0.10 at n >= 200" \
    "| 2026-08-01 | 0.09 | 210 | refuted | telemetry |"
commit_lab "one row quietly gone"
history_run
grep -qF "once recorded the measurement" /tmp/srs-history.log \
    || { echo "FAIL FR-GND-200 — a deleted measurement was not reported"
         cat /tmp/srs-history.log; exit 1; }
passes=$((passes + 1))

# Deleting the record takes its measurements with it, which is the easiest
# way to make an inconvenient one disappear and the case the rule above
# cannot see: that one walks the records that are still here.
rm -rf "$HLAB/.git"; ( cd "$HLAB" && git init -q . && git config user.email t@t \
  && git config user.name t )
hyp_at "proportion < 0.10 at n >= 200" \
    "| 2026-02-14 | 0.38 | 42 | supported | @kira |"
commit_lab "measured"
printf '# nothing here now\n' > "$HLAB/grounds/10-h-test.md"
commit_lab "record deleted whole"
history_run
grep -qF "no longer in the register at all" /tmp/srs-history.log \
    || { echo "FAIL FR-GND-200 — a record deleted with its evidence was not"
         echo "reported"; cat /tmp/srs-history.log; exit 1; }
passes=$((passes + 1))

# And a shallow clone says so rather than passing both rules in silence.
rm -rf /tmp/srs-grounds-shallow
git clone -q --depth 1 "file://$HLAB" /tmp/srs-grounds-shallow 2>/dev/null
( cd /tmp/srs-grounds-shallow && python3 tools/srs_grounds.py --no-write ) \
    > /tmp/srs-shallow.log 2>&1 || true
grep -qF "the clone is shallow" /tmp/srs-shallow.log \
    || { echo "FAIL FR-GND-270 — a shallow clone did not say so"
         cat /tmp/srs-shallow.log; exit 1; }
passes=$((passes + 1))

# --- verifies: IF-GND-020 — the exit codes a gate binds to.
ground < <(rec H-010 "Ground" "$HYP" 'Studios export weekly.')
rule "IF-GND-020 clean" 0 "Errors: 0"
rule "IF-GND-020 unknown flag" 2 "unknown flag(s): --bogus" --bogus
# A tree with the tooling and no register at all. Its own directory, not
# this lab: the checker locates the register from where the script sits, the
# way the specification checker locates specs/, so a cd proves nothing.
LAB2=/tmp/srs-grounds-none
rm -rf "$LAB2"; mkdir -p "$LAB2/tools"
cp tools/srs_grounds.py tools/srs_parse.py "$LAB2/tools/"
rc=0
( cd "$LAB2" && python3 tools/srs_grounds.py --no-write ) \
    > /tmp/srs-grounds.log 2>&1 || rc=$?
[ "$rc" = 2 ] || { echo "FAIL IF-GND-020 no register — exit $rc, expected 2"
                   cat /tmp/srs-grounds.log; exit 1; }
grep -qF "no grounds/ directory" /tmp/srs-grounds.log \
    || { echo "FAIL IF-GND-020 no register — wrong message"
         cat /tmp/srs-grounds.log; exit 1; }
passes=$((passes + 2))

echo "grounds-rules: $passes fixtures pass"
