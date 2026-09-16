#!/usr/bin/env bash
# One fixture per rule of the architecture checker, each breaking exactly one
# thing, so a failure names the rule that stopped working.
#
# verifies: FR-ARCH-010, FR-ARCH-020, FR-ARCH-030, FR-ARCH-040, FR-ARCH-050
# verifies: FR-ARCH-060, FR-ARCH-070, FR-ARCH-080, FR-ARCH-090, FR-ARCH-100
# verifies: IF-ARCH-020, IF-ARCH-030, CON-ARCH-010, FR-ARCH-200, FR-ARCH-210
# verifies: FR-ARCH-220
#
# Several of these assert that the checker stays quiet, and they are why this
# file exists rather than a smoke test: delete the rule underneath one and the
# checker goes quiet for the wrong reason, so the fixture passes and proves
# nothing. Which ones they are is not written out here — they are the `silent`
# calls below, and that list cannot fall behind the file the way a copy of it
# in this comment did: this comment named two of them and 50-verification.md
# named three others, and neither reader could tell which set was meant.
set -eo pipefail

# implements: FR-CI-090
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."
. tools/test_lib.sh

LAB=/tmp/srs-arch
rm -rf "$LAB"
mkdir -p "$LAB/tools" "$LAB/specs" "$LAB/arch" "$LAB/src"
cp tools/srs_arch.py tools/srs_parse.py tools/srs_check.py tools/srs_view.py "$LAB/tools/"
printf 'x\n' > "$LAB/src/a.py"
printf 'x\n' > "$LAB/src/b.py"

cat > "$LAB/specs/srs-config.json" <<'JSON'
{
  "areas": ["CORE"],
  "code_roots": ["src"],
  "test_roots": ["t"],
  "code_extensions": [".py"]
}
JSON

# Two requirements, one realized in each source file, so that ownership has
# something to be right or wrong about.
cat > "$LAB/specs/10-fr-core.md" <<'MD'
# Functional requirements — core

### FR-CORE-010 — The first

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [src/a.py]
tests: []
created: 2026-09-02
```

The system **shall** act.

### FR-CORE-020 — The second

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [src/b.py]
tests: []
created: 2026-09-02
```

The system **shall** also act.
MD

printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"

# elements <<'MD' — the layer under test, replaced by every fixture.
elements() { cat > "$LAB/arch/00-elements.md"; }

passes=0

# rule <name> <expected exit> <message fragment> [flags…]
rule() {
    local name=$1 want=$2 msg=$3; shift 3
    local rc=0
    ( cd "$LAB" && python3 tools/srs_arch.py --no-write "$@" ) > /tmp/srs-arch.log 2>&1 || rc=$?
    if [ "$rc" != "$want" ]; then
        echo "FAIL $name — exit $rc, expected $want"; cat /tmp/srs-arch.log; exit 1
    fi
    if ! grep -qF "$msg" /tmp/srs-arch.log; then
        echo "FAIL $name — no message matching: $msg"; cat /tmp/srs-arch.log; exit 1
    fi
    passes=$((passes + 1))
}

# silent <name> <expected exit> <fragment that must NOT appear>
silent() {
    local name=$1 want=$2 msg=$3; shift 3
    local rc=0
    ( cd "$LAB" && python3 tools/srs_arch.py --no-write "$@" ) > /tmp/srs-arch.log 2>&1 || rc=$?
    if [ "$rc" != "$want" ]; then
        echo "FAIL $name — exit $rc, expected $want"; cat /tmp/srs-arch.log; exit 1
    fi
    if grep -qF "$msg" /tmp/srs-arch.log; then
        echo "FAIL $name — said something it should not: $msg"
        cat /tmp/srs-arch.log; exit 1
    fi
    passes=$((passes + 1))
}

# --- A layer that says everything it should: nothing is reported at all.
elements <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries the whole of it.
MD
silent "a complete layer is silent" 0 "warning:"
silent "and a directory carrier owns the files under it" 0 "src/a.py"

# --- verifies: FR-ARCH-020 — identifiers are well-formed and unique.
elements <<'MD'
# Elements

### E-01 — Two digits short

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries it.
MD
rule "FR-ARCH-020 malformed" 1 "identifier does not match E-<NNN>"

elements <<'MD'
# Elements

### E-010 — First

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries it.

### E-010 — Same number again

```yaml
status: built
carries: [src]
requirements: []
depends_on: []
```

Carries it too.
MD
rule "FR-ARCH-020 duplicate" 1 "is already used at"

# --- verifies: FR-ARCH-030 — a missing required key is named as missing.
elements <<'MD'
# Elements

### E-010 — No carriers key at all

