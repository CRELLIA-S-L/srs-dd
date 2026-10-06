#!/usr/bin/env bash
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# The architecture document: a projection of the layer for a person to read.
# One fixture per section, each asserting both states — what the section says
# when there is something to say and what it says when there is not — because a
# generated document reads as complete either way.
#
# file verifies: FR-ARCH-410, FR-ARCH-420, FR-ARCH-430, FR-ARCH-440, FR-ARCH-450
# file verifies: FR-ARCH-460, FR-ARCH-510, FR-ARCH-520, FR-ARCH-530
# file verifies: INV-SPEC-130, FR-ARCH-550
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

LAB=/tmp/srs-arch-doc
rm -rf "$LAB"
mkdir -p "$LAB/srs-dd/tools" "$LAB/specs" "$LAB/arch" "$LAB/src"
cp srs-dd/tools/srs_arch_doc.py srs-dd/tools/srs_arch.py srs-dd/tools/srs_parse.py \
   srs-dd/tools/srs_check.py srs-dd/tools/srs_view.py srs-dd/tools/srs_view_model.py \
   "$LAB/srs-dd/tools/"

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

# --- verifies: FR-ARCH-510 — the two or three a part was cut to keep, before
# --- the forty it merely carries; absent where the record names none.
elements <<'MD'
# Elements

### E-010 — The engine

```yaml
status: built
carries: [src/engine.py]
requirements: [FR-CORE-010, FR-CORE-030]
protects: [FR-CORE-010]
depends_on: []
interface: one call, run()
```

Answers a question.
MD
doc
says "FR-ARCH-510 what the part protects, with its title" "  - FR-CORE-010 — The engine answers"
says "FR-ARCH-510 under its own heading" "- **Exists to protect:**"

elements <<'MD'
# Elements

### E-020 — The store

```yaml
status: built
carries: [src/store.py]
requirements: [FR-CORE-020]
depends_on: []
interface: one call, read()
```

Keeps what the engine reads.
MD
doc
silent "FR-ARCH-510 absent where the record names none" "Exists to protect"

# srs-end: FR-ARCH-510

# --- verifies: FR-ARCH-520 — the same document as one page: every section a
# --- reader of the markdown gets, nothing fetched, and nothing written.
page() { ( cd "$LAB" && python3 srs-dd/tools/srs_arch_doc.py --html ) > /tmp/srs-arch-page.out 2>/tmp/srs-arch-page.err; }

# shows <name> <fragment that must appear on the page>
shows() {
    if ! grep -qF -- "$2" /tmp/srs-arch-page.out; then
        echo "FAIL $1 — the page does not hold: $2"; head -40 /tmp/srs-arch-page.out; exit 1
    fi
    passes=$((passes + 1))
}

# hides <name> <fragment that must not appear on the page>
hides() {
    if grep -qF -- "$2" /tmp/srs-arch-page.out; then
        echo "FAIL $1 — the page holds what it should not: $2"; exit 1
    fi
    passes=$((passes + 1))
}

elements <<'MD'
# Elements

### E-010 — The engine

```yaml
status: built
carries: [src/engine.py]
requirements: [FR-CORE-010, FR-CORE-030]
protects: [FR-CORE-010]
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
interface: one call, read()
```

Keeps what the engine reads.
MD
before=$(find "$LAB" -newer "$LAB/specs/srs-config.json" | wc -l)
page
doc

# Every heading of the markdown form is a heading of the page: taken from the
# document itself, so a section added later is asked for without naming it here.
python3 - <<'PYHEAD'
import re, sys
markdown = open("/tmp/srs-arch-doc.out", encoding="utf-8").read()
page = open("/tmp/srs-arch-page.out", encoding="utf-8").read()
missing = []
for level, text in re.findall(r"^(#{1,3}) (.+)$", markdown, re.M):
    plain = re.sub(r"[*`_]", "", text)
    if ("<h%d>" % len(level)) not in page or plain.split(" \u2014 ")[0] not in page:
        missing.append(text)
if missing:
    sys.exit("FAIL FR-ARCH-520 — the page is missing heading(s): %s" % missing[:3])
if markdown.count("- **") > page.count("<strong>"):
    sys.exit("FAIL FR-ARCH-520 — the page has fewer bold labels than the markdown")
