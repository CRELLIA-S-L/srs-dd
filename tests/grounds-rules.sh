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
# verifies: FR-GND-510, FR-GND-520
# verifies: FR-GND-270, FR-GND-410, FR-GND-420, FR-GND-430
# verifies: FR-GND-160, FR-GND-170, FR-GND-180, FR-GND-450
# verifies: FR-GND-460, FR-GND-470, FR-GND-230, FR-GND-140
# verifies: FR-GND-150, FR-GND-490
#
# Three of these pass silently if the rule underneath them is deleted, and
# they are the reason this file exists rather than a smoke test: a
# requirement claimed by nobody must stay quiet and non-fatal, two bets on
# one requirement must speak, and a lowered rule must stop failing without
# stopping being computed.
set -eo pipefail

# implements: FR-CI-090
# The lab below is a tree of its own, and the history fixtures run `git
# init` and commit inside it; a hook's environment would otherwise follow
# us there and the commits would land in the one being prepared.
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
cp "$LAB/specs/10-fr-core.md" /tmp/srs-grounds-core.md

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

# --- verifies: FR-GND-450 — and the heading itself is the one the format
# --- declares. Found by its marker column, read by position from there: a
# --- table headed `date | verdict | by` is found and then read as though
# --- the verdict were the fourth cell of a three-cell row. Nothing errored
# --- before this; the rows were skipped and every reading over them came
# --- out empty while the register plainly held the measurements.
ground < <(rec H-010 "Its own idea of an evidence table" "$HYP" \
               'Studios export weekly.

| date | verdict | by |
|---|---|---|
| 2026-02-14 | supported | @kira |')
rule "FR-GND-450 heading of its own" 1 "the format declares | date | value | n | verdict | by |"

# A table carrying none of the marker columns is one the format has not
# named, and it is nobody's business but the record's.
ground < <(rec H-010 "A table of its own, for a reader" "$HYP" \
               'Studios export weekly.

| segment | note |
|---|---|
| enterprise | out of scope for now |')
silent "FR-GND-450 an unnamed table is left alone" 0 "the format declares"

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

# --- verifies: FR-GND-160 — a class III verdict names who made it. The
# --- hook FR-GND-210 needs: an author whose verdicts keep being reversed
# --- cannot be noticed if the verdicts are anonymous.
ground < <(rec H-010 "Judged by nobody in particular" "$HYP" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-02-14 | 0.38 | 42 | supported |  |')
rule "FR-GND-160 unattributed" 0 "a verdict with nobody named"

# Class I is a machine reading and needs no name.
ground < <(rec H-010 "Measured by an instrument" "${HYP/class: III/class: I}" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-02-14 | 0.38 | 42 | supported |  |')
silent "FR-GND-160 class I needs no name" 0 "a verdict with nobody named"

# --- verifies: FR-GND-170 — a grade permits only the actions declared for
# --- it, and the map is the project's own.
printf '{"rules": {}, "grades": {"low": ["experiment"], "high": ["release"]}}\n' \
    > "$LAB/grounds/grounds-config.json"
ground < <(rec H-010 "Weak evidence, strong action" \
               "$HYP
grade: low
action: release" 'Studios export weekly.')
rule "FR-GND-170 beyond its grade" 0 "which that grade does not permit here"

ground < <(rec H-010 "Weak evidence, matching action" \
               "$HYP
grade: low
action: experiment" 'Studios export weekly.')
silent "FR-GND-170 within its grade" 0 "which that grade does not permit here"

# A grade the map says nothing about permits anything — the project has not
# expressed an appetite for it, and the framework has none to supply.
ground < <(rec H-010 "A grade the map omits" \
               "$HYP
grade: moderate
action: release" 'Studios export weekly.')
silent "FR-GND-170 unmapped grade permits" 0 "which that grade does not permit here"

ground < <(rec H-010 "A grade the format does not define" \
               "$HYP
grade: pretty-good" 'Studios export weekly.')
rule "FR-GND-170 unknown grade" 1 "carries grade 'pretty-good'"
printf '{\n  "rules": {}\n}\n' > "$LAB/grounds/grounds-config.json"

# --- verifies: FR-GND-180 — a refusal carries its reason and its date, in
# --- one value because the halves are useless apart.
ground < <(rec H-010 "Turned down, silently" \
               "${HYP/status: assumed/status: declined}" 'Studios export weekly.')
rule "FR-GND-180 declined bare" 1 "carries no \`declined\` value"

ground < <(rec H-010 "Turned down, with half of it" \
               "${HYP/status: assumed/status: declined}
declined: because we said so" 'Studios export weekly.')
rule "FR-GND-180 declined without a date" 1 "is not the grammar the format defines"

ground < <(rec H-010 "Turned down, on the record" \
               "${HYP/status: assumed/status: declined}
declined: 2026-12-02 — the core is for studios, not for their clients' finance teams" \
               'Studios export weekly.')
rule "FR-GND-180 declined properly" 0 "Errors: 0"

# --- verifies: FR-GND-460 — the refusal outliving the status. The sequence
# --- is ordinary: refused, then a later measurement changes the picture,
# --- the status moves, and the line stays behind saying the opposite.
ground < <(rec H-010 "Refused once, held later" \
               "${HYP/status: assumed/status: supported}
declined: 2026-12-02 — the core is for studios, not their clients" \
               'Studios export weekly.')
rule "FR-GND-460 refusal left behind" 0 "still carries a \`declined\` value"

ground < <(rec H-010 "Refused, and saying so" \
               "${HYP/status: assumed/status: declined}
declined: 2026-12-02 — the core is for studios, not their clients" \
               'Studios export weekly.')
silent "FR-GND-460 a declined record may say so" 0 "still carries a"

# --- verifies: FR-GND-470 — an action with no grade at all. Quieter than
# --- acting beyond your grade, because nothing is there to compare it to.
printf '{"rules": {}, "grades": {"low": ["experiment"]}}\n' \
    > "$LAB/grounds/grounds-config.json"
ground < <(rec H-010 "Acting on something unstated" \
               "$HYP
action: release" 'Studios export weekly.')
rule "FR-GND-470 action with no grade" 0 "and no grade, so there is nothing to say"

# Without a map the project has expressed no appetite, and there is nothing
# for the omission to be measured against.
printf '{\n  "rules": {}\n}\n' > "$LAB/grounds/grounds-config.json"
silent "FR-GND-470 no map, no finding" 0 "and no grade, so there is nothing to say"

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

# --- verifies: FR-GND-100, FR-GND-220 — a bet naming no hypothesis at all.
# --- Both lists are optional, so the record is legal; read as a claim it
# --- would take the requirement off the one list this layer exists to
# --- produce and retire the declaration saying so, and every check on the
# --- shape would still pass. Cheapest possible invented link.
ground < <(rec B-010 "Names nothing" 'status: active
requirement: FR-CORE-010' 'FR-CORE-010 rests on, well, nothing.'
           rec U-010 "Says it rests on nothing" \
               'status: active
requirement: FR-CORE-010' 'Nobody could name a ground for this.')
silent "FR-GND-100 an empty bet retires no declaration" 0 "declares FR-CORE-010 unclaimed"
( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
grep -qE "^\| FR-CORE-010 \|" "$LAB/grounds/90-dashboard.md" \
    || { echo "FAIL FR-GND-220 — a bet staking nothing took the requirement"
         echo "off the list of what rests on no hypothesis"
         cat "$LAB/grounds/90-dashboard.md"; exit 1; }
passes=$((passes + 1))
rm -f "$LAB/grounds/90-dashboard.md"

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

# --- verifies: FR-GND-060 — and `off` is not the only way to lower a rule.
# --- Lowered to a report, the specific rule still speaks, so this one used
# --- to step aside for it — and the expiry FR-GND-060 owes as a warning
# --- came out as a report, which `--strict` does not fail on. A second
# --- rule's severity changed by a setting that never named it.
printf '{"rules": {"never-measured": "report"}}\n' > "$LAB/grounds/grounds-config.json"
rule "FR-GND-060 a lowered neighbour does not silence it" 1 \
     "ran out of term on 2020-01-01" --strict
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

# --- verifies: FR-GND-130 — and the denominator is what the sentence names.
# --- A third requirement carrying a bet that resolves to nothing belongs in
# --- "of N carrying a bet" and in no row of the table. Counted off the rows
# --- instead, the share was computed over a set the sentence does not name
# --- and every fixture above stayed green, because in all of them the two
# --- sets are the same size.
ground < <(rec H-010 "Held" "${HYP/status: assumed/status: supported}" 'Studios export.'
           rec H-020 "Did not" "${HYP/status: assumed/status: refuted}" 'Studios import.'
           rec B-010 "On the one that held" 'status: active
requirement: FR-CORE-010
all_of: [H-010]' 'FR-CORE-010 rests on H-010.'
           rec B-020 "On the one that did not" 'status: active
requirement: FR-CORE-020
all_of: [H-020]' 'FR-CORE-020 rests on H-020.'
           rec B-030 "On nothing at all" 'status: active
requirement: FR-CORE-030' 'FR-CORE-030 carries a bet that stakes it on nothing.')
cat > "$LAB/specs/10-fr-core.md" <<'MD'
# Functional requirements — core

### FR-CORE-010 — The system acts

```yaml
status: implemented
verification: T
code: []
tests: []
```

The system **shall** act.

### FR-CORE-020 — And again

```yaml
status: implemented
verification: T
code: []
tests: []
```

The system **shall** act again.

### FR-CORE-030 — And a third time

```yaml
status: implemented
verification: T
code: []
tests: []
```

The system **shall** act a third time.
MD
( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
D="$LAB/grounds/90-dashboard.md"
grep -qF "Of 3 requirements carrying a bet, 1 rest on" "$D" \
    || { echo "FAIL FR-GND-130 — the denominator is the rows, not the bets"
         cat "$D"; exit 1; }
grep -qF "\`assumed\` — 33%." "$D" \
    || { echo "FAIL FR-GND-130 — the share is computed over the wrong set"
         cat "$D"; exit 1; }
grep -qF "stakes them on no hypothesis at all" "$D" \
    || { echo "FAIL FR-GND-130 — a table shorter than its denominator says"
         echo "nothing about why"; cat "$D"; exit 1; }
passes=$((passes + 3))
rm -f "$D"
cp /tmp/srs-grounds-core.md "$LAB/specs/10-fr-core.md"

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
# Separately for each class, which is the half a census of whatever happens
# to be present passes by accident: two of the three are carried by nobody.
grep -qF "| I | 0 | — | — |" "$D" \
    || { echo "FAIL FR-GND-240 — a class nothing confirms has no row"
         cat "$D"; exit 1; }
grep -qF "| II | 0 | — | — |" "$D" \
    || { echo "FAIL FR-GND-240 — a class nothing confirms has no row"
         cat "$D"; exit 1; }
passes=$((passes + 3))

# Nothing is staked here, so every requirement that has not been cancelled
# rests on nothing — which is the honest reading of a register with no bets
# in it, not an empty list. FR-CORE-020 is withdrawn and is outside both
# numbers: it rests on no hypothesis and never will, nothing of the system
# rests on it, and left in it would sit on this list forever.
grep -qF "1 of 1 requirements" "$D" \
    || { echo "FAIL FR-GND-220 — the unclaimed count is wrong, or a cancelled"
         echo "requirement is being counted"; cat "$D"; exit 1; }
absent "| FR-CORE-020 |" "$D"
passes=$((passes + 2))
rm -f "$D"

# --- verifies: FR-GND-220 — and the weight is arithmetic, not a shape. The
# --- fixture above has neither links nor code on either requirement, so
# --- every column read `0` and a regular expression over digits accepted
# --- them; the sum could have been deleted and nothing here would have
# --- moved. A live requirement links to the one under test and it names two
# --- files, so the row is one exact answer. The link comes from a live
# --- requirement on purpose: `incoming` is computed over every entry the
# --- model holds, and the narrowing to what has not been cancelled belongs
# --- to this dashboard, which is asserted just above.
cat > "$LAB/specs/10-fr-core.md" <<'MD'
# Functional requirements — core

### FR-CORE-010 — Carries weight

```yaml
status: implemented
verification: T
code: [src/one.py, src/two.py]
tests: []
```

The system **shall** act.

### FR-CORE-020 — Cancelled with nothing to replace it

```yaml
status: withdrawn
verification: T
depends_on: [FR-CORE-010]
code: []
tests: []
```

The system **shall** have done something nobody wants now.

**Rationale.** Withdrawn, and its link must not become somebody's weight.

### FR-CORE-030 — Stands on the first

```yaml
status: implemented
verification: T
depends_on: [FR-CORE-010]
code: []
tests: []
```

The system **shall** depend on the first.
MD
ground < <(rec H-010 "Unstaked" "$HYP" 'Studios export weekly.')
( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
grep -qF "| FR-CORE-010 | 1 | 2 | 3 |" "$D" \
    || { echo "FAIL FR-GND-220 — the weight is not incoming plus code files,"
         echo "or a withdrawn dependant was counted into it"; cat "$D"; exit 1; }
passes=$((passes + 1))
rm -f "$D"
cp /tmp/srs-grounds-core.md "$LAB/specs/10-fr-core.md"

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

# --- verifies: FR-GND-140 — a verdict follows from the threshold, and what
# --- follows is not a bare comparison. A value below its threshold by less
# --- than a sample of that size can miss by has refuted nothing: 0.24 on
# --- 200 is forty-eight people where fifty were wanted, and burying a
# --- hypothesis over two of them is a coin toss wearing an arithmetic's
# --- clothes. This is the rule's whole reason for existing.
HYP_I="${HYP/class: III/class: I}"

ground < <(rec H-010 "Two people are not a refutation" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-02-14 | 0.24 | 200 | refuted | telemetry |')
rule "FR-GND-140 refuted on noise" 1 "the verdict it compels is 'supported'"

ground < <(rec H-010 "Past the threshold and past the error" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-08-01 | 0.19 | 210 | supported | telemetry |')
rule "FR-GND-140 survived what killed it" 1 "the verdict it compels is 'refuted'"

# The two halves that need no error calculation at all: the threshold's own
# `at n >=` is part of the sentence its author wrote, and a value on the
# safe side contradicts a refutation whatever the error.
ground < <(rec H-010 "Refuted on a sample the threshold refuses" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 0.10 | 30 | refuted | telemetry |')
rule "FR-GND-140 below the gate" 1 "is smaller than the threshold's own at n >= 200"

ground < <(rec H-010 "Refuted while thriving" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 0.60 | 400 | refuted | telemetry |')
rule "FR-GND-140 safe side" 1 "is on the safe side of < 0.25"

ground < <(rec H-010 "A word no measurement reaches" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 0.60 | 400 | promising | telemetry |')
rule "FR-GND-140 verdict vocabulary" 1 "which is not one a measurement can reach"

ground < <(rec H-010 "Nothing to compare" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | most | 400 | supported | telemetry |')
rule "FR-GND-140 unmeasurable value" 1 "which no threshold can be compared against"

# And the fixture this rule would be worthless without: rows that are right
# say nothing. Both of them cross a boundary the naive comparison would get
# backwards, so a checker that reported everything would pass every fixture
# above and fail only here.
ground < <(rec H-010 "Both readings are honest" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-02-14 | 0.24 | 200 | supported | telemetry |
| 2026-08-01 | 0.19 | 210 | refuted | telemetry |')
silent "FR-GND-140 honest rows are quiet" 0 "the verdict it compels"

# A register is written by hand, so a typo is ordinary input. Every one of
# these reached the arithmetic before the guard existed and either crashed
# it or was judged in silence, which for a checker is the same failure.
HYP_COUNT="${HYP_I/refuted_if: proportion < 0.25 at n >= 200/refuted_if: count > 10 at n >= 1}"
# Nought out of twenty is where a proportion's error is least like a
# straight band around the value: the truth still reaches 0.12, twice what
# a naive interval centred on the measurement would allow. Thresholds on a
# proportion are drawn near the ends, so this is not an exotic case.
HYP_EDGE="${HYP_I/refuted_if: proportion < 0.25 at n >= 200/refuted_if: proportion < 0.1 at n >= 20}"
ground < <(rec H-010 "Nobody at all, out of twenty" "$HYP_EDGE" \
               'A tenth of them export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 0 | 20 | refuted | telemetry |')
rule "FR-GND-140 nought of twenty" 1 "the verdict it compels is 'supported'"

ground < <(rec H-010 "A proportion above one" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 1.5 | 400 | refuted | telemetry |')
rule "FR-GND-140 impossible proportion" 1 "is outside nought to one"

ground < <(rec H-010 "Nothing observed at all" \
               "${HYP_I/at n >= 200/at n >= 0}" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 0.1 | 0 | refuted | telemetry |')
rule "FR-GND-140 an empty sample" 1 "measures nothing"

ground < <(rec H-010 "Two and a half crashes" "$HYP_COUNT" \
               'Crashes stay under ten a week.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 12.5 | 1 | refuted | ops |')
rule "FR-GND-140 a fractional count" 1 "is not a whole number of things"

ground < <(rec H-010 "Fewer crashes than none" "$HYP_COUNT" \
               'Crashes stay under ten a week.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | -3 | 1 | refuted | ops |')
rule "FR-GND-140 a negative count" 1 "is fewer than none of them"

ground < <(rec H-010 "A value that is not a number" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | nan | 400 | refuted | telemetry |')
rule "FR-GND-140 nan" 1 "is not a number anything can be compared against"

ground < <(rec H-010 "A value with no end" "$HYP_COUNT" \
               'Crashes stay under ten a week.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | inf | 1 | refuted | ops |')
rule "FR-GND-140 infinity" 1 "is not a number anything can be compared against"

# The seam between the exact criterion and its approximation is crossed by
# ordinary data, and crossing it must not change the answer and must not
# cost a term per event counted. The exact sum answers this row in about
# thirty seconds, so the bound below is loose enough never to flake and
# tight enough to notice that.
ground < <(rec H-010 "Two million of them" "$HYP_COUNT" \
               'Crashes stay under ten a week.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 2000000 | 1 | refuted | ops |')
started=$(date +%s)
silent "FR-GND-140 a large count is judged" 0 "the verdict it compels"

# Two million events is far enough from any threshold that a badly wrong
# spread would not show. These two straddle the seam a hundred apart from
# it, close enough to their threshold that the bound decides the verdict:
# the exact side and the approximate side must reach the same one.
HYP_SEAM="${HYP_I/refuted_if: proportion < 0.25 at n >= 200/refuted_if: count > 900 at n >= 1}"
ground < <(rec H-010 "Just short of the seam" "$HYP_SEAM" \
               'Crashes stay under nine hundred a week.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 999 | 1 | supported | ops |')
rule "FR-GND-140 below the seam" 1 "the verdict it compels is 'refuted'"

ground < <(rec H-010 "Just past the seam" "$HYP_SEAM" \
               'Crashes stay under nine hundred a week.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 1001 | 1 | supported | ops |')
rule "FR-GND-140 above the seam" 1 "the verdict it compels is 'refuted'"

# And the approximate side must carry an error at all, not merely agree
# with the exact side about values far from their threshold. 1050 against
# `count > 1000` crosses it raw and does not cross it once the fifty-three
# a count of that size can miss by is allowed for.
HYP_NOISE="${HYP_I/refuted_if: proportion < 0.25 at n >= 200/refuted_if: count > 1000 at n >= 1}"
ground < <(rec H-010 "Fifty over, and fifty is the noise" "$HYP_NOISE" \
               'Crashes stay under a thousand a week.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 1050 | 1 | refuted | ops |')
rule "FR-GND-140 noise past the seam" 1 "the verdict it compels is 'supported'"

ground < <(rec H-010 "Two hundred over is not noise" "$HYP_NOISE" \
               'Crashes stay under a thousand a week.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-09-01 | 1200 | 1 | refuted | ops |')
silent "FR-GND-140 past the seam and past the noise" 0 "the verdict it compels"
elapsed=$(( $(date +%s) - started ))
[ "$elapsed" -gt 10 ] && { echo "FAIL FR-GND-140 — judging one count took"
                           echo "${elapsed}s, so the exact sum is being walked"
                           exit 1; }
passes=$((passes + 1))

# --- verifies: FR-GND-150 — the criterion comes from the kind of quantity,
# --- and a mean has none: how far it can miss needs the spread behind it,
# --- which the row does not carry. Class I over one is a claim that
# --- re-confirmation happens by itself when nothing can perform it.
HYP_MEAN="${HYP_I/refuted_if: proportion < 0.25 at n >= 200/refuted_if: mean < 4.0 at n >= 50}"

ground < <(rec H-010 "Class I over a mean" "$HYP_MEAN" \
               'Sessions average four edits.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-03-01 | 3.9 | 60 | supported | telemetry |')
rule "FR-GND-150 untestable class I" 0 "class-untestable"

# The same threshold at a class that never claimed to re-confirm itself.
ground < <(rec H-010 "Class II over a mean" "${HYP_MEAN/class: I/class: II}" \
               'Sessions average four edits.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-03-01 | 3.9 | 60 | supported | telemetry |')
silent "FR-GND-150 class II may hold a mean" 0 "class-untestable"

# A mean compels no verdict either way, so the row above went unjudged —
# but the half that needs no criterion still speaks.
ground < <(rec H-010 "A mean refuted while thriving" "${HYP_MEAN/class: I/class: II}" \
               'Sessions average four edits.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-03-01 | 9.0 | 60 | refuted | telemetry |')
rule "FR-GND-150 the criterion-free half" 1 "is on the safe side of < 4"

# --- verifies: FR-GND-490 — how much error is allowed is the project's, and
# --- the proof is that the same row changes verdict when the answer does.
ground < <(rec H-010 "Refuted at ninety-five, alive at ninety-nine" "$HYP_I" \
               'Studios export weekly.

| date | value | n | verdict | by |
|---|---|---|---|---|
| 2026-08-01 | 0.19 | 210 | supported | telemetry |')
rule "FR-GND-490 default confidence" 1 "the verdict it compels is 'refuted'"
printf '{"rules": {}, "confidence": 0.99}\n' > "$LAB/grounds/grounds-config.json"
silent "FR-GND-490 a surer project keeps it" 0 "the verdict it compels"
printf '{"rules": {}, "confidence": 0.973}\n' > "$LAB/grounds/grounds-config.json"
rule "FR-GND-490 unknown confidence" 2 "confidence must be one of"
printf '{\n  "rules": {}\n}\n' > "$LAB/grounds/grounds-config.json"

# --- verifies: FR-GND-230 — the rate and where it clusters, not the total.
# --- One requirement standing on nothing is noise and is meant to be; the
# --- reading is five in a period with four in one area. Periods are
# --- calendar ones of the length `period` names, taken from the dates in
# --- the records, so this file stays comparable — a window anchored to
# --- today would move every night.
cat > "$LAB/specs/10-fr-core.md" <<'MD'
# Functional requirements — core

### FR-CORE-010 — Dated, and claimed

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-02-10
```

The system **shall** act.

### FR-CORE-020 — Dated, and standing on nothing

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-08-14
```

The system **shall** also act.

### FR-CORE-030 — Undated, and standing on nothing

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

The system **shall** act a third time.

### FR-CORE-040 — Dated, standing on nothing, and cancelled

```yaml
status: withdrawn
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-08-20
```

The system **shall** have arrived in the same quarter and then been dropped.

**Rationale.** Counted in, it would make the quarter below read two.
MD
# FR-CORE-040 arrived in the same quarter as FR-CORE-020 and was withdrawn.
# The row below reads one because a cancelled requirement is outside the
# count: it rests on no hypothesis and never will, and a withdrawal is the
# case where somebody did say out loud what the rate is looking for.
# B-020 stakes FR-CORE-020 on nothing: the arrivals half of FR-GND-100's
# neighbour. Read as a claim it would take FR-CORE-020 out of the quarter
# it arrived in, and the row below would go with it.
ground < <(rec H-010 "Ground" "$HYP" 'Studios export weekly.'
           rec B-010 "Claims the first" 'status: active
requirement: FR-CORE-010
all_of: [H-010]' 'FR-CORE-010 rests on H-010.'
           rec B-020 "Claims the second and stakes it on nothing" 'status: active
requirement: FR-CORE-020' 'FR-CORE-020 carries a bet naming no hypothesis.')
( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
D="$LAB/grounds/90-dashboard.md"
grep -qE "^\| 2026-Q3 \| 1 \| CORE 1 \|" "$D" \
    || { echo "FAIL FR-GND-230 — the quarter that received one unclaimed"
         echo "requirement is not stated, or a bet staking nothing took it"
         echo "out of the count"; cat "$D"; exit 1; }
absent "| 2026-Q1 |" "$D"
grep -qF "carry no \`created\` date and fall in no period" "$D" \
    || { echo "FAIL FR-GND-230 — an undated requirement is silently dropped"
         echo "rather than counted apart"; cat "$D"; exit 1; }
passes=$((passes + 3))

# The unit is the project's, and the dashboard says which one it used so
# that nobody has to open the configuration to know what a row counts.
grep -qF "Counted by quarter, which is what \`period\` says" "$D" \
    || { echo "FAIL FR-GND-230 — the dashboard does not name its own unit"
         cat "$D"; exit 1; }
printf '{"rules": {}, "period": "month"}\n' > "$LAB/grounds/grounds-config.json"
( cd "$LAB" && python3 tools/srs_grounds.py ) > /tmp/srs-grounds.log 2>&1
grep -qE "^\| 2026-08 \| 1 \| CORE 1 \|" "$D" \
    || { echo "FAIL FR-GND-230 — the configured period is not used"
         cat "$D"; exit 1; }
absent "| 2026-Q3 |" "$D"
printf '{"rules": {}, "period": "fortnight"}\n' > "$LAB/grounds/grounds-config.json"
rule "FR-GND-230 unknown period" 2 "period must be one of"
printf '{\n  "rules": {}\n}\n' > "$LAB/grounds/grounds-config.json"
passes=$((passes + 3))
rm -f "$D"
cp /tmp/srs-grounds-core.md "$LAB/specs/10-fr-core.md" 2>/dev/null || true

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

# --- verifies: FR-GND-190, FR-GND-200 — two of the rules that read the
# --- register's history. A lab of their own, because they need one; the
# --- ideology pair below shares it.
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

# --- verifies: FR-GND-510, FR-GND-520 — growth in what may move an
# --- ideology, and whether the growth said what it opened.
ideo_at() {   # ideo_at <admissible arguments> [amendment rows…]
    { printf '### I-010 — For studios\n\n```yaml\nstatus: active\nadmissible_arguments: [%s]\n```\n\nWe are for studios of five to fifty.\n\n' "$1"
      shift
      if [ "$#" -gt 0 ]; then
          printf '| date | what changed | why | territory it opens |\n|---|---|---|---|\n'
          for row in "$@"; do printf '%s\n' "$row"; done
      fi
    } > "$HLAB/grounds/00-ideology.md"
}

# Adopted, then widened in the same commit as the amendment that says what
# the wider set now admits. The price is charged; the disclosure is not.
ideo_at "a cohort measurement"; commit_lab "ideology adopted"
ideo_at "a cohort measurement, a frame refusal" \
    "| 2027-01-12 | a frame refusal admitted | three refusals in a quarter | teams with a delivery manager |"
commit_lab "widened, and said what it opens"
history_run
grep -qF "widened what may move it, admitting a frame refusal" /tmp/srs-history.log \
    || { echo "FAIL FR-GND-510 — a widened set of admissible arguments was"
         echo "not reported"; cat /tmp/srs-history.log; exit 1; }
grep -qF "widened without an amendment naming the territory" /tmp/srs-history.log \
    && { echo "FAIL FR-GND-520 — a widening that named its territory was"
         echo "reported as undisclosed"; cat /tmp/srs-history.log; exit 1; }
passes=$((passes + 2))

# Widened again with nothing new said. This is the assertion the rule would
# pass without: reporting every widening as undisclosed would satisfy the
# grep above's absence only by accident.
ideo_at "a cohort measurement, a frame refusal, revenue" \
    "| 2027-01-12 | a frame refusal admitted | three refusals in a quarter | teams with a delivery manager |"
commit_lab "widened in silence"
history_run
grep -qF "widened without an amendment naming the territory" /tmp/srs-history.log \
    || { echo "FAIL FR-GND-520 — a widening with no amendment was not"
         echo "reported"; cat /tmp/srs-history.log; exit 1; }
passes=$((passes + 1))

# Narrowing is the other move and this pair says nothing about it — by
# design, and the gap is named in FR-GND-510's rationale.
ideo_at "a cohort measurement"
commit_lab "narrowed"
history_run
grep -cF "widened what may move it" /tmp/srs-history.log | grep -qx 2 \
    || { echo "FAIL FR-GND-510 — narrowing changed how many widenings are"
         echo "reported"; cat /tmp/srs-history.log; exit 1; }
passes=$((passes + 1))

# --- verifies: IF-GND-030 — a published rule name keeps its meaning. The
# --- names go into somebody else's `grounds/grounds-config.json` to say what
# --- a rule costs, so a rename breaks their file and the checker refuses to
# --- start, listing what it knows. A promise about the future cannot be
# --- tested; what can is the past, listed here so a rename has to walk past
# --- it. Written out rather than read from RULES, which would compare the
# --- tuple with itself and never fail.
#
# Twelve of the fifteen were reachable by nothing before this: `rule` greps
# the output for a fragment, and every fixture but two greps prose, which a
# rename leaves untouched. `hypothesis-expired` and `never-measured` are
# spelled as configuration keys and `class-untestable` is asserted in the
# output, so those three would have reddened; the rest could be renamed with
# this suite green.
( cd "$LAB" && python3 -c "
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import srs_grounds

published = (
    'bet-cancelled', 'hypothesis-expired', 'bet-duplicated',
    'declaration-superfluous', 'threshold-moved', 'evidence-dropped',
    'relied-on-untested', 'never-measured', 'verdict-unattributed',
    'action-beyond-grade', 'declined-leftover', 'action-without-grade',
    'class-untestable', 'arguments-widened', 'widening-undisclosed',
)
gone = [name for name in published if name not in srs_grounds.RULES]
if gone:
    sys.stderr.write('rule names withdrawn or renamed: %s\n' % ', '.join(gone))
    sys.exit(1)
" ) > /tmp/srs-grounds.log 2>&1 \
    || { echo "FAIL IF-GND-030 — a published rule name is gone"
         cat /tmp/srs-grounds.log; exit 1; }
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

# --- verifies: FR-GND-540 — a record is cited like a requirement: the form
# --- the viewer prints, over the register's own records of any kind, in the
# --- order asked; an unknown identifier is named and fails the run without
# --- dropping the ones that resolve; nothing is written.
ground < <(rec H-010 "Studios keep exporting" "$HYP" 'Studios export weekly.'
           rec U-010 "Nobody measured this" 'status: active
requirement: FR-CORE-010
reason: no hypothesis names it yet' 'It stands in for a bet.')
rm -f "$LAB/grounds/90-dashboard.md"
rc=0
( cd "$LAB" && python3 tools/srs_grounds.py --cite U-010 H-010 H-990 ) \
    > /tmp/srs-grounds-cite.out 2> /tmp/srs-grounds-cite.err || rc=$?
cat > /tmp/srs-grounds-cite.want <<'WANT'
U-010 — Nobody measured this (grounds/10-h-test.md, active)
H-010 — Studios keep exporting (grounds/10-h-test.md, assumed)
WANT
diff -u /tmp/srs-grounds-cite.want /tmp/srs-grounds-cite.out \
    || { echo "FAIL FR-GND-540 — --cite printed something other than the form, or lost the order"; exit 1; }
[ "$rc" = 1 ] || { echo "FAIL FR-GND-540 — an unknown record left --cite with exit $rc"; exit 1; }
grep -q "no record H-990" /tmp/srs-grounds-cite.err \
    || { echo "FAIL FR-GND-540 — --cite did not say which record it could not resolve"; exit 1; }
[ -f "$LAB/grounds/90-dashboard.md" ] \
    && { echo "FAIL FR-GND-540 — a citation wrote the dashboard"; exit 1; }
rule "FR-GND-540 --cite with nothing to cite is a setup fault" 2 "needs at least one" --cite
passes=$((passes + 4))

echo "grounds-rules: $passes fixtures pass"
