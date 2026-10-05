#!/usr/bin/env bash
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# The architecture document: a projection of the layer for a person to read.
# One fixture per section, each asserting both states — what the section says
# when there is something to say and what it says when there is not — because a
# generated document reads as complete either way.
#
# file verifies: FR-ARCH-410, FR-ARCH-420, FR-ARCH-430, FR-ARCH-440, FR-ARCH-450
# file verifies: FR-ARCH-460
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

LAB=/tmp/srs-arch-doc
rm -rf "$LAB"
mkdir -p "$LAB/srs-dd/tools" "$LAB/specs" "$LAB/arch" "$LAB/src"
cp srs-dd/tools/srs_arch_doc.py srs-dd/tools/srs_arch.py srs-dd/tools/srs_parse.py \
   srs-dd/tools/srs_check.py srs-dd/tools/srs_view.py "$LAB/srs-dd/tools/"

cat > "$LAB/specs/srs-config.json" <<'JSON'
{
  "areas": ["CORE"],
  "code_roots": ["src"],
  "test_roots": ["t"],
  "code_extensions": [".py"]
}
JSON

cat > "$LAB/specs/10-fr-core.md" <<'MD'
# Functional requirements — core

### FR-CORE-010 — The engine answers

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: [src/engine.py]
tests: []
created: 2026-10-05
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
code: [src/store.py]
tests: []
created: 2026-10-05
```

The system **shall** keep.

### FR-CORE-030 — Approved and unbuilt

```yaml
status: deferred
verification: T
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
created: 2026-10-05
```

The system **shall** act later.
MD

# The engine imports the store, which is the edge the model may or may not declare.
printf 'import store\n\n\ndef run():\n    return store.read()\n' > "$LAB/src/engine.py"
printf 'def read():\n    return 1\n' > "$LAB/src/store.py"
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"

# elements <<'MD' — the layer under test, replaced by every fixture.
elements() { cat > "$LAB/arch/00-elements.md"; }
moves() { cat > "$LAB/arch/10-moves.md"; }
doc() { ( cd "$LAB" && python3 srs-dd/tools/srs_arch_doc.py ) > /tmp/srs-arch-doc.out 2>/tmp/srs-arch-doc.err; }

passes=0

# says <name> <fragment that must appear>
# `--` because every fragment here is a list item and starts with `-`, which a
# grep that is ugrep would otherwise read as an option.
says() {
    if ! grep -qF -- "$2" /tmp/srs-arch-doc.out; then
        echo "FAIL $1 — the document does not say: $2"; cat /tmp/srs-arch-doc.out; exit 1
    fi
    passes=$((passes + 1))
}

# silent <name> <fragment that must not appear>
silent() {
    if grep -qF -- "$2" /tmp/srs-arch-doc.out; then
        echo "FAIL $1 — the document says what it should not: $2"; cat /tmp/srs-arch-doc.out; exit 1
    fi
    passes=$((passes + 1))
}

# --- A layer of two parts, one declaring an interface and one not, with the
# --- import declared, so every section has something to say.
elements <<'MD'
# Elements

### E-010 — The engine

```yaml
status: built
carries: [src/engine.py]
requirements: [FR-CORE-010]
depends_on: [E-020]
interface: one call, run()
```

Answers a question by reading the store.

**Rationale.** Split from the store because the two are used at different moments.

### E-020 — The store

```yaml
status: built
carries: [src/store.py]
requirements: [FR-CORE-020]
depends_on: []
```

Keeps what the engine reads.
MD
moves <<'MD'
# Moves

### M-010 — The reader leaves the engine

```yaml
status: moving
from: [E-010]
to: [E-020]
moves: [src/engine.py]
adr: ADR-0001
```

Hands the reader over.
MD
mkdir -p "$LAB/specs/adr"
printf '# ADR-0001 — The cut changes\n\n- **Status:** accepted\n' > "$LAB/specs/adr/ADR-0001-cut.md"
doc

# --- verifies: FR-ARCH-410 — printed, and nothing written.
says "FR-ARCH-410 the document is printed" "# Architecture"
if [ -n "$(find "$LAB" -newer "$LAB/specs/srs-config.json" -name '*.md' -not -path '*/specs/*' -not -path '*/arch/*' 2>/dev/null)" ]; then
    echo "FAIL FR-ARCH-410 — the command wrote a file; the document goes to stdout"; exit 1
fi
passes=$((passes + 1))

# srs-end: FR-ARCH-410
# --- verifies: FR-ARCH-420 — what the system is made of.
says "FR-ARCH-420 the part and its title" "### E-010 — The engine"
says "FR-ARCH-420 what it is responsible for" "Answers a question by reading the store."
silent "FR-ARCH-420 and not its rationale" "Split from the store because"
says "FR-ARCH-420 its status" '- **Status:** `built`'
says "FR-ARCH-420 what it carries" '- **Carries:** `src/engine.py`'
says "FR-ARCH-420 the interface where one is declared" "- **Interface:** one call, run()"
says "FR-ARCH-420 the obligation with its title" "  - FR-CORE-010 — The engine answers"
says "FR-ARCH-420 the move over it" "- **Moving:** M-010 — The reader leaves the engine (\`moving\`)"

# srs-end: FR-ARCH-420
# --- verifies: FR-ARCH-430 — the drawing, as text the reader renders.
says "FR-ARCH-430 a mermaid block" '```mermaid'
says "FR-ARCH-430 a node per part" 'E_010["E-010 The engine"]'
says "FR-ARCH-430 an edge per declared dependency" "    E_010 --> E_020"
says "FR-ARCH-430 the count beside it" "2 part(s), 1 declared dependency(ies)."