```yaml
status: built
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries nothing it admits to.
MD
rule "FR-ARCH-030 missing key" 1 "required key 'carries' is missing"

# --- verifies: FR-ARCH-040 — an element names a requirement that exists.
elements <<'MD'
# Elements

### E-010 — Points at nothing

```yaml
status: built
carries: [src]
requirements: [FR-CORE-990]
depends_on: []
```

Carries it.
MD
rule "FR-ARCH-040 unknown requirement" 1 "which the specification does not carry"

# --- verifies: FR-ARCH-050 — a cancelled requirement is reported, not fatal.
cat >> "$LAB/specs/10-fr-core.md" <<'MD'

### FR-CORE-030 — The cancelled one

```yaml
status: withdrawn
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-09-02
```

The system **shall** have acted.
MD
elements <<'MD'
# Elements

### E-010 — Carries a cancelled requirement

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-030]
depends_on: []
```

Carries it.
MD
rule "FR-ARCH-050 cancelled requirement" 0 "which is withdrawn"

# --- verifies: FR-ARCH-060 — a carrier no element claims.
elements <<'MD'
# Elements

### E-010 — Half of it

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries half.
MD
rule "FR-ARCH-060 carrier unclaimed" 0 "src/b.py — named by FR-CORE-020 and carried by no element"

# --- The `code` field and not `tests`: whether a suite belongs to the part it
# --- exercises or to the gate is a question about how a system is cut, and
# --- this rule does not answer it.
mkdir -p "$LAB/t"
printf 'x = 1\n' > "$LAB/t/a_test.py"
python3 - <<'PY2'
path = '/tmp/srs-arch/specs/10-fr-core.md'
text = open(path, encoding='utf-8').read()
open(path, 'w', encoding='utf-8').write(
    text.replace('code: [src/a.py]\ntests: []', 'code: [src/a.py]\ntests: [t/a_test.py]', 1))
PY2
elements <<'MD'
# Elements

### E-010 — Only the code

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries the code and not the suites.
MD
silent "FR-ARCH-060 a test file no element carries is not reported" 0 "t/a_test.py"

# --- verifies: FR-ARCH-070 — a realized requirement no element carries.
elements <<'MD'
# Elements

### E-010 — Names one requirement

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010]
depends_on: []
```

Carries it.
MD
rule "FR-ARCH-070 requirement uncarried" 0 "FR-CORE-020 is implemented and no element carries it"

# --- verifies: FR-ARCH-080 — an element carrying no requirement.
elements <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries it.

### E-020 — Answers to nothing

```yaml
status: built
carries: []
requirements: []
depends_on: []
```

Exists.
MD
rule "FR-ARCH-080 element carries nothing" 0 "carries no requirement, so nothing says what it is for"

# --- And a dissolved element is exempt: it has nothing left to answer for.
elements <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries it.

### E-020 — Dissolved

```yaml
status: withdrawn
carries: []
requirements: []
depends_on: []
```

Gone.
MD
silent "FR-ARCH-080 a dissolved element is exempt" 0 "carries no requirement"

# --- verifies: FR-ARCH-100 — strict mode fails on a warning alone.
# Its own layer rather than whatever the fixture above left behind: a check
# that depends on the previous one passes for reasons nobody chose.
elements <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries it.

### E-020 — Answers to nothing

```yaml
status: built
carries: []
requirements: []
depends_on: []
```

Exists.
MD
silent "FR-ARCH-100 the same layer is not fatal without --strict" 0 "treated as errors"
rule "FR-ARCH-100 strict" 1 "treated as errors" --strict

# --- The three fixtures below deliberately reuse the layer the strict one
# --- just wrote: they need a layer that warns, and writing it again would
# --- only hide which layer they are asserting against.
# --- verifies: FR-ARCH-090, IF-ARCH-030 — a lowered rule is still computed
# --- and no longer fatal, and the name it is lowered by is the published one.
printf '{"rules": {"element-empty": "report"}}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-090 lowered rule still speaks" 0 "note: "
silent "FR-ARCH-090 and stops failing strictly" 0 "treated as errors" --strict
printf '{"rules": {"no-such-rule": "warn"}}\n' > "$LAB/arch/arch-config.json"
rule "IF-ARCH-030 an unknown rule name is refused" 2 "unknown rule"
printf '{"rules": {"element-empty": "loud"}}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-090 an unknown severity is refused" 2 "expected warn/report/off"
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"

# --- verifies: IF-ARCH-020 — the third exit code is for what cannot be read.
rule "IF-ARCH-020 unknown flag" 2 "unknown flag(s): --nope" --nope
mv "$LAB/tools/srs_view.py" "$LAB/tools/srs_view.hidden"
rule "IF-ARCH-020 no viewer to read the model through" 2 "tools/srs_view.py is not here"
mv "$LAB/tools/srs_view.hidden" "$LAB/tools/srs_view.py"

# --- verifies: FR-ARCH-200 — a dependency the code has and the model does not.
# --- Its own source files, because the ownership fixtures above carry no imports.
printf 'import b\n' > "$LAB/src/a.py"
printf 'x = 1\n' > "$LAB/src/b.py"
elements <<'MD'
# Elements

### E-010 — The first

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: []
```

