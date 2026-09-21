#!/usr/bin/env bash
# One fixture per rule of the architecture checker, each breaking exactly one
# thing, so a failure names the rule that stopped working.
#
# verifies: FR-ARCH-010, FR-ARCH-020, FR-ARCH-030, FR-ARCH-040, FR-ARCH-050
# verifies: FR-ARCH-060, FR-ARCH-070, FR-ARCH-080, FR-ARCH-090, FR-ARCH-100
# verifies: IF-ARCH-020, IF-ARCH-030, CON-ARCH-010, FR-ARCH-200, FR-ARCH-210
# verifies: FR-ARCH-220, FR-ARCH-230, FR-ARCH-240, FR-ARCH-250, FR-ARCH-260, IF-ARCH-040
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
# --- A file that parses and is not an object is refused the same way, not
# --- with a traceback: IF-ARCH-020 promises 2 for what cannot be read, and a
# --- gate reading the exit code told 1 would call it a bad layer.
printf '[]\n' > "$LAB/arch/arch-config.json"
rule "IF-ARCH-020 a configuration that is not an object is refused" 2 \
     "the top level must be a JSON object"
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

# --- verifies: FR-ARCH-260, IF-ARCH-040 — edges the project supplies are
# --- compared as the ones the checker reads. Sources in a language the
# --- checker does not read; the project says what they depend on.
mkdir -p "$LAB/src/core" "$LAB/src/shell"
printf 'struct Router {}\n' > "$LAB/src/core/Router.swift"
printf 'struct Capsule {}\n' > "$LAB/src/shell/Capsule.swift"
printf 'x = 1\n' > "$LAB/src/a.py"
printf 'x = 1\n' > "$LAB/src/b.py"
elements <<'MD'
# Elements

### E-010 — The core

```yaml
status: built
carries: [src/core, src/a.py]
requirements: [FR-CORE-010]
depends_on: []
```

Declares nothing.

### E-020 — The shell

```yaml
status: built
carries: [src/shell, src/b.py]
requirements: [FR-CORE-020]
depends_on: [E-010]
```

Declares the core.
MD
cat > "$LAB/arch/edges.json" <<'JSON'
[
  {"from": "src/core/Router.swift", "to": "src/shell/Capsule.swift", "via": "Capsule:12"},
  {"from": "src/shell/Capsule.swift", "to": "src/core/Router.swift", "via": "Router:3"},
  {"from": "src/core/Router.swift", "to": "src/core/Other.swift"},
  {"from": "src/core/Router.swift", "to": "vendor/Elsewhere.swift"}
]
JSON
rule "FR-ARCH-260 an edge the model does not declare is reported" 0 \
     "src/core/Router.swift — uses src/shell/Capsule.swift, carried by E-020, and E-010 does not declare it (Capsule:12)"
silent "FR-ARCH-260 a declared edge is silent" 0 "carried by E-010"
silent "FR-ARCH-260 an edge inside one element is not a dependency" 0 "src/core/Other.swift"
silent "FR-ARCH-260 an end no element carries is left alone" 0 "vendor/Elsewhere.swift"

# --- A carrier two elements claim resolves an end to neither, as a module
# --- name two files answer to does: reporting it against either would name an
# --- element the code may never touch.
elements <<'MD'
# Elements

### E-010 — The core

```yaml
status: built
carries: [src/core, src/a.py]
requirements: [FR-CORE-010]
depends_on: []
```

Declares nothing.

### E-020 — The shell

```yaml
status: built
carries: [src/shell, src/b.py]
requirements: [FR-CORE-020]
depends_on: [E-010]
```

Declares the core.

### E-030 — A second claim on the shell

```yaml
status: built
carries: [src/shell]
requirements: [FR-CORE-020]
depends_on: []
```

Claims the same directory.
MD
silent "FR-ARCH-260 an end two elements carry resolves to neither" 0 "does not declare it"
elements <<'MD'
# Elements

### E-010 — The core

```yaml
status: built
carries: [src/core, src/a.py]
requirements: [FR-CORE-010]
depends_on: []
```