PYHEAD
passes=$((passes + 2))

shows "FR-ARCH-520 one self-contained page" "<!doctype html>"
shows "FR-ARCH-520 its own stylesheet, inside the file" "<style>"
shows "FR-ARCH-520 a part, as a heading" "<h3>E-010 — The engine</h3>"
shows "FR-ARCH-520 what it carries, as code" "<code>src/engine.py</code>"
shows "FR-ARCH-520 an obligation with its title" "<li>FR-CORE-010 — The engine answers"
# Nothing fetched: no source attribute, no import, no script and no address over
# the network. `xmlns` is a namespace's name rather than a request, so the
# drawing's own may stand.
hides "FR-ARCH-520 no external source" "src="
hides "FR-ARCH-520 no import of a stylesheet" "@import"
hides "FR-ARCH-520 no script at all" "<script"
hides "FR-ARCH-520 nothing addressed over the network" "href=\"http"
hides "FR-ARCH-520 and nothing pulled in by a url()" "url(http"

# Nothing written: both forms go to stdout, as `FR-ARCH-410` asks.
after=$(find "$LAB" -newer "$LAB/specs/srs-config.json" | wc -l)
[ "$before" = "$after" ] || { echo "FAIL FR-ARCH-520 — --html wrote into the project"; exit 1; }
passes=$((passes + 1))

# The tags close in the order they opened: a nested list belongs inside the item
# above it, and a page a browser has to repair is a page a reader scrolls past.
python3 - <<'PYWELL'
from html.parser import HTMLParser
import sys

VOID = {"meta", "br", "hr", "img", "input", "link"}


class Check(HTMLParser):
    def __init__(self):
        HTMLParser.__init__(self, convert_charrefs=True)
        self.stack, self.problems = [], []

    def handle_starttag(self, tag, attrs):
        # A list inside a list belongs inside the item above it: tags that merely
        # balance can still put a <ul> where only an <li> may stand.
        if tag == "ul" and self.stack and self.stack[-1] == "ul":
            self.problems.append("<ul> inside <ul>, not inside an item, line %d"
                                 % self.getpos()[0])
        if tag not in VOID:
            self.stack.append(tag)

    def handle_endtag(self, tag):
        if not self.stack:
            self.problems.append("</%s> with nothing open, line %d" % (tag, self.getpos()[0]))
        elif self.stack[-1] != tag:
            self.problems.append("</%s> closes <%s>, line %d"
                                 % (tag, self.stack[-1], self.getpos()[0]))
            self.stack.pop()
        else:
            self.stack.pop()


check = Check()
check.feed(open("/tmp/srs-arch-page.out", encoding="utf-8").read())
if check.problems or check.stack:
    sys.exit("FAIL FR-ARCH-520 — the page is not well formed: %s %s"
             % (check.problems[:3], check.stack[:3]))
PYWELL
passes=$((passes + 1))

# --- The empty layer, as a page: the sentences of `FR-ARCH-460` arrive as
# --- emphasis rather than as markdown nobody rendered.
elements <<'MD'
# Elements

The parts this project is made of.
MD
page
shows "FR-ARCH-520 the empty layer reads as a sentence" "<em>No part is written down yet: the layer is installed and empty.</em>"
hides "FR-ARCH-520 and no markdown is left raw" "_No part is written down yet"

# --- A stray flag beside --html is refused as any other is.
rc=0
( cd "$LAB" && python3 srs-dd/tools/srs_arch_doc.py --html --nope ) >/dev/null 2>/tmp/srs-arch-page.err || rc=$?
if [ "$rc" != "2" ]; then
    echo "FAIL FR-ARCH-520 — a stray flag beside --html exited $rc, expected 2"; exit 1
fi
if ! grep -qF -- "--html" /tmp/srs-arch-page.err; then
    echo "FAIL FR-ARCH-520 — the usage line does not name --html"; cat /tmp/srs-arch-page.err; exit 1
fi
passes=$((passes + 2))

# srs-end: FR-ARCH-520

# --- verifies: FR-ARCH-530 — the drawing on the page is an image the command
# --- laid out: a node per part in force, an edge per declared dependency.
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

### E-020 — The store

