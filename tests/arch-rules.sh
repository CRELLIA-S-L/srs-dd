#!/usr/bin/env bash
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# One fixture per rule of the architecture checker, each breaking exactly one
# thing, so a failure names the rule that stopped working.
#
# verifies: FR-ARCH-010, FR-ARCH-020, FR-ARCH-030, FR-ARCH-040, FR-ARCH-050
# verifies: FR-ARCH-060, FR-ARCH-070, FR-ARCH-080, FR-ARCH-090, FR-ARCH-100
# verifies: IF-ARCH-020, IF-ARCH-030, CON-ARCH-010, FR-ARCH-200, FR-ARCH-210
# verifies: FR-ARCH-220, FR-ARCH-230, FR-ARCH-240, FR-ARCH-250, FR-ARCH-260, IF-ARCH-040
# verifies: FR-ARCH-310, FR-ARCH-320, FR-ARCH-330, FR-ARCH-340, FR-ARCH-350
# verifies: FR-ARCH-360, FR-ARCH-370, FR-ARCH-380, FR-ARCH-390, FR-ARCH-400, IF-ARCH-050
# verifies: FR-ARCH-470, FR-ARCH-480, IF-ARCH-060, FR-ARCH-490, FR-ARCH-500
# verifies: FR-ARCH-560, FR-ARCH-540, FR-ARCH-570, FR-ARCH-580
# verifies: FR-ARCH-590, FR-ARCH-600, IF-ARCH-070
# verifies: FR-ARCH-610, FR-ARCH-620, IF-ARCH-080
#
# Several of these assert that the checker stays quiet, and they are why this
# file exists rather than a smoke test: delete the rule underneath one and the
# checker goes quiet for the wrong reason, so the fixture passes and proves
# nothing. Which ones they are is not written out here — they are the `silent`
# calls below, and that list cannot fall behind the file the way a copy of it
# in this comment did: this comment named two of them and 50-verification.md
# named three others, and neither reader could tell which set was meant.
set -eo pipefail

# srs-end: FR-ARCH-010
# implements: FR-CI-090
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."
. tools/test_lib.sh

LAB=/tmp/srs-arch
rm -rf "$LAB"
mkdir -p "$LAB/srs-dd/tools" "$LAB/specs" "$LAB/arch" "$LAB/src"
cp srs-dd/tools/srs_arch.py srs-dd/tools/srs_parse.py srs-dd/tools/srs_check.py srs-dd/tools/srs_view.py \
   srs-dd/tools/srs_view_model.py "$LAB/srs-dd/tools/"
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
    ( cd "$LAB" && python3 srs-dd/tools/srs_arch.py --no-write "$@" ) > /tmp/srs-arch.log 2>&1 || rc=$?
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
    ( cd "$LAB" && python3 srs-dd/tools/srs_arch.py --no-write "$@" ) > /tmp/srs-arch.log 2>&1 || rc=$?
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

# srs-end: FR-CI-090
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

# srs-end: FR-ARCH-020
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

# srs-end: FR-ARCH-030
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

# srs-end: FR-ARCH-040
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

# srs-end: FR-ARCH-050
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

# srs-end: FR-ARCH-060
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

# srs-end: FR-ARCH-070
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

# srs-end: FR-ARCH-080
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
# srs-end: FR-ARCH-100
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

# srs-end: FR-ARCH-090, IF-ARCH-030
# --- verifies: IF-ARCH-020 — the third exit code is for what cannot be read.
rule "IF-ARCH-020 unknown flag" 2 "unknown flag(s): --nope" --nope
mv "$LAB/srs-dd/tools/srs_view.py" "$LAB/srs-dd/tools/srs_view.hidden"
rule "IF-ARCH-020 no viewer to read the model through" 2 "srs-dd/tools/srs_view.py is not here"
mv "$LAB/srs-dd/tools/srs_view.hidden" "$LAB/srs-dd/tools/srs_view.py"

# srs-end: IF-ARCH-020
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

# srs-end: FR-ARCH-200
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
( cd "$LAB" && python3 srs-dd/tools/srs_arch.py --no-write ) > /tmp/srs-arch.log 2>&1 || true
n=$(grep -c "and E-010 does not declare it" /tmp/srs-arch.log)
if [ "$n" != "1" ]; then
    echo "FAIL FR-ARCH-260 a pair said by the import and by the file is one finding — got $n"
    cat /tmp/srs-arch.log; exit 1
fi
passes=$((passes + 1))
printf 'x = 1\n' > "$LAB/src/a.py"

# srs-end: FR-ARCH-260, IF-ARCH-040
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

# srs-end: IF-ARCH-040
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
# Exit 1 is also what a traceback exits with: the run has to have reached
# the end and said so, the error for E-999 printed and no crash in between.
silent "FR-ARCH-220 the walk does not crash on it" 1 "Traceback"
grep -qF "E-010 depends on E-999, which no element carries" /tmp/srs-arch.log \
    || { echo "FAIL FR-ARCH-220 — the run did not finish with the error for E-999"; cat /tmp/srs-arch.log; exit 1; }

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

# srs-end: FR-ARCH-220
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