Declares nothing.

### E-020 — The shell

```yaml
status: built
carries: [src/shell, src/b.py]
requirements: [FR-CORE-020]
depends_on: [E-010]
```

Declares the core.
MD
rule "FR-ARCH-260 a warning by default, which --strict fails on" 1 \
     "treated as errors" --strict
( cd "$LAB" && printf '{"rules": {"dependency-undeclared": "report"}}\n' > arch/arch-config.json )
rule "FR-ARCH-260 lowered to report under the published name" 0 \
     "note: src/core/Router.swift — uses" --strict
( cd "$LAB" && printf '{"rules": {}}\n' > arch/arch-config.json )

# --- The same pair from both suppliers is one finding.
printf 'import b\n' > "$LAB/src/a.py"
( cd "$LAB" && python3 tools/srs_arch.py --no-write ) > /tmp/srs-arch.log 2>&1 || true
n=$(grep -c "and E-010 does not declare it" /tmp/srs-arch.log)
if [ "$n" != "1" ]; then
    echo "FAIL FR-ARCH-260 a pair said by the import and by the file is one finding — got $n"
    cat /tmp/srs-arch.log; exit 1
fi
passes=$((passes + 1))
printf 'x = 1\n' > "$LAB/src/a.py"

# --- verifies: IF-ARCH-040 — a file the checker cannot read is a setup fault,
# --- exit 2, never a finding; an element identifier as an end is refused with
# --- the reason.
printf 'not json\n' > "$LAB/arch/edges.json"
rule "IF-ARCH-040 malformed JSON is exit 2" 2 "arch/edges.json:"
printf '{"from": "a", "to": "b"}\n' > "$LAB/arch/edges.json"
rule "IF-ARCH-040 the top level is a list" 2 "must be a JSON list"
printf '[{"from": "src/core/Router.swift"}]\n' > "$LAB/arch/edges.json"
rule "IF-ARCH-040 both ends are required" 2 "\`to\` must be a repository-relative file path"
printf '[{"from": "E-010", "to": "src/core/Router.swift"}]\n' > "$LAB/arch/edges.json"
rule "IF-ARCH-040 an element identifier is refused with the reason" 2 \
     "the file names files, not elements"
printf '[{"from": "src/core/Router.swift", "to": "src/shell/Capsule.swift", "via": 7}]\n' > "$LAB/arch/edges.json"
rule "IF-ARCH-040 via is text" 2 "\`via\` must be text"
rm -f "$LAB/arch/edges.json"
rm -rf "$LAB/src/core" "$LAB/src/shell"
silent "FR-ARCH-260 no file, no edges" 0 "uses"

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

# --- A dependency naming no element ends the path, not the run: resolving
# --- it is FR-ARCH-230's error, and the walk must not be what reports it.
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
silent "FR-ARCH-220 an unresolved dependency ends the path, not the run" 1 "circle"

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

# --- verifies: FR-ARCH-230 — a dependency names an element that exists.
elements <<'MD'
# Elements

### E-010 — Points at nothing

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: [E-999]
```

Depends on a part nobody described.
MD
rule "FR-ARCH-230 unresolved dependency" 1 "E-010 depends on E-999, which no element carries"

# --- Declared further down the file is still declared: the rule reads the
# --- whole layer, not the records above the one it is looking at.
elements <<'MD'
# Elements

### E-010 — The first

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: [E-020]
```

Needs the one below.

### E-020 — The second

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: []
```

Declared after it is needed.
MD
silent "FR-ARCH-230 a forward reference resolves" 0 "no element carries"

# --- A cancelled element is present, with a status that says it left.
elements <<'MD'
# Elements

### E-010 — The first

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: [E-020]
```

Needs one that left.

### E-020 — Gone

```yaml
status: withdrawn
carries: []
requirements: []
depends_on: []
```

Left.
MD
silent "FR-ARCH-230 a cancelled target is not absent" 0 "no element carries"