```yaml
status: built
carries: [src/store.py]
requirements: [FR-CORE-020]
depends_on: []
interface: one call, read()
```

Keeps what the engine reads.

### E-030 — The old store

```yaml
status: superseded
carries: []
requirements: []
depends_on: []
```

Replaced by E-020.
MD
page
doc
shows "FR-ARCH-530 the drawing is an image inside the page" "<svg "
hides "FR-ARCH-530 and not a diagram somebody else must draw" "flowchart TD"
says "FR-ARCH-530 while the markdown form still hands over the source" "flowchart TD"
shows "FR-ARCH-530 a node carries the part's title" 'class="node-title">The engine</text>'
hides "FR-ARCH-530 and no node for a part out of force" ">E-030<"

# A box per part, none overlapping, none off the canvas, one edge per declared
# dependency, and the part that depends drawn above what it depends on: a
# drawing nobody can look at here is held to its geometry instead.
python3 - <<'PYSVG'
import re, sys
page = open("/tmp/srs-arch-page.out", encoding="utf-8").read()
svg = page[page.index("<svg"):page.index("</svg>") + 6]
width, height = (int(v) for v in re.search(r'viewBox="0 0 (\d+) (\d+)"', svg).groups())
boxes = [tuple(int(v) for v in box) for box in
         re.findall(r'<rect x="(-?\d+)" y="(-?\d+)" width="(\d+)" height="(\d+)"', svg)]
ids = re.findall(r'class="node-id">([^<]+)<', svg)
edges = len(re.findall(r'class="edge"', svg))
if sorted(ids) != ["E-010", "E-020"]:
    sys.exit("FAIL FR-ARCH-530 — the drawing's nodes are %s" % ids)
if edges != 1:
    sys.exit("FAIL FR-ARCH-530 — %d edge(s) drawn for one declared dependency" % edges)
for first in range(len(boxes)):
    for second in range(first + 1, len(boxes)):
        a, b = boxes[first], boxes[second]
        if a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]:
            sys.exit("FAIL FR-ARCH-530 — two boxes overlap: %s %s" % (a, b))
for box in boxes:
    if box[0] < 0 or box[1] < 0 or box[0] + box[2] > width or box[1] + box[3] > height:
        sys.exit("FAIL FR-ARCH-530 — a box falls outside the canvas: %s in %dx%d"
                 % (box, width, height))
rows = dict(zip(ids, (box[1] for box in boxes)))
if not rows["E-010"] < rows["E-020"]:
    sys.exit("FAIL FR-ARCH-530 — the part that depends is not drawn above what it depends on")
PYSVG
passes=$((passes + 5))

# --- Two runs of the same records draw the same bytes.
cp /tmp/srs-arch-page.out /tmp/srs-arch-page.first
page
if ! cmp -s /tmp/srs-arch-page.first /tmp/srs-arch-page.out; then
    echo "FAIL FR-ARCH-530 — two runs of --html differ"; exit 1
fi
passes=$((passes + 1))

# --- A circle: the checker reports it, and the drawing survives it rather than
# --- looping while it ranks the parts.
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

### E-020 — The store

```yaml
status: built
carries: [src/store.py]
requirements: [FR-CORE-020]
depends_on: [E-010]
interface: one call, read()
```

Keeps what the engine reads.
MD
page
shows "FR-ARCH-530 a circle is still drawn" "<svg "
shows "FR-ARCH-530 with both parts in it" ">E-020<"

# --- The empty layer: no drawing at all, and the sentence in its place.
elements <<'MD'
# Elements

The parts this project is made of.
MD
page
hides "FR-ARCH-530 nothing drawn where there is nothing to draw" "<svg "
shows "FR-ARCH-530 and the sentence stands instead" "<em>Nothing to draw: no part is written down yet.</em>"

# srs-end: FR-ARCH-530

# --- verifies: INV-SPEC-130 — the page links exactly the pages its caller named.
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

Answers a question.
MD
page
hides "INV-SPEC-130 nothing named, nothing linked" "<nav class=\"pages\">"

linked() {
    ( cd "$LAB" && python3 srs-dd/tools/srs_arch_doc.py --html --link "$1" ) \
        > /tmp/srs-arch-page.out 2>/tmp/srs-arch-page.err
}
linked index.html
shows "INV-SPEC-130 one named, one linked" '<a href="index.html">the specification</a>'
hides "INV-SPEC-130 and not the one nobody named" 'href="grounds.html"'