# srs-end: FR-ARCH-230
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
( cd "$LAB" && python3 srs-dd/tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 \
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
( cd "$LAB" && python3 srs-dd/tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 \
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

# srs-end: FR-ARCH-240
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
( cd "$LAB" && python3 srs-dd/tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 \
    || { echo "FAIL FR-ARCH-250 — the derived layer does not pass"; cat /tmp/srs-arch.log; exit 1; }
grep -qF '| **FR-CORE-010**, FR-CORE-020, FR-CORE-060 (3 realized) |' "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-250 — the map does not mark written apart from derived"
         cat "$LAB/arch/90-map.md"; exit 1; }
grep -qF 'Requirements are derived' "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-250 — the map does not say what the mark means"
         cat "$LAB/arch/90-map.md"; exit 1; }
passes=$((passes + 1))
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"
( cd "$LAB" && python3 srs-dd/tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 \
    || { echo "FAIL FR-ARCH-250 — the written layer does not pass"; cat /tmp/srs-arch.log; exit 1; }
grep -qF '| **FR-CORE-010** (1 realized) |' "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-250 — under the default nothing is derived"
         cat "$LAB/arch/90-map.md"; exit 1; }
if grep -qF 'Requirements are derived' "$LAB/arch/90-map.md"; then
    echo "FAIL FR-ARCH-250 — the legend is printed where nothing is derived"
    cat "$LAB/arch/90-map.md"; exit 1
fi
passes=$((passes + 1))

# srs-end: FR-ARCH-250
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
( cd "$LAB" && python3 srs-dd/tools/srs_arch.py --drivers ) > /tmp/srs-arch-drivers.log 2>&1 \
    || { echo "FAIL FR-ARCH-210 — --drivers exited non-zero"
         cat /tmp/srs-arch-drivers.log; exit 1; }
head -3 /tmp/srs-arch-drivers.log | grep -qF "FR-CORE-010" \
    || { echo "FAIL FR-ARCH-210 — the most linked requirement does not lead"
         cat /tmp/srs-arch-drivers.log; exit 1; }
grep -qF "1 incoming" /tmp/srs-arch-drivers.log \
    || { echo "FAIL FR-ARCH-210 — the ranking does not say what it counted"
         cat /tmp/srs-arch-drivers.log; exit 1; }
passes=$((passes + 1))

# srs-end: FR-ARCH-210
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
rm -rf "$LAB2"; mkdir -p "$LAB2/srs-dd/tools" "$LAB2/specs" "$LAB2/arch" "$LAB2/src"
cp srs-dd/tools/srs_arch.py srs-dd/tools/srs_parse.py srs-dd/tools/srs_check.py srs-dd/tools/srs_view.py \
   srs-dd/tools/srs_view_model.py "$LAB2/srs-dd/tools/"
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
( cd "$LAB2" && python3 srs-dd/tools/srs_arch.py ) > /dev/null 2>&1
[ -f "$LAB2/arch/90-map.md" ] \
    || { echo "FAIL CON-ARCH-010 — the run wrote no map, so this assertion"
         echo "would hold for a checker that did nothing"; exit 1; }
weigh > "$AFTER"
cmp -s "$BEFORE" "$AFTER" \
    || { echo "FAIL CON-ARCH-010 — a run touched something outside the layer"
         diff "$BEFORE" "$AFTER" | head -10; exit 1; }
passes=$((passes + 2))

# srs-end: CON-ARCH-010
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
( cd "$LAB" && python3 srs-dd/tools/srs_arch.py --cite E-020 E-010 E-990 ) \
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

# srs-end: FR-ARCH-270
# --- verifies: INV-SPEC-080 — an element's number widens like a requirement's:
# --- E-1000 is an identifier, E-0100 is not.
# srs-end: INV-SPEC-080
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
rc=0; ( cd "$LAB" && python3 srs-dd/tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 || rc=$?
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

# srs-end: INV-SPEC-090
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
# Where git put the file is a clause after "does not exist", opened with "; ";
# outside git there is none. (-F takes the fragment literally, so one
# fragment covers every clause rather than an alternation it cannot read.)
silent "FR-ARCH-280 says nothing of where it went outside git" 0 "does not exist;"
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
rm -rf "$GITLAB"; mkdir -p "$GITLAB/srs-dd/tools" "$GITLAB/specs" "$GITLAB/arch" "$GITLAB/src"
cp srs-dd/tools/srs_arch.py srs-dd/tools/srs_parse.py srs-dd/tools/srs_check.py srs-dd/tools/srs_view.py \
   srs-dd/tools/srs_view_model.py "$GITLAB/srs-dd/tools/"
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
( cd "$GITLAB" && python3 srs-dd/tools/srs_arch.py --no-write ) > /tmp/srs-arch-git.log 2>&1 || true
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

# --- verifies: FR-ARCH-310, FR-ARCH-320 — design mode: a part designed and
# --- not yet built. Appended last: the approved requirement it needs would
# --- otherwise be unanswered for in every fixture above.
cat >> "$LAB/specs/10-fr-core.md" <<'MD'

### FR-CORE-070 — The approved one

```yaml
status: deferred
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-10-04
```

The system **shall** act once somebody builds it.
MD

elements <<'MD'
# Elements

### E-010 — Everything built

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries what exists.
MD
rule "FR-ARCH-320 an approved requirement nobody answers for" 0 \
    "FR-CORE-070 is deferred and no element answers for it"

# A backlog is not a defect: a note by default, a warning once priced up. The
# layer below is otherwise silent, so the exit code is about the note alone.
elements <<'MD'
# Elements

### E-010 — Everything built

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-040, FR-CORE-060]
depends_on: []
```

Carries every file and every realized obligation.
MD
rule "FR-ARCH-320 a note by default" 0 "note: specs/10-fr-core.md — FR-CORE-070 is deferred"
silent "FR-ARCH-320 a strict run passes over the note" 0 "treated as errors" --strict
printf '{"rules": {"requirement-unassigned": "warn"}}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-320 priced up, it fails a strict run" 1 "treated as errors" --strict
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"

elements <<'MD'
# Elements

### E-010 — Everything built

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Carries what exists.

### E-020 — The part that will carry the third

```yaml
status: proposed
carries: [src/later]
requirements: [FR-CORE-070]
depends_on: [E-010]
```

Will carry it once somebody builds it.
MD
silent "FR-ARCH-320 a design answers for an approved requirement" 0 \
    "FR-CORE-070 is deferred and no element answers"
silent "FR-ARCH-310 a designed part's carriers need not exist" 0 \
    "src/later, which does not exist"
silent "FR-ARCH-330 a design whose files are absent is not called built" 0 \
    "every file it carries exists"

# srs-end: FR-ARCH-310, FR-ARCH-320
# --- verifies: FR-ARCH-340 — a design claims a file a built part does not own:
# --- the file is still unclaimed, the obligation still answered for.
elements <<'MD'
# Elements

### E-010 — Half of it

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: []
```

Carries half.

### E-020 — The part that will take the other half

```yaml
status: proposed
carries: [src/a.py]
requirements: [FR-CORE-010, FR-CORE-070]
depends_on: []
```

Will take the first file.
MD
rule "FR-ARCH-340 a designed part does not own its files yet" 0 \
    "src/a.py — named by FR-CORE-010 and carried by no element"
silent "FR-ARCH-340 and it does carry the obligation" 0 \
    "FR-CORE-010 is implemented and no element carries it"
silent "FR-ARCH-330 a design with an unbuilt obligation is not called built" 0 \
    "every requirement it carries is realized"

# srs-end: FR-ARCH-340
# --- verifies: FR-ARCH-330 — a design whose files are all here and whose
# --- obligations are all built is a built part with the wrong status on it.
elements <<'MD'
# Elements

### E-010 — The design that shipped

```yaml
status: proposed
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
```

Everything it names is already here.
MD
rule "FR-ARCH-330 a design that is already built" 0 \
    "E-010 is proposed, and every file it carries exists and every requirement it carries is realized"

elements <<'MD'
# Elements

### E-010 — A part designed and empty

```yaml
status: proposed
carries: []
requirements: []
depends_on: []
```

Answers to nothing yet.
MD
rule "FR-ARCH-330 an empty design is reported as empty" 0 "carries no requirement"
silent "FR-ARCH-330 and not as built" 0 "every requirement it carries is realized"

# srs-end: FR-ARCH-330

# --- verifies: FR-ARCH-350 — what moving to the designed parts requires.
elements <<'MD'
# Elements

### E-010 — The old whole

```yaml
status: built
carries: [src/a.py, src/b.py]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: [E-020]
```

Carries both files today.

### E-020 — What the old whole leans on

```yaml
status: built
carries: [t]
requirements: []
depends_on: []
```

Carries the suites.

### E-030 — The design

```yaml
status: proposed
carries: [src/a.py, src/later]
requirements: [FR-CORE-010, FR-CORE-070]
depends_on: [E-020]
```

Takes one file that exists and one that does not.
MD
rule "FR-ARCH-350 a file changes hands, both ends named" 0 \
    "file  src/a.py — from E-010" --plan
rule "FR-ARCH-350 a file the repository does not have yet" 0 \
    "file  src/later — not in the repository yet" --plan
rule "FR-ARCH-350 an obligation changes part" 0 \
    "holds FR-CORE-010 — from E-010" --plan
rule "FR-ARCH-350 an obligation no part carries today" 0 \
    "holds FR-CORE-070 — no part carries it today" --plan
rule "FR-ARCH-350 a dependency the design adds" 0 \
    "needs E-020 — a dependency the built parts do not have" --plan
silent "FR-ARCH-350 a part keeping a file of its own does not fall away" 0 \
    "Falls away" --plan
silent "FR-ARCH-350 the plan reports no finding" 0 "warning:" --plan
silent "FR-ARCH-350 an absent path names no part as losing it" 0 \
    "file  src/later — from" --plan

# --- A path that exists and no built part owns is the other reading, and the
# --- two must not be told as one.
elements <<'MD'
# Elements

### E-010 — Half of it

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010, FR-CORE-040]
depends_on: []
```

Carries one file.

### E-030 — The design

```yaml
status: proposed
carries: [src/b.py]
requirements: [FR-CORE-020, FR-CORE-070]
depends_on: []
```

Takes a file nobody owns today.
MD
rule "FR-ARCH-350 a file that exists and no part owns" 0 \
    "file  src/b.py — no part owns it today" --plan

# --- A record the reading could not take is said, not dropped in silence.
elements <<'MD'
# Elements

### E-010 — Everything built

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-040, FR-CORE-060, FR-CORE-070]
depends_on: []
```