# srs-end: FR-ARCH-430
# --- verifies: FR-ARCH-440 — the code agrees here, and the document says so.
says "FR-ARCH-440 agreement is said, not left silent" "Nothing: every dependency the checker can read is declared."

# --- The same layer with the edge undeclared: the disagreement is named with
# --- the file the checker read it from.
elements <<'MD'
# Elements

### E-010 — The engine

```yaml
status: built
carries: [src/engine.py]
requirements: [FR-CORE-010]
depends_on: []
interface: one call, run()
```

Answers a question by reading the store.

### E-020 — The store

```yaml
status: built
carries: [src/store.py]
requirements: [FR-CORE-020]
depends_on: []
```

Keeps what the engine reads.
MD
doc
says "FR-ARCH-440 the undeclared dependency, with its file" "- src/engine.py — imports store, carried by E-020, and E-010 does not declare it"
silent "FR-ARCH-440 and not the clean sentence" "Nothing: every dependency"

# srs-end: FR-ARCH-440
# --- verifies: FR-ARCH-450 — the three silences, named rather than left empty.
says "FR-ARCH-450 a part with no interface" "- **Parts that declare no interface:** E-020"
says "FR-ARCH-450 an approved requirement nobody answers for" "- **Approved requirements no part answers for:** FR-CORE-030"

# --- A layer that answers for everything and carries every file: each silence
# --- says so rather than printing an empty line.
elements <<'MD'
# Elements

### E-010 — Everything

```yaml
status: built
carries: [src]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-030]
depends_on: []
interface: one call, run()
```

Carries the whole of it.
MD
rm -f "$LAB/arch/10-moves.md"
doc
says "FR-ARCH-450 no part without an interface is said" "- **Parts that declare no interface:** _none_"
says "FR-ARCH-450 nothing unanswered is said" "- **Approved requirements no part answers for:** _none_"
says "FR-ARCH-450 no unowned file is said" "- **Files of a realized requirement no part carries:** _none_"

# --- A file of a realized requirement that no part carries is named.
elements <<'MD'
# Elements

### E-010 — Half of it

```yaml
status: built
carries: [src/engine.py]
requirements: [FR-CORE-010, FR-CORE-020, FR-CORE-030]
depends_on: []
```

Carries one file.
MD
doc
says "FR-ARCH-450 the file no part carries" "- **Files of a realized requirement no part carries:** \`src/store.py\`"

# srs-end: FR-ARCH-450
# --- Without the layer at all the command says so and stops; the exit code is
# --- the setup fault the checkers publish, not a finding.
rm -rf "$LAB/arch"
rc=0
( cd "$LAB" && python3 srs-dd/tools/srs_arch_doc.py ) >/dev/null 2>/tmp/srs-arch-doc.err || rc=$?
if [ "$rc" != "2" ]; then
    echo "FAIL FR-ARCH-410 — no arch/ and the exit code is $rc, expected 2"; exit 1
fi
grep -qF -- "arch/ directory not found" /tmp/srs-arch-doc.err \
    || { echo "FAIL FR-ARCH-410 — it does not say the layer is absent"; cat /tmp/srs-arch-doc.err; exit 1; }
passes=$((passes + 1))

# --- verifies: FR-ARCH-460 — the empty layer, which is the first document
# --- every fresh install prints: said, not left blank.
mkdir -p "$LAB/arch"
printf '{"rules": {}}\n' > "$LAB/arch/arch-config.json"
elements <<'MD'
# Elements

The parts this project is made of.
MD
doc
says "FR-ARCH-460 no part is written down" "_No part is written down yet: the layer is installed and empty._"
says "FR-ARCH-460 nothing to draw" "_Nothing to draw: no part is written down yet._"
silent "FR-ARCH-460 and no empty diagram" "flowchart TD"
says "FR-ARCH-460 nothing to compare" "_Nothing to compare: no part is written down yet._"
silent "FR-ARCH-460 and no verdict where there was nothing to read" "every dependency the checker can read is declared"

# srs-end: FR-ARCH-460

echo "arch-doc: $passes fixtures pass"