linked grounds.html,index.html
shows "INV-SPEC-130 both named, both linked" '<a href="grounds.html">the grounds dashboard</a>'
python3 - <<'PYORDER'
import re, sys
page = open("/tmp/srs-arch-page.out", encoding="utf-8").read()
strip = re.search(r'<nav class="pages">(.*?)</nav>', page, re.S)
if not strip:
    sys.exit("FAIL INV-SPEC-130 — no strip of links on the page")
order = re.findall(r'href="([^"]+)"', strip.group(1))
if order != ["index.html", "grounds.html"]:
    sys.exit("FAIL INV-SPEC-130 — the links read %s, not the set's own order" % order)
PYORDER
passes=$((passes + 2))

for bad in nope.html arch.html; do
    rc=0
    ( cd "$LAB" && python3 srs-dd/tools/srs_arch_doc.py --html --link "$bad" ) \
        >/tmp/srs-arch-page.out 2>/tmp/srs-arch-page.err || rc=$?
    if [ "$rc" != "2" ]; then
        echo "FAIL INV-SPEC-130 — --link $bad exited $rc, expected 2"; exit 1
    fi
    if [ -s /tmp/srs-arch-page.out ]; then
        echo "FAIL INV-SPEC-130 — --link $bad printed a page anyway"; exit 1
    fi
    if ! grep -qF -- "$bad" /tmp/srs-arch-page.err; then
        echo "FAIL INV-SPEC-130 — the refusal does not name $bad"; cat /tmp/srs-arch-page.err; exit 1
    fi
    passes=$((passes + 1))
done

rc=0
( cd "$LAB" && python3 srs-dd/tools/srs_arch_doc.py --link index.html ) >/dev/null 2>/tmp/srs-arch-page.err || rc=$?
if [ "$rc" != "2" ]; then
    echo "FAIL INV-SPEC-130 — --link without --html exited $rc, expected 2"; exit 1
fi
passes=$((passes + 1))

# srs-end: INV-SPEC-130

# --- verifies: FR-ARCH-550 — what the parts stand on, where the project keeps a
# --- register: absent where it keeps none, since there is no question to answer.
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

Answers a question.
MD
doc
silent "FR-ARCH-550 no register, no section" "What the parts stand on"

cp srs-dd/tools/srs_grounds.py "$LAB/srs-dd/tools/"
mkdir -p "$LAB/grounds"
printf '{\n  "rules": {}\n}\n' > "$LAB/grounds/grounds-config.json"
cat > "$LAB/grounds/10-h-test.md" <<'MD'
# Grounds under test

### H-010 — The claim under the engine

```yaml
status: assumed
class: III
population: studios of five to fifty people
refuted_if: proportion < 0.25 at n >= 200
expires: 2099-01-01
owner: @someone
impact: a third of the plan
```

Studios of five to fifty people export weekly.

### B-010 — The engine rests on it

```yaml
status: active
requirement: FR-CORE-010
all_of: [H-010]
```

Worth building only if the claim holds.
MD
doc
says "FR-ARCH-550 the section is there once the register is" "## What the parts stand on"
says "FR-ARCH-550 the part, the hypothesis and its state" "- **E-010** The engine — H-010 (\`assumed\`) under 1 obligation(s)"
says "FR-ARCH-550 and where it comes from is said" "- What the parts stand on: the bets and hypotheses in \`grounds/\`"

# A register nothing in the layer stands on: said, not left blank.
cat > "$LAB/grounds/10-h-test.md" <<'MD'
# Grounds under test

### H-010 — A claim nothing rests on

```yaml
status: assumed
class: III
population: studios of five to fifty people
refuted_if: proportion < 0.25 at n >= 200
expires: 2099-01-01
owner: @someone
impact: a third of the plan
```

Studios of five to fifty people export weekly.
MD
doc
says "FR-ARCH-550 a register nothing stands on is said" "_No obligation of any part rests on a hypothesis the register holds._"
rm -rf "$LAB/grounds"

# srs-end: FR-ARCH-550

echo "arch-doc: $passes fixtures pass"