# --- verifies: FR-ARCH-240 — what a part carries can be derived from what it
# --- owns. The rows of the decision table, one fixture each: under the default
# --- nothing changes and a missing key is still missing; under `derived` a
# --- record naming nothing carries what it owns, so neither the emptiness rule
# --- nor the uncarried rule speaks; a file two elements could own goes to the
# --- nearest carrier; what the record names is kept beside what was derived;
# --- and an element owning nothing is empty even though no key is missing.
elements <<'MD'
# Elements

### E-010 — Owns both files, names neither

```yaml
status: built
carries: [src]
```

Owns everything under src/.
MD
rule "FR-ARCH-240 written is the default, so the key is still required" 1 \
     "required key 'requirements' is missing"
printf '{"requirements": "written"}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-240 and required when written is said out loud" 1 \
     "required key 'requirements' is missing"
printf '{"requirements": "derived"}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-240 derived: the key is optional" 0 "is missing" --strict
silent "FR-ARCH-240 derived: an element owning files is not empty" 0 \
       "carries no requirement" --strict
silent "FR-ARCH-240 derived: a requirement whose file is owned is carried" 0 \
       "no element carries it" --strict
# --- The union: the record names what it does not own, and that entry is
# --- the only thing carrying the requirement — nothing owns b.py, so the
# --- file is reported unclaimed and the requirement must not be reported
# --- uncarried. Without --strict, because the unclaimed file is a warning
# --- this fixture expects. A second element owning b.py would carry the
# --- requirement by derivation and prove nothing about the written half.
elements <<'MD'
# Elements

### E-010 — Owns the first, answers for the second

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-020]
```

Owns a.py and answers for what b.py realizes.
MD
rule "FR-ARCH-240 derived: a file nobody owns is still unclaimed" 0 \
     "src/b.py — named by FR-CORE-020 and carried by no element"
silent "FR-ARCH-240 derived: a written entry is kept beside the derived" 0 \
       "FR-CORE-020 is implemented and no element carries it"
# --- The nearest carrier owns the file, the same answer FR-ARCH-060 gives.
elements <<'MD'
# Elements

### E-010 — The directory

```yaml
status: built
carries: [src]
```

Owns src/ except what a nearer carrier claims.

### E-020 — One file out of it

```yaml
status: built
carries: [src/b.py]
```

Owns b.py alone.
MD
( cd "$LAB" && python3 tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 \
    || { echo "FAIL FR-ARCH-240 — the derived layer does not pass"; cat /tmp/srs-arch.log; exit 1; }
grep -qE '^\| \*\*E-010\*\*.*\| FR-CORE-010 \(1 realized\) \|$' "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-240 — the directory carries only what no nearer carrier owns"
         cat "$LAB/arch/90-map.md"; exit 1; }
grep -qE '^\| \*\*E-020\*\*.*\| FR-CORE-020 \(1 realized\) \|$' "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-240 — the nearer carrier owns the file"
         cat "$LAB/arch/90-map.md"; exit 1; }
passes=$((passes + 1))
# --- Owning nothing is still empty: the derivation found nothing, and no key
# --- is missing to say so instead.
elements <<'MD'
# Elements

### E-010 — Owns nothing anybody realizes

```yaml
status: built
carries: [t]
```

Owns the tests and nothing else.
MD
rule "FR-ARCH-240 derived: an element owning nothing is empty" 0 \
     "E-010 carries no requirement"
# --- And one owning nothing but naming something is not: the written half
# --- counts for emptiness as it counts for carrying.
elements <<'MD'
# Elements

### E-010 — Owns nothing, answers for the first

```yaml
status: built
carries: [t]
requirements: [FR-CORE-010]
```

Owns the tests and answers for the first.
MD
silent "FR-ARCH-240 derived: a written entry alone keeps an element from being empty" 0 \
       "carries no requirement"
# --- Only what is realized, and only through `code`: a deferred requirement
# --- naming an owned file is not carried, a test file an element owns makes
# --- it carry nothing, and an entry the record names that the derivation
# --- would also produce is printed once, in the specification's order.
# --- The two requirements stay in the lab from here on; nothing below
# --- assumes they are absent.
mkdir -p "$LAB/t"; printf 'x\n' > "$LAB/t/x.sh"
cat >> "$LAB/specs/10-fr-core.md" <<'MD'

### FR-CORE-050 — Approved, not built

```yaml
status: deferred
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [src/b.py]
tests: []
created: 2026-09-17
```

The system **shall** eventually act.

### FR-CORE-060 — Realized in both files, proven in t

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [src/a.py, src/b.py]
tests: [t/x.sh]
created: 2026-09-17
```