Carries all of it.

### E-03 — Two digits short

```yaml
status: proposed
carries: [src/later]
requirements: [FR-CORE-070]
depends_on: []
```

A typo in the identifier.
MD
rule "FR-ARCH-350 a record it could not read is said" 0 \
    "1 record(s) could not be read and are not in this plan" --plan

# --- A design that claims every file of a built part dissolves it, and the
# --- dependencies it declared go with it.
elements <<'MD'
# Elements

### E-010 — The old whole

```yaml
status: built
carries: [src/a.py, src/b.py]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: [E-020]
```

Carries both files today.

### E-020 — What the old whole leans on

```yaml
status: built
carries: [t]
requirements: []
depends_on: []
```

Carries the suites.

### E-030 — The design

```yaml
status: proposed
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-070]
depends_on: [E-020]
```

Takes the whole directory, and with it everything E-010 had.
MD
rule "FR-ARCH-350 a part the design empties falls away" 0 \
    "E-010 — The old whole keeps no file of its own under the design" --plan
rule "FR-ARCH-350 and its dependency goes with it" 0 \
    "E-010 → E-020 — the dependency goes with it" --plan

# --- Nothing designed: the command says so rather than printing an empty plan.
elements <<'MD'
# Elements

### E-010 — Everything built

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-070]
depends_on: []
```

Carries all of it.
MD
rule "FR-ARCH-350 nothing designed" 0 \
    "No part is designed and unbuilt, so there is nothing to move." --plan

# srs-end: FR-ARCH-350

# --- verifies: IF-ARCH-050, FR-ARCH-360 — the move record: the second kind
# --- of record this layer holds, in a file of its own.
mkdir -p "$LAB/specs/adr"
cat > "$LAB/specs/adr/ADR-0001-the-cut-changes.md" <<'MD'
# ADR-0001 — The cut changes

- **Status:** accepted
MD

# moves <<'MD' — the redraws under test, replaced by every fixture.
moves() { cat > "$LAB/arch/10-moves.md"; }

elements <<'MD'
# Elements

### E-010 — The part losing a file

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: []
```

Carries the file today.

### E-020 — The part taking it

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020, FR-CORE-070]
depends_on: []
```

Will carry it.
MD

moves <<'MD'
# Moves

### M-01 — Two digits short

```yaml
status: planned
from: [E-010]
to: [E-020]
moves: [src/a.py]
adr: ADR-0001
```

Hands the file over.
MD
rule "FR-ARCH-360 malformed identifier" 1 "identifier does not match E-<NNN> or M-<NNN>"

moves <<'MD'
# Moves

### M-010 — The first

```yaml
status: planned
from: [E-010]
to: [E-020]
moves: [src/a.py]
adr: ADR-0001
```

Hands the file over.

### M-010 — The same number again

```yaml
status: planned
from: [E-010]
to: [E-020]
moves: [src/b.py]
adr: ADR-0001
```

Hands another over.
MD
rule "FR-ARCH-360 duplicate identifier" 1 "M-010 is already used at"

moves <<'MD'
# Moves

### M-010 — No list of what moves

```yaml
status: planned
from: [E-010]
to: [E-020]
adr: ADR-0001
```

Says nothing about what changes hands.
MD
rule "FR-ARCH-360 missing key" 1 "required key 'moves' is missing"

moves <<'MD'
# Moves

### M-010 — A state of its own invention

```yaml
status: started
from: [E-010]
to: [E-020]
moves: [src/a.py]
adr: ADR-0001
```

Hands the file over.
MD
rule "FR-ARCH-360 status outside the four" 1 \
    "status 'started' is not one of planned, moving, done, abandoned"

# srs-end: FR-ARCH-360, IF-ARCH-050
# --- verifies: FR-ARCH-370 — a move names parts and a decision that exist.
moves <<'MD'
# Moves

### M-010 — Into a part nobody wrote down

```yaml
status: planned
from: [E-010]
to: [E-990]
moves: [src/a.py]
adr: ADR-0001
```

Hands the file to a part that does not exist.
MD
rule "FR-ARCH-370 an end no element carries" 1 \
    'M-010 names E-990 in `to`, which no element carries'

moves <<'MD'
# Moves

### M-010 — Behind a decision nobody wrote

```yaml
status: planned
from: [E-010]
to: [E-020]
moves: [src/a.py]
adr: ADR-0099
```

Hands the file over for reasons recorded nowhere.
MD
rule "FR-ARCH-370 a decision the specification does not hold" 1 \
    "M-010 names ADR-0099, and the specification holds no document named after it"

# srs-end: FR-ARCH-370
# --- verifies: FR-ARCH-380 — a move in force whose paths are all at the
# --- receiving end is finished, and only its status still says otherwise.
elements <<'MD'
# Elements

### E-010 — The part that lost the file

```yaml
status: built
carries: []
requirements: [FR-CORE-010]
depends_on: []
```

Carries nothing any more.

### E-020 — The part that took it

```yaml
status: built
carries: [src/a.py, src/b.py]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-070]
depends_on: []
```

Carries both now.
MD
moves <<'MD'
# Moves

### M-010 — The file changes hands

```yaml
status: moving
from: [E-010]
to: [E-020]
moves: [src/a.py]
adr: ADR-0001
```

Hands the file over.
MD
rule "FR-ARCH-380 a finished move is reported as finished" 0 \
    "M-010 has every path it moves at E-020 and none at E-010, and its status still says moving"

moves <<'MD'
# Moves

### M-010 — The file changed hands and the record was closed

```yaml
status: done
from: [E-010]
to: [E-020]
moves: [src/a.py]
adr: ADR-0001
```

Handed the file over.
MD
silent "FR-ARCH-380 a closed move is not reported" 0 "has every path it moves"

# --- A path still at the leaving end has not arrived.
elements <<'MD'
# Elements

### E-010 — The part still holding it

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: []
```