Imports the second.

### E-020 — The second

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: []
```

Imported.
MD
rule "FR-ARCH-200 undeclared dependency" 0 "and E-010 does not declare it"

# --- Declared, the same code is silent: the model and the imports agree.
elements <<'MD'
# Elements

### E-010 — The first

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: [E-020]
```

Imports the second, and says so.

### E-020 — The second

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: []
```

Imported.
MD
silent "FR-ARCH-200 a declared dependency is silent" 0 "does not declare it"

# --- An import that resolves to no carried file is not reported: the rule
# --- speaks only about what it can prove.
printf 'import json\nimport b\n' > "$LAB/src/a.py"
silent "FR-ARCH-200 an unresolvable import is left alone" 0 "imports json"
printf 'import b\n' > "$LAB/src/a.py"

# --- A module name two elements answer to is resolved beside the importer,
# --- not by whichever file was read last. Without this the rule reports an
# --- import against an element the file never touched.
# The importing element's own directory sorts after the other one on purpose: a
# resolver that picks any single file for an ambiguous name picks the wrong one
# here, and the silence below would come from luck rather than from the rule.
mkdir -p "$LAB/alpha" "$LAB/zeta"
printf 'import util\n' > "$LAB/zeta/main.py"
printf 'x = 1\n' > "$LAB/zeta/util.py"
printf 'y = 2\n' > "$LAB/alpha/util.py"
elements <<'MD'
# Elements

### E-010 — One

```yaml
status: built
carries: [zeta, src]
requirements: [FR-CORE-010]
depends_on: []
```

Has a util of its own.

### E-020 — Two

```yaml
status: built
carries: [alpha]
requirements: [FR-CORE-020]
depends_on: []
```

Has a util of its own too.
MD
silent "FR-ARCH-200 a name two elements answer to is left unresolved" 0 \
       "imports util"

# --- And a genuine cross-element import is still reported.
printf 'z = 3\n' > "$LAB/alpha/other.py"
printf 'import util\nimport other\n' > "$LAB/zeta/main.py"
rule "FR-ARCH-200 a real cross-element import still speaks" 0 \
     "imports other, carried by E-020, and E-010 does not declare it"
rm -rf "$LAB/alpha" "$LAB/zeta"

# --- verifies: FR-ARCH-220 — elements that depend on each other in a circle.
# --- No imports in the sources: the circle is declared, and the rule reads
# --- the declaration, not the code.
printf 'x = 1\n' > "$LAB/src/a.py"
printf 'x = 1\n' > "$LAB/src/b.py"
elements <<'MD'
# Elements

### E-010 — The first

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: [E-020]
```

Needs the second.

### E-020 — The second

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: [E-010]
```

Needs the first.
MD
rule "FR-ARCH-220 a circle is reported naming its elements" 0 \
     "elements depend on each other in a circle: E-010 → E-020 → E-010"
# --- Located like every other finding here, at the element it is named from.
rule "FR-ARCH-220 and located at that element" 0 \
     "arch/00-elements.md:3 — elements depend on each other"
rule "FR-ARCH-220 and fails a strict run" 1 "treated as errors" --strict
# --- Priced by the project like every other rule here (FR-ARCH-090), under
# --- the name IF-ARCH-030 publishes.
printf '{"rules": {"element-cycle": "off"}}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-220 silenced in the configuration" 0 "in a circle" --strict
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"

# --- A cancelled element is on no circle: it keeps its field for the record
# --- and has left the graph.
elements <<'MD'
# Elements

### E-010 — The first

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: [E-020]
```

Needs the second.

### E-020 — The second, gone

```yaml
status: withdrawn
carries: [src/b.py]
requirements: []
depends_on: [E-010]
```

Left, and its field stayed.
MD
silent "FR-ARCH-220 a circle through a cancelled element is none" 0 "in a circle"

# --- A dependency naming no element ends the path, not the run: nothing
# --- checks that `depends_on` resolves, and the walk must not be what does.
# --- The unresolved name sits on a would-be circle, so a walk that followed
# --- it into its bookkeeping would report one that no declared element closes.
elements <<'MD'
# Elements