The system **shall** act again.
MD
elements <<'MD'
# Elements

### E-010 — Owns the sources, names one of them

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010]
```

Owns src/ and names what it would have derived anyway.

### E-020 — Owns the tests

```yaml
status: built
carries: [t]
```

Owns t/ and nothing a requirement realizes.
MD
rule "FR-ARCH-240 derived: a test file an element owns carries nothing" 0 \
     "E-020 carries no requirement"
( cd "$LAB" && python3 tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 \
    || { echo "FAIL FR-ARCH-240 — the derived layer does not pass"; cat /tmp/srs-arch.log; exit 1; }
grep -qF '| **FR-CORE-010**, FR-CORE-020, FR-CORE-060 (3 realized) |' "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-240 — only realized requirements, through code, each once, in order"
         cat "$LAB/arch/90-map.md"; exit 1; }
passes=$((passes + 1))
# --- A mode this checker does not publish is a setup error, like a rule it
# --- does not publish.
printf '{"requirements": "guessed"}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-240 an unknown mode is refused before anything is read" 2 \
     "expected written/derived"

# --- verifies: FR-ARCH-250 — the map marks what was written apart from what
# --- was derived. One element naming one requirement and owning the file of
# --- two others: the named one is bold, the derived ones plain, and the map
# --- says so above the table. The second derived one is the requirement
# --- realized in both files, and it lands here as it landed in the element
# --- owning the other file — the case a specification by capability produces
# --- on every second requirement. Then the same layer under the default, where the
# --- legend is absent and nothing is derived — which is the assertion that
# --- reddens the day the mark is printed unconditionally.
printf '{"requirements": "derived"}\n' > "$LAB/arch/arch-config.json"
elements <<'MD'
# Elements

### E-010 — Names one, owns the other

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-010]
```

Answers for the first and owns what realizes the second.
MD
( cd "$LAB" && python3 tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 \
    || { echo "FAIL FR-ARCH-250 — the derived layer does not pass"; cat /tmp/srs-arch.log; exit 1; }
grep -qF '| **FR-CORE-010**, FR-CORE-020, FR-CORE-060 (3 realized) |' "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-250 — the map does not mark written apart from derived"
         cat "$LAB/arch/90-map.md"; exit 1; }
grep -qF 'Requirements are derived' "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-250 — the map does not say what the mark means"
         cat "$LAB/arch/90-map.md"; exit 1; }
passes=$((passes + 1))
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"
( cd "$LAB" && python3 tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 \
    || { echo "FAIL FR-ARCH-250 — the written layer does not pass"; cat /tmp/srs-arch.log; exit 1; }
grep -qF '| **FR-CORE-010** (1 realized) |' "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-250 — under the default nothing is derived"
         cat "$LAB/arch/90-map.md"; exit 1; }
if grep -qF 'Requirements are derived' "$LAB/arch/90-map.md"; then
    echo "FAIL FR-ARCH-250 — the legend is printed where nothing is derived"
    cat "$LAB/arch/90-map.md"; exit 1
fi
passes=$((passes + 1))

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

# --- verifies: FR-ARCH-270 — an element is cited like a requirement: the
# --- form the viewer prints, over the layer's own records, in the order
# --- asked; an unknown identifier is named and fails the run without
# --- dropping the ones that resolve; nothing is written.
elements <<'MD'
# Elements