Has not handed it over yet.

### E-020 — The part waiting for it

```yaml
status: built
carries: [src/a.py, src/b.py]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-070]
depends_on: []
```

Claims it too, for now.
MD
moves <<'MD'
# Moves

### M-010 — Half handed over

```yaml
status: moving
from: [E-010]
to: [E-020]
moves: [src/a.py]
adr: ADR-0001
```

Hands the file over.
MD
silent "FR-ARCH-380 a path at both ends has not arrived" 0 "has every path it moves"

# srs-end: FR-ARCH-380
# --- verifies: FR-ARCH-390 — a path at neither end cannot be moved as written.
elements <<'MD'
# Elements

### E-010 — The leaving part

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: []
```

Carries one file.

### E-020 — The receiving part

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020, FR-CORE-070]
depends_on: []
```

Carries the other.
MD
moves <<'MD'
# Moves

### M-010 — A file neither part has

```yaml
status: planned
from: [E-010]
to: [E-020]
moves: [src/ghost.py]
adr: ADR-0001
```

Hands over something nobody carries.
MD
rule "FR-ARCH-390 a path at neither end" 0 \
    "M-010 moves src/ghost.py, which no element at either end carries"

moves <<'MD'
# Moves

### M-010 — A file the leaving part has

```yaml
status: planned
from: [E-010]
to: [E-020]
moves: [src/a.py]
adr: ADR-0001
```

Hands over what E-010 carries today.
MD
silent "FR-ARCH-390 a path one end carries is not an orphan" 0 "which no element at either end carries"

# srs-end: FR-ARCH-390
# --- verifies: FR-ARCH-400 — the map says what is moving, and says nothing of
# --- a move that is over.
( cd "$LAB" && python3 srs-dd/tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 || {
    echo "FAIL FR-ARCH-400 — the run that writes the map failed"; cat /tmp/srs-arch.log; exit 1; }
grep -qF "## What is moving" "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-400 — the map holds no section for what is moving"; exit 1; }
grep -qF "| **M-010** A file the leaving part has | \`planned\` | E-010 | E-020 | \`src/a.py\` |" "$LAB/arch/90-map.md" \
    || { echo "FAIL FR-ARCH-400 — the map does not say what the move moves, between which parts, in what state"
         sed -n '/What is moving/,$p' "$LAB/arch/90-map.md"; exit 1; }
passes=$((passes + 1))

moves <<'MD'
# Moves

### M-010 — A move that is over

```yaml
status: done
from: [E-010]
to: [E-020]
moves: [src/a.py]
adr: ADR-0001
```

Handed over long ago.
MD
( cd "$LAB" && python3 srs-dd/tools/srs_arch.py ) > /tmp/srs-arch.log 2>&1 || {
    echo "FAIL FR-ARCH-400 — the run that writes the map failed"; cat /tmp/srs-arch.log; exit 1; }
grep -qF "## What is moving" "$LAB/arch/90-map.md" \
    && { echo "FAIL FR-ARCH-400 — a closed move is in the map"; exit 1; }
passes=$((passes + 1))

rm -f "$LAB/arch/10-moves.md"
# srs-end: FR-ARCH-400

# --- verifies: IF-ARCH-060, FR-ARCH-470, FR-ARCH-480 — a dependency the
# --- project said must not exist, in the model and in the code alike.
elements <<'MD'
# Elements

### E-010 — The engine

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010, FR-CORE-040]
depends_on: [E-020]
```

Reads the store.

### E-020 — The store

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020, FR-CORE-060, FR-CORE-070]
depends_on: []
```

Keeps it.
MD
printf 'import b\n' > "$LAB/src/a.py"
printf '{"rules": {}, "forbidden": [{"from": "E-010", "to": "E-020", "why": "the engine must not reach the store"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-470 a declared edge the project forbids" 0 \
    "E-010 depends on E-020 and the project forbids it (the model declares it): the engine must not reach the store"
rule "FR-ARCH-470 and the same edge in the code" 0 \
    "E-010 depends on E-020 and the project forbids it (src/a.py imports b): the engine must not reach the store"

# --- The wildcard says the common intents: nothing leans on this part.
printf '{"rules": {}, "forbidden": [{"from": "*", "to": "E-020", "why": "nothing leans on the store"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-470 the wildcard on the receiving side" 0 \
    "E-010 depends on E-020 and the project forbids it (the model declares it): nothing leans on the store"

# --- An edge nobody forbade is not reported, which is the half that fails
# --- quietly if the matching is wrong.
printf '{"rules": {}, "forbidden": [{"from": "E-020", "to": "E-010", "why": "the store must not reach the engine"}]}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-470 an edge the other way round is not forbidden" 0 "the project forbids it"

# --- A prohibition about a part nobody has is an error: it reads as enforced
# --- and enforces nothing.
printf '{"rules": {}, "forbidden": [{"from": "E-990", "to": "E-020", "why": "nope"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-480 a prohibition naming no part" 1 \
    "forbidden entry 0 names E-990 in \`from\`, which no element carries"