### E-010 — The first

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: [E-999]
```

Points at nothing.

### E-020 — The second

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: [E-010]
```

Needs the first.
MD
silent "FR-ARCH-220 an unresolved dependency ends the path, not the run" 0 "circle"

# --- And the degenerate circle, said in words that fit one element.
elements <<'MD'
# Elements

### E-010 — The first

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: [E-010]
```

Needs itself.
MD
rule "FR-ARCH-220 an element depending on itself" 0 "E-010 depends on itself"

# --- The circle is named from where it closes, not from where the walk
# --- began: an element that merely leads into one is not on it.
elements <<'MD'
# Elements

### E-005 — The way in

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: [E-010]
```

Leads into the circle.

### E-010 — On the circle

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: [E-020]
```

On it.

### E-020 — Also on the circle

```yaml
status: built
carries: [t]
requirements: []
depends_on: [E-010]
```

On it too.
MD
rule "FR-ARCH-220 the circle is cut where it closes" 0 \
     "in a circle: E-010 → E-020 → E-010"
silent "FR-ARCH-220 and the way in is not on it" 0 "E-005 → E-010 → E-020"

# --- verifies: FR-ARCH-210 — the drivers are ranked, not chosen by taste.
cat >> "$LAB/specs/10-fr-core.md" <<'MD'

### FR-CORE-040 — Leans on the first

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CORE-010]
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-09-02
```

The system **shall** lean.
MD
( cd "$LAB" && python3 tools/srs_arch.py --drivers ) > /tmp/srs-arch-drivers.log 2>&1 \
    || { echo "FAIL FR-ARCH-210 — --drivers exited non-zero"
         cat /tmp/srs-arch-drivers.log; exit 1; }
head -3 /tmp/srs-arch-drivers.log | grep -qF "FR-CORE-010" \
    || { echo "FAIL FR-ARCH-210 — the most linked requirement does not lead"
         cat /tmp/srs-arch-drivers.log; exit 1; }
grep -qF "1 incoming" /tmp/srs-arch-drivers.log \
    || { echo "FAIL FR-ARCH-210 — the ranking does not say what it counted"
         cat /tmp/srs-arch-drivers.log; exit 1; }
passes=$((passes + 1))

# --- verifies: CON-ARCH-010 — a run writes inside the layer and nowhere else.
# ---
# --- In a tree the checker has never run in, and that is the whole point:
# --- weighed inside the lab above, a file left behind by one of the 26 runs
# --- it has already had sits in both snapshots and the assertion cannot
# --- fail. Every file is weighed, not two chosen directories: the checker
# --- shells out to the viewer, and bytecode landing in tools/ is exactly
# --- the kind of writing this forbids and the kind a narrower comparison
# --- never sees.
LAB2=/tmp/srs-arch-write
rm -rf "$LAB2"; mkdir -p "$LAB2/tools" "$LAB2/specs" "$LAB2/arch" "$LAB2/src"
cp tools/srs_arch.py tools/srs_parse.py tools/srs_check.py tools/srs_view.py \
   "$LAB2/tools/"
cp "$LAB/specs/srs-config.json" "$LAB/specs/10-fr-core.md" "$LAB2/specs/"
printf '{"rules": {}}\n' > "$LAB2/arch/arch-config.json"
printf 'x\n' > "$LAB2/src/a.py"
printf 'x\n' > "$LAB2/src/b.py"
cat > "$LAB2/arch/00-elements.md" <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries it.
MD

weigh() { ( cd "$LAB2" && find . -type f ! -name 90-map.md \
            -exec cksum {} \; | sort ); }
# Distinct from the names the fixture this replaced used for a pair of
# directories: a machine that ran the old one still has them, and a
# redirect onto a directory is a suite that fails for its own reasons.
BEFORE=/tmp/srs-arch-write.before
AFTER=/tmp/srs-arch-write.after
rm -rf "$BEFORE" "$AFTER"
weigh > "$BEFORE"
( cd "$LAB2" && python3 tools/srs_arch.py ) > /dev/null 2>&1
[ -f "$LAB2/arch/90-map.md" ] \
    || { echo "FAIL CON-ARCH-010 — the run wrote no map, so this assertion"
         echo "would hold for a checker that did nothing"; exit 1; }
weigh > "$AFTER"
cmp -s "$BEFORE" "$AFTER" \
    || { echo "FAIL CON-ARCH-010 — a run touched something outside the layer"
         diff "$BEFORE" "$AFTER" | head -10; exit 1; }
passes=$((passes + 2))

echo "arch-rules: $passes fixtures pass"