### E-010 — The first

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: []
```

One.

### E-020 — The second, cancelled

```yaml
status: withdrawn
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: []
```

Gone, and cited with the status that says so.
MD
rm -f "$LAB/arch/90-map.md"
rc=0
( cd "$LAB" && python3 tools/srs_arch.py --cite E-020 E-010 E-990 ) \
    > /tmp/srs-arch-cite.out 2> /tmp/srs-arch-cite.err || rc=$?
cat > /tmp/srs-arch-cite.want <<'WANT'
E-020 — The second, cancelled (arch/00-elements.md, withdrawn)
E-010 — The first (arch/00-elements.md, built)
WANT
diff -u /tmp/srs-arch-cite.want /tmp/srs-arch-cite.out \
    || { echo "FAIL FR-ARCH-270 — --cite printed something other than the form, or lost the order"; exit 1; }
[ "$rc" = 1 ] || { echo "FAIL FR-ARCH-270 — an unknown element left --cite with exit $rc"; exit 1; }
grep -q "no element E-990" /tmp/srs-arch-cite.err \
    || { echo "FAIL FR-ARCH-270 — --cite did not say which element it could not resolve"; exit 1; }
[ -f "$LAB/arch/90-map.md" ] \
    && { echo "FAIL FR-ARCH-270 — a citation wrote the map"; exit 1; }
rule "FR-ARCH-270 --cite with nothing to cite is a setup fault" 2 "needs at least one" --cite
passes=$((passes + 4))

# --- verifies: INV-SPEC-080 — an element's number widens like a requirement's:
# --- E-1000 is an identifier, E-0100 is not.
# --- verifies: INV-SPEC-090 — and the map orders E-1000 after E-990.
elements <<'MD'
# Elements

### E-100 — Hundred

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: []
```

One.