# --- Refused before anything is read: the setup, not a finding.
printf '{"rules": {}, "forbidden": [{"from": "*", "to": "*", "why": "nothing at all"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-480 the wildcard on both sides" 2 \
    "forbids every dependency, which is a typo for one side or the other"
printf '{"rules": {}, "forbidden": [{"from": "E-010", "why": "half an entry"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-480 an entry missing a side" 2 "forbidden entry 0: \`to\` must be text"
printf '{"rules": {}, "forbidden": [{"from": "E-010", "to": "E-020"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-480 an entry with no reason" 2 "forbidden entry 0: \`why\` must be text"
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"
printf 'x\n' > "$LAB/src/a.py"

# srs-end: FR-ARCH-470, FR-ARCH-480, IF-ARCH-060

# --- verifies: FR-ARCH-490 — a part entered by a name its interface does not
# --- state: every dependency rule can be satisfied while the field says
# --- something else entirely.
printf 'import b\n' > "$LAB/src/a.py"
elements <<'MD'
# Elements

### E-010 — The engine

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010, FR-CORE-040]
depends_on: [E-020]
```

Reads the store.

### E-020 — The store

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020, FR-CORE-060, FR-CORE-070]
depends_on: []
interface: a command, and nothing importable
```

Keeps it.
MD
rule "FR-ARCH-490 a module the interface does not state" 0 \
    "src/a.py reaches E-020 by \`b\`, which its interface does not state"

# --- Named, and the finding goes: the boundary is what the other side writes.
elements <<'MD'
# Elements

### E-010 — The engine

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010, FR-CORE-040]
depends_on: [E-020]
```

Reads the store.

### E-020 — The store

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020, FR-CORE-060, FR-CORE-070]
depends_on: []
interface: the module `b`, imported by whoever reads the store
```

Keeps it.
MD
silent "FR-ARCH-490 a module the interface states" 0 "which its interface does not state"

# --- A part with no interface is FR-ARCH-450's silence, not this rule's: said
# --- twice, a project prices both away.
elements <<'MD'
# Elements

### E-010 — The engine

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010, FR-CORE-040]
depends_on: [E-020]
```

Reads the store.

### E-020 — The store

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020, FR-CORE-060, FR-CORE-070]
depends_on: []
```

Keeps it.
MD
silent "FR-ARCH-490 a part with no interface is not this rule's finding" 0 "its interface does not state"
printf 'x\n' > "$LAB/src/a.py"

# srs-end: FR-ARCH-490

# --- verifies: FR-ARCH-500 — what a part was cut to keep, as a subset of what
# --- it carries: empty is ordinary, a name the specification lacks is an error,
# --- and a name the part does not carry is a claim about another boundary.
elements <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-040, FR-CORE-060, FR-CORE-070]
protects: [FR-CORE-990]
depends_on: []
```

Carries all of it.
MD
rule "FR-ARCH-500 protecting what the specification does not carry" 1 \
    "E-010 protects FR-CORE-990, which the specification does not carry"

elements <<'MD'
# Elements

### E-010 — Half of it

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010, FR-CORE-040]
protects: [FR-CORE-020]
depends_on: []
```

Carries one file.

### E-020 — The other half

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020, FR-CORE-060, FR-CORE-070]
protects: [FR-CORE-020]
depends_on: []
```

Carries the other.
MD
rule "FR-ARCH-500 protecting what it does not carry" 0 \
    "E-010 protects FR-CORE-020 and does not carry it"
silent "FR-ARCH-500 and the part that does carry it is not reported" 0 \
    "E-020 protects FR-CORE-020 and does not carry it"

elements <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-040, FR-CORE-060, FR-CORE-070]
depends_on: []
```

Carries all of it, and protects nothing in particular.
MD
silent "FR-ARCH-500 naming none is ordinary and silent" 0 "protects"

# srs-end: FR-ARCH-500

# --- verifies: FR-ARCH-560 — a part standing on ground the register has lost.
# --- The register is a layer of its own, so the lab grows one: its tool, a
# --- hypothesis whose state the fixture moves, and a bet naming a requirement.
cp srs-dd/tools/srs_grounds.py "$LAB/srs-dd/tools/"
mkdir -p "$LAB/grounds"
printf '{\n  "rules": {}\n}\n' > "$LAB/grounds/grounds-config.json"

# ground <status> — the register under test: one hypothesis in that state and a
# bet resting FR-CORE-010 on it.
ground() {
    cat > "$LAB/grounds/10-h-test.md" <<MD
# Grounds under test

### H-010 — The claim under the first requirement

\`\`\`yaml
status: $1
class: III
population: studios of five to fifty people
refuted_if: proportion < 0.25 at n >= 200
expires: 2099-01-01
owner: @someone
impact: a third of the plan
\`\`\`

Studios of five to fifty people export weekly.

### B-010 — The first requirement rests on it

\`\`\`yaml
status: ${2:-active}
requirement: FR-CORE-010
all_of: [H-010]
\`\`\`

Worth building only if the claim holds.
MD
}

elements <<'MD'
# Elements

### E-010 — The first part

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: []
interface: one call, first()
```

Carries the first.

### E-020 — The second part

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020]
depends_on: []
interface: one call, second()
```

Carries the second.
MD

ground refuted
rule "FR-ARCH-560 a part on refuted ground is reported" 0 "E-010 carries FR-CORE-010, which rests on H-010 (refuted)"
rule "FR-ARCH-560 and it fails a strict run" 1 "rests on H-010 (refuted)" --strict
silent "FR-ARCH-560 and the part standing on nothing is not" 0 "E-020 carries"

ground expired
rule "FR-ARCH-560 expired ground counts too" 0 "rests on H-010 (expired)"

ground assumed
silent "FR-ARCH-560 assumed ground is the ordinary state and silent" 0 "rests on H-010"

ground supported
silent "FR-ARCH-560 supported ground is silent" 0 "rests on H-010"

# A retired bet is a bet that was: the ground it named is past.
ground refuted retired
silent "FR-ARCH-560 a retired bet names no ground" 0 "rests on H-010"

# Priced off like every other reading of this layer.
ground refuted
printf '{\n  "rules": {"element-ungrounded": "off"}\n}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-560 the project can price it off" 0 "rests on H-010"
printf '{\n  "rules": {}\n}\n' > "$LAB/arch/arch-config.json"

# Without a register there is no question: the rule cannot fire at all.
rm -rf "$LAB/grounds"
silent "FR-ARCH-560 no register, no finding" 0 "rests on H-010"

# srs-end: FR-ARCH-560

# --- verifies: FR-ARCH-540 — the draft cut: a lab of its own, because this one
# --- asks what an empty layer over a codebase looks like.
DRAFT=/tmp/srs-arch-draft
rm -rf "$DRAFT"
mkdir -p "$DRAFT/srs-dd/tools" "$DRAFT/specs" "$DRAFT/arch" "$DRAFT/src/engine" "$DRAFT/src/store"
cp srs-dd/tools/srs_arch.py srs-dd/tools/srs_parse.py srs-dd/tools/srs_check.py \
   srs-dd/tools/srs_view.py srs-dd/tools/srs_view_model.py "$DRAFT/srs-dd/tools/"
cp "$LAB/specs/srs-config.json" "$DRAFT/specs/"
printf 'x\n' > "$DRAFT/src/engine/run.py"
printf 'x\n' > "$DRAFT/src/engine/parse.py"
printf 'x\n' > "$DRAFT/src/store/keep.py"
printf '{\n  "rules": {}\n}\n' > "$DRAFT/arch/arch-config.json"
printf '# Elements\n\nNothing is written down yet.\n' > "$DRAFT/arch/00-elements.md"
cat > "$DRAFT/specs/10-fr-core.md" <<'MD'
# Functional requirements — core

### FR-CORE-010 — The engine answers

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [src/engine/run.py, src/engine/parse.py]
tests: []
created: 2026-10-06
```

The system **shall** answer.

### FR-CORE-020 — The store keeps

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [src/store/keep.py]
tests: []
created: 2026-10-06
```

The system **shall** keep.
MD

draft() { ( cd "$DRAFT" && python3 srs-dd/tools/srs_arch.py --draft ) > /tmp/srs-arch-draft.out 2>&1; }
before=$(cat "$DRAFT/arch/00-elements.md")
draft
python3 - <<'PYDRAFT'
import re, sys
text = open("/tmp/srs-arch-draft.out", encoding="utf-8").read()
if "2 directories holding files no part carries" not in text:
    sys.exit("FAIL FR-ARCH-540 — the draft does not say how many directories it grouped:\n" + text[:300])
records = re.findall(r"^### (E-\d{3}) — <what (\S+) is responsible for>$", text, re.M)
if records != [("E-010", "src/engine"), ("E-020", "src/store")]:
    sys.exit("FAIL FR-ARCH-540 — the draft's records are %s" % records)
if "carries: [src/engine/parse.py, src/engine/run.py]" not in text:
    sys.exit("FAIL FR-ARCH-540 — a group does not name the files it holds")
if "requirements: [FR-CORE-010]" not in text or "requirements: [FR-CORE-020]" not in text:
    sys.exit("FAIL FR-ARCH-540 — a group does not name the requirements that name its files")
PYDRAFT
passes=$((passes + 4))

# Nothing written: the layer's own file is the one the fixture left there.
[ "$before" = "$(cat "$DRAFT/arch/00-elements.md")" ] \
    || { echo "FAIL FR-ARCH-540 — --draft wrote into arch/00-elements.md"; exit 1; }
passes=$((passes + 1))

# The round trip: filled in and pasted, the draft is a layer its own checker accepts.
( cd "$DRAFT" && python3 srs-dd/tools/srs_arch.py --draft | sed -n '3,$p' \
    | sed 's/<what \(.*\) is responsible for>/The \1 part/; s/<how this part is reached from outside>/one call/; s/<One sentence.*>/It answers for what it carries./' \
    > /tmp/srs-arch-draft.records )
{ printf '# Elements\n\n'; cat /tmp/srs-arch-draft.records; } > "$DRAFT/arch/00-elements.md"
rc=0
( cd "$DRAFT" && python3 srs-dd/tools/srs_arch.py --no-write --strict ) > /tmp/srs-arch-draft.log 2>&1 || rc=$?
if [ "$rc" != "0" ]; then
    echo "FAIL FR-ARCH-540 — the filled-in draft does not pass its own checker"; cat /tmp/srs-arch-draft.log; exit 1
fi
passes=$((passes + 1))

# And once every file is carried, there is nothing to draft and it says so.
draft
grep -qF "there is nothing to draft" /tmp/srs-arch-draft.out \
    || { echo "FAIL FR-ARCH-540 — a layer that carries everything still drafts"; cat /tmp/srs-arch-draft.out; exit 1; }
passes=$((passes + 1))

# The next number continues the layer's own: E-010 taken, the draft starts at E-020.
printf '# Elements\n\n### E-010 — The engine\n\n```yaml\nstatus: built\ncarries: [src/engine]\nrequirements: [FR-CORE-010]\ndepends_on: []\ninterface: one call\n```\n\nCarries the engine.\n' \
    > "$DRAFT/arch/00-elements.md"
draft
grep -qF "### E-020 — <what src/store is responsible for>" /tmp/srs-arch-draft.out \
    || { echo "FAIL FR-ARCH-540 — the draft does not continue the layer's own numbering"; cat /tmp/srs-arch-draft.out; exit 1; }
passes=$((passes + 1))

# srs-end: FR-ARCH-540

# --- verifies: FR-ARCH-570, FR-ARCH-580 — what a cut costs, and the cut the
# --- links suggest. Three requirements and two parts, so every number here is
# --- one a reader can count by hand: 020 depends on 010 inside the first part,
# --- 030 depends on 010 across the boundary.
PRICE=/tmp/srs-arch-price
rm -rf "$PRICE"
mkdir -p "$PRICE/srs-dd/tools" "$PRICE/specs" "$PRICE/arch" "$PRICE/src"
cp srs-dd/tools/srs_arch.py srs-dd/tools/srs_parse.py srs-dd/tools/srs_check.py \
   srs-dd/tools/srs_view.py srs-dd/tools/srs_view_model.py "$PRICE/srs-dd/tools/"
cp "$LAB/specs/srs-config.json" "$PRICE/specs/"
printf 'x\n' > "$PRICE/src/a.py"
printf 'x\n' > "$PRICE/src/b.py"
printf 'x\n' > "$PRICE/src/c.py"
printf '{\n  "rules": {}\n}\n' > "$PRICE/arch/arch-config.json"
cat > "$PRICE/specs/10-fr-core.md" <<'MD'
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
created: 2026-10-06
```

The system **shall** act first.