### E-1000 — Thousand

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: [E-990]
```

Two.

### E-990 — Nine ninety

```yaml
status: proposed
carries: []
requirements: []
depends_on: []
```

Three, carrying nothing yet.
MD
# Warnings are expected of this fixture — a proposed part carrying nothing,
# requirements no element carries — and are not what it asserts; an error
# would be, and the exit code says which it was.
rc=0; ( cd "$LAB" && python3 tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 || rc=$?
[ "$rc" = 0 ] || { echo "FAIL INV-SPEC-080 — the wide fixture exited $rc"; cat /tmp/srs-arch.log; exit 1; }
grep -q "identifier does not match" /tmp/srs-arch.log && { echo "FAIL INV-SPEC-080 — a wide element number was refused"; cat /tmp/srs-arch.log; exit 1; }
python3 - "$LAB/arch/90-map.md" <<'PY' || { echo "FAIL INV-SPEC-090 — the map orders elements as strings"; exit 1; }
import re, sys
rows = re.findall(r"^\| \*\*(E-\d+)\*\*", open(sys.argv[1], encoding="utf-8").read(), re.M)
assert rows == ["E-100", "E-990", "E-1000"], rows
PY
passes=$((passes + 1))
elements <<'MD'
# Elements

### E-0100 — A leading zero

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Not an identifier.
MD
rule "INV-SPEC-080 a leading zero is refused" 1 "identifier does not match"

# --- verifies: FR-ARCH-280 — a path an element carries and nobody has is a
# --- warning named carrier-missing, naming the element and the path. The lab
# --- is no git repository, so the warning stands without a hint; a git lab
# --- below gets the hint for a committed rename, a committed deletion and a
# --- rename still in the working tree, and nothing for a file git never saw.
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"
elements <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src, src/vanished.py]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries the whole of it, and one file nobody has.
MD
rule "FR-ARCH-280 a carried path that does not exist" 0 "E-010 carries src/vanished.py, which does not exist"
silent "FR-ARCH-280 says nothing of where it went outside git" 0 "git renamed\|git deleted\|in the working tree"
rule "FR-ARCH-280 fails a strict gate" 1 "treated as errors" --strict
printf '{"rules": {"carrier-missing": "off"}}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-280 turned off says nothing" 0 "does not exist"
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"
# A directory is a carrier too, and one that is there is not reported.
elements <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src, src/]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries a directory, spelled both ways.
MD
silent "FR-ARCH-280 a directory that exists is not reported" 0 "does not exist"

# The git lab: a file renamed and committed, a file deleted and committed, a
# file renamed in the working tree, and a file git never saw.
GITLAB=/tmp/srs-arch-git
rm -rf "$GITLAB"; mkdir -p "$GITLAB/tools" "$GITLAB/specs" "$GITLAB/arch" "$GITLAB/src"
cp tools/srs_arch.py tools/srs_parse.py tools/srs_check.py tools/srs_view.py "$GITLAB/tools/"
cp "$LAB/specs/srs-config.json" "$GITLAB/specs/"
cp "$LAB/specs/10-fr-core.md" "$GITLAB/specs/"
printf '{"rules": {}}\n' > "$GITLAB/arch/arch-config.json"
printf 'a = 1\n' > "$GITLAB/src/a.py"; printf 'b = 1\n' > "$GITLAB/src/b.py"
printf 'old = 1\n' > "$GITLAB/src/old.py"; printf 'gone = 1\n' > "$GITLAB/src/gone.py"; printf 'wt = 1\n' > "$GITLAB/src/wt.py"
printf 'x = 1\n' > "$GITLAB/src/файл.py"    # a path outside ASCII, which git quotes unless told not to
cat > "$GITLAB/arch/00-elements.md" <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src/a.py, src/b.py, src/old.py, src/gone.py, src/wt.py, src/never.py, src/файл.py]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries files that will move.
MD
( cd "$GITLAB" && git init -q && git add -A \
  && git -c user.email=ci@example.com -c user.name=CI commit -qm base \
  && git mv src/old.py src/new.py && git rm -q src/gone.py && git mv src/файл.py src/файл2.py \
  && git -c user.email=ci@example.com -c user.name=CI commit -qm moved \
  && git mv src/wt.py src/wt2.py )
( cd "$GITLAB" && python3 tools/srs_arch.py --no-write ) > /tmp/srs-arch-git.log 2>&1 || true
grep -q "E-010 carries src/old.py, which does not exist; git renamed it to src/new.py in [0-9a-f]\{7,\}$" /tmp/srs-arch-git.log \
    || { echo "FAIL FR-ARCH-280 — a committed rename is not named with its new path and commit"; cat /tmp/srs-arch-git.log; exit 1; }
grep -q "E-010 carries src/gone.py, which does not exist; git deleted it in [0-9a-f]\{7,\}$" /tmp/srs-arch-git.log \
    || { echo "FAIL FR-ARCH-280 — a committed deletion is not named with its commit"; cat /tmp/srs-arch-git.log; exit 1; }
grep -q "E-010 carries src/wt.py, which does not exist; renamed to src/wt2.py in the working tree$" /tmp/srs-arch-git.log \
    || { echo "FAIL FR-ARCH-280 — a rename in the working tree is not named"; cat /tmp/srs-arch-git.log; exit 1; }
grep -q "E-010 carries src/never.py, which does not exist$" /tmp/srs-arch-git.log \
    || { echo "FAIL FR-ARCH-280 — a file git never saw got a hint, or no warning"; cat /tmp/srs-arch-git.log; exit 1; }
grep -q "E-010 carries src/файл.py, which does not exist; git renamed it to src/файл2.py in [0-9a-f]\{7,\}$" /tmp/srs-arch-git.log \
    || { echo "FAIL FR-ARCH-280 — a rename of a path outside ASCII is not named as git wrote it"; cat /tmp/srs-arch-git.log; exit 1; }
grep -q "src/a.py, which does not exist\|src/b.py, which does not exist" /tmp/srs-arch-git.log \
    && { echo "FAIL FR-ARCH-280 — a file that exists was reported"; cat /tmp/srs-arch-git.log; exit 1; }
passes=$((passes + 1))

echo "arch-rules: $passes fixtures pass"