### FR-CORE-020 — The second

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CORE-010]
refines: []
conflicts_with: []
code: [src/b.py]
tests: []
created: 2026-10-06
```

The system **shall** act second.

### FR-CORE-030 — The third

```yaml
status: implemented
verification: T
derives_from: []
depends_on: [FR-CORE-010]
refines: []
conflicts_with: []
code: [src/c.py]
tests: []
created: 2026-10-06
```

The system **shall** act third.
MD
cat > "$PRICE/arch/00-elements.md" <<'MD'
# Elements

### E-010 — The first part

```yaml
status: built
carries: [src/a.py, src/b.py]
requirements: [FR-CORE-010, FR-CORE-020]
depends_on: []
interface: one call, first()
```

Carries the first two.

### E-020 — The second part

```yaml
status: built
carries: [src/c.py]
requirements: [FR-CORE-030]
depends_on: []
interface: one call, third()
```

Carries the third.
MD

priced() { ( cd "$PRICE" && python3 srs-dd/tools/srs_arch.py --price "$1" ) > /tmp/srs-arch-price.out 2>&1; }

priced parts
python3 - <<'PYPRICE'
import re, sys
text = open("/tmp/srs-arch-price.out", encoding="utf-8").read()
if "3 of 3 requirements covered" not in text:
    sys.exit("FAIL FR-ARCH-570 — the coverage line is wrong:\n" + text)
rows = dict((m.group(1), tuple(int(v) for v in m.groups()[1:])) for m in
            re.finditer(r"^(E-\d{3})\s+(\d+) held · \s*(\d+) inside · \s*(\d+) out · \s*(\d+) in",
                        text, re.M))
# E-010 holds 010 and 020: the link between them is inside, and 030's link arrives.
if rows.get("E-010") != (2, 1, 0, 1):
    sys.exit("FAIL FR-ARCH-570 — E-010 priced %s, expected (2, 1, 0, 1)" % (rows.get("E-010"),))
# E-020 holds 030 alone: nothing inside, one link leaving.
if rows.get("E-020") != (1, 0, 1, 0):
    sys.exit("FAIL FR-ARCH-570 — E-020 priced %s, expected (1, 0, 1, 0)" % (rows.get("E-020"),))
PYPRICE
passes=$((passes + 3))

priced areas
grep -qF "The areas the specification declares — 1 group(s), 3 of 3 requirements covered." /tmp/srs-arch-price.out \
    || { echo "FAIL FR-ARCH-570 — the areas cut is not priced"; cat /tmp/srs-arch-price.out; exit 1; }
grep -qE "^CORE +3 held · +2 inside · +0 out · +0 in" /tmp/srs-arch-price.out \
    || { echo "FAIL FR-ARCH-570 — the one area's price is wrong"; cat /tmp/srs-arch-price.out; exit 1; }
passes=$((passes + 2))

# A part that carries nothing of the specification is still a group, and what no
# group holds is said: the second part is emptied and its requirement left over.
cat > "$PRICE/arch/00-elements.md" <<'MD'
# Elements

### E-010 — The first part

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010]
depends_on: []
interface: one call, first()
```

Carries the first.
MD
priced parts
grep -qF "2 requirement(s) in no group: FR-CORE-020, FR-CORE-030" /tmp/srs-arch-price.out \
    || { echo "FAIL FR-ARCH-570 — what the cut leaves out is not named"; cat /tmp/srs-arch-price.out; exit 1; }
passes=$((passes + 1))

# --- The proposal needs a specification larger than the handful of seeds it
# --- starts from, or every requirement is a seed and the grouping is untested.
# --- Twenty requirements: the first is the only one anything links to, ten are
# --- seeds by the ranking's tie-break, and the other ten hang off the first.
python3 - <<'PYBIG'
lines = ["# Functional requirements — core", ""]
for index in range(20):
    number = (index + 1) * 10
    depends = "[FR-CORE-010]" if index >= 10 else "[]"
    lines += ["### FR-CORE-%03d — Requirement %d" % (number, number), "", "```yaml",
              "status: implemented", "verification: T", "derives_from: []",
              "depends_on: %s" % depends, "refines: []", "conflicts_with: []",
              "code: []", "tests: []", "created: 2026-10-06", "```", "",
              "The system **shall** act %d." % number, ""]
open("/tmp/srs-arch-price/specs/10-fr-core.md", "w", encoding="utf-8").write("\n".join(lines))
PYBIG
priced proposed
python3 - <<'PYPROP'
import re, sys
text = open("/tmp/srs-arch-price.out", encoding="utf-8").read()
if "seeded by the drivers: FR-CORE-010" not in text:
    sys.exit("FAIL FR-ARCH-580 — the proposal does not name its seeds:\n" + text)
if "10 group(s), 20 of 20 requirements covered" not in text:
    sys.exit("FAIL FR-ARCH-580 — the proposal is not ten groups over twenty requirements:\n"
             + text)
rows = dict((m.group(1), int(m.group(2))) for m in
            re.finditer(r"^(FR-CORE-\d{3})\s+(\d+) held", text, re.M))
# Everything that links to the first requirement joins its group: it and the ten.
if rows.get("FR-CORE-010") != 11:
    sys.exit("FAIL FR-ARCH-580 — the first group holds %s, expected 11 — the links did not "
             "draw the grouping" % rows.get("FR-CORE-010"))
if sum(rows.values()) != 20:
    sys.exit("FAIL FR-ARCH-580 — the groups hold %d places for 20 requirements, so they share "
             "some" % sum(rows.values()))
PYPROP
cp /tmp/srs-arch-price.out /tmp/srs-arch-price.first
priced proposed
cmp -s /tmp/srs-arch-price.first /tmp/srs-arch-price.out \
    || { echo "FAIL FR-ARCH-580 — two runs of --price proposed differ"; exit 1; }
passes=$((passes + 3))

# Neither writes anything, and a cut nobody named is refused.
before=$(cat "$PRICE/arch/00-elements.md")
priced parts
[ "$before" = "$(cat "$PRICE/arch/00-elements.md")" ] \
    || { echo "FAIL FR-ARCH-570 — --price wrote into the layer"; exit 1; }
rc=0
( cd "$PRICE" && python3 srs-dd/tools/srs_arch.py --price ) >/tmp/srs-arch-price.out 2>&1 || rc=$?
[ "$rc" = "2" ] || { echo "FAIL FR-ARCH-570 — --price with no cut named exited $rc, expected 2"; exit 1; }
rc=0
( cd "$PRICE" && python3 srs-dd/tools/srs_arch.py --price nope ) >/dev/null 2>&1 || rc=$?
[ "$rc" = "2" ] || { echo "FAIL FR-ARCH-570 — --price nope exited $rc, expected 2"; exit 1; }
passes=$((passes + 3))

# srs-end: FR-ARCH-570, FR-ARCH-580

# --- verifies: IF-ARCH-070, FR-ARCH-590, FR-ARCH-600 — the order of the cut:
# --- an edge that runs upward, in the model, in the imports and in the edges
# --- the project supplies, and the orders that are refused instead.
elements <<'MD'
# Elements

### E-010 — The engine

```yaml
status: built
carries: [src/a.py]
requirements: [FR-CORE-010, FR-CORE-040]
depends_on: [E-020]
```

Reads the store.

### E-020 — The store

```yaml
status: built
carries: [src/b.py]
requirements: [FR-CORE-020, FR-CORE-060, FR-CORE-070]
depends_on: []
```

Keeps it.
MD
printf 'x\n' > "$LAB/src/a.py"
printf '{"rules": {}, "layers": [["E-020"], ["E-010"]]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-590 a declared edge against the order" 0 \
    "E-010 in group 1 depends on E-020 in group 0, which the order puts above it (the model declares it)"

printf 'import b\n' > "$LAB/src/a.py"
rule "FR-ARCH-590 and the same edge in the code" 0 \
    "E-010 in group 1 depends on E-020 in group 0, which the order puts above it (src/a.py imports b)"

# --- The third supplier: an edge the project computed itself.
printf 'x\n' > "$LAB/src/a.py"
printf '[{"from": "src/a.py", "to": "src/b.py", "via": "Store:3"}]\n' > "$LAB/arch/edges.json"
rule "FR-ARCH-590 and an edge the project supplied" 0 \
    "E-010 in group 1 depends on E-020 in group 0, which the order puts above it (src/a.py uses src/b.py)"
rm -f "$LAB/arch/edges.json"

# --- Downward is what the order allows, and this is the half that fails
# --- quietly if the comparison is the wrong way round.
printf '{"rules": {}, "layers": [["E-010"], ["E-020"]]}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-590 a dependency running downward" 0 "which the order puts above it"

# --- A group is the level: parts inside it may lean on each other.
printf '{"rules": {}, "layers": [["E-010", "E-020"]]}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-590 two parts in one group" 0 "which the order puts above it"

# --- A part the order does not place is outside it.
printf '{"rules": {}, "layers": [["E-020"]]}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-590 a part in no group" 0 "which the order puts above it"

# --- Priced, like every rule of this checker.
printf '{"rules": {"dependency-upward": "report"}, "layers": [["E-020"], ["E-010"]]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-590 lowered to a note" 0 "note: "
silent "FR-ARCH-590 a note does not fail a strict run" 0 "treated as errors" --strict
printf '{"rules": {}, "layers": [["E-020"], ["E-010"]]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-590 at its default cost it fails a strict run" 1 "treated as errors" --strict
printf '{"rules": {"dependency-upward": "off"}, "layers": [["E-020"], ["E-010"]]}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-590 switched off says nothing" 0 "which the order puts above it"

# --- An order about a part nobody has reads as enforced and enforces nothing.
printf '{"rules": {}, "layers": [["E-990"], ["E-010"]]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-600 an order naming no part" 1 \
    "layers group 0 names E-990, which no element carries"

# --- Refused before anything is read: the setup, not a finding.
printf '{"rules": {}, "layers": ["E-010"]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-600 an order that is not a list of groups" 2 "\`layers\` must be a JSON list of groups"
printf '{"rules": {}, "layers": [["nope"]]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-600 a group holding something else" 2 "layers group 0 holds 'nope', expected an element identifier"
printf '{"rules": {}, "layers": [["E-010"], ["E-010"]]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-600 a part in two groups" 2 \
    "E-010 is in groups 0 and 1, so the order does not say where it stands"

printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"
printf 'x\n' > "$LAB/src/a.py"

# srs-end: IF-ARCH-070, FR-ARCH-590, FR-ARCH-600

# --- verifies: IF-ARCH-080, FR-ARCH-610, FR-ARCH-620 — a module a part may
# --- not import: the far end is outside the system, so no element names it.
printf 'import json\n' > "$LAB/src/a.py"
printf '{"rules": {}, "forbidden_imports": [{"in": "E-010", "module": "json", "why": "the engine never serialises"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-610 a module the part may not import" 0 \
    "src/a.py imports json, which E-010 may not: the engine never serialises"

# --- A module nobody forbade, and a prohibition about another part, are both
# --- silent — the halves that fail quietly if the matching is wrong.
printf '{"rules": {}, "forbidden_imports": [{"in": "E-010", "module": "subprocess", "why": "no shelling out"}]}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-610 a module the part does not import" 0 "which E-010 may not"
printf '{"rules": {}, "forbidden_imports": [{"in": "E-020", "module": "json", "why": "the store never serialises"}]}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-610 a prohibition about another part" 0 "imports json"

# --- Priced, like every rule of this checker.
printf '{"rules": {"import-forbidden": "report"}, "forbidden_imports": [{"in": "E-010", "module": "json", "why": "no serialising"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-610 lowered to a note" 0 "note: "
printf '{"rules": {}, "forbidden_imports": [{"in": "E-010", "module": "json", "why": "no serialising"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-610 at its default cost it fails a strict run" 1 "treated as errors" --strict
printf '{"rules": {"import-forbidden": "off"}, "forbidden_imports": [{"in": "E-010", "module": "json", "why": "no serialising"}]}\n' > "$LAB/arch/arch-config.json"
silent "FR-ARCH-610 switched off says nothing" 0 "which E-010 may not"

# --- An entry about a part nobody has reads as enforced and enforces nothing.
printf '{"rules": {}, "forbidden_imports": [{"in": "E-990", "module": "json", "why": "nope"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-620 an entry naming no part" 1 \
    "forbidden_imports entry 0 names E-990 in \`in\`, which no element carries"

# --- Refused before anything is read: the setup, not a finding.
printf '{"rules": {}, "forbidden_imports": {"in": "E-010"}}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-620 a list that is not a list" 2 "\`forbidden_imports\` must be a JSON list"
printf '{"rules": {}, "forbidden_imports": [{"in": "E-010", "module": "json"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-620 an entry with no reason" 2 "forbidden_imports entry 0: \`why\` must be text"
printf '{"rules": {}, "forbidden_imports": [{"in": "E-010", "why": "half an entry"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-620 an entry with no module" 2 "forbidden_imports entry 0: \`module\` must be text"
printf '{"rules": {}, "forbidden_imports": [{"in": "src/a.py", "module": "json", "why": "a file, not a part"}]}\n' > "$LAB/arch/arch-config.json"
rule "FR-ARCH-620 an end that is not an element" 2 "forbidden_imports entry 0: \`in\` is 'src/a.py', expected an element identifier"

printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"
printf 'x\n' > "$LAB/src/a.py"

# srs-end: IF-ARCH-080, FR-ARCH-610, FR-ARCH-620

echo "arch-rules: $passes fixtures pass"
# srs-end: FR-ARCH-280
