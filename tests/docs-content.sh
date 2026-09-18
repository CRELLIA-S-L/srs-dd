#!/usr/bin/env bash
# What the landing page derives from the repository is held to the
# repository: its headings, its example requirement, its skills table, its
# map of the top level, the installer's exit codes, and every relative link
# in README.md and docs/. One instrument per claim, each named for the
# requirement it verifies; a failure names the line.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

python3 - <<'PY'
import glob, os, re, shutil, subprocess, sys, tempfile

failures = []
def fail(text):
    failures.append(text)

with open("README.md", encoding="utf-8") as handle:
    lines = handle.read().split("\n")

# Lines outside fenced blocks, with their numbers: a heading inside an
# example is not a section, as a heading inside a code block is not a
# requirement to the checker (FR-CHK-110).
prose, fenced, fence = [], [], None
for number, line in enumerate(lines, 1):
    opened = re.match(r"^(`{3,})", line)
    if fence is None and opened:
        fence = opened.group(1)
        fenced.append((number, line))
        continue
    if fence is not None:
        fenced.append((number, line))
        if line.startswith(fence):
            fence = None
        continue
    prose.append((number, line))

def section(title, level="## "):
    """The prose lines of one section, up to the next heading of the same
    or a higher level."""
    out, inside = [], False
    for number, line in prose:
        if line.startswith(level) and line[len(level):].strip() == title:
            inside = True
            continue
        if inside and re.match(r"^#{1,%d} " % len(level.strip()), line):
            break
        if inside:
            out.append((number, line))
    return out

# --- verifies: FR-DOC-140 — the headings are the sections FR-DOC-010 names,
# --- in its order, and no other.
EXPECTED = [
    "## What breaks without it",
    "## What it looks like",
    "## A requirement, and what the tooling does with it",
    "## What you get back",
    "## Why the thing exists, not only what it does",
    "## Install",
    "## Handing this to an agent",
    "### What you then tell the agent to do",
    "## The loop",
    "## Reading the specification",
    "## Where things are",
]
headings = [line.rstrip() for _n, line in prose if re.match(r"^##+ ", line)]
if headings != EXPECTED:
    fail("FR-DOC-140 — the headings are not the ten sections in their order:\n  got  %s\n  want %s"
         % (headings, EXPECTED))

# --- verifies: FR-DOC-150 — the example requirement passes the checker in a
# --- project laid out as the standard asks. The neighbours it links to are
# --- supplied, since an example shows a link on purpose; the files it names
# --- are created empty, since what is checked is the block and not the code.
example = []
for number, line in fenced:
    if line.startswith("````markdown"):
        example = ["open"]
    elif example and line.startswith("````"):
        break
    elif example:
        example.append(line)
example = "\n".join(example[1:])
if not example.strip():
    fail("FR-DOC-150 — no ````markdown example block found on the page")
else:
    lab = tempfile.mkdtemp(prefix="srs-docs-example-")
    try:
        os.makedirs(os.path.join(lab, "tools"))
        os.makedirs(os.path.join(lab, "specs"))
        for tool in ("srs_check.py", "srs_parse.py", "srs_view.py"):
            shutil.copy(os.path.join("tools", tool), os.path.join(lab, "tools", tool))
        ids = set(re.findall(r"\b[A-Z]+-[A-Z]+-\d{3}\b", example))
        own = re.search(r"^### ([A-Z]+-[A-Z]+-\d{3})", example, re.M)
        own = own.group(1) if own else ""
        area = own.split("-")[1] if own else "CORE"
        with open(os.path.join(lab, "specs", "srs-config.json"), "w", encoding="utf-8") as handle:
            handle.write('{"areas": ["%s"], "code_roots": ["src"], "test_roots": ["tests"], '
                         '"code_extensions": [".py"]}\n' % area)
        stubs = ""
        for rid in sorted(ids - {own}):
            stubs += ("\n### %s — A neighbour the example links to\n\n```yaml\nstatus: implemented\n"
                      "verification: T\nderives_from: []\ndepends_on: []\nrefines: []\n"
                      "conflicts_with: []\ncode: [src/neighbour.py]\ntests: [tests/test_neighbour.py]\n"
                      "created: 2026-01-01\n```\n\nThe system **shall** exist.\n" % rid)
        with open(os.path.join(lab, "specs", "10-fr-%s.md" % area.lower()), "w", encoding="utf-8") as handle:
            handle.write("# Example\n" + stubs + "\n" + example + "\n")
        for path in re.findall(r"\b(?:src|tests)/[\w./-]+", example) + ["src/neighbour.py", "tests/test_neighbour.py"]:
            full = os.path.join(lab, path)
            os.makedirs(os.path.dirname(full), exist_ok=True)
            open(full, "a").close()
        run = subprocess.run(["python3", "tools/srs_check.py", "--no-write"], cwd=lab,
                             capture_output=True, text=True)
        if run.returncode != 0:
            fail("FR-DOC-150 — the example requirement is refused by the checker:\n" + run.stdout + run.stderr)
    finally:
        shutil.rmtree(lab, ignore_errors=True)

# --- verifies: FR-DOC-160 — the skills table names exactly what the installer copies.
sys.path.insert(0, "tools")
import srs_init
shipped = set(srs_init.SKILLS) | set(srs_init.GROUNDS_SKILLS) | set(srs_init.ARCH_SKILLS)
named = set()
for _n, line in section("What you then tell the agent to do", "### "):
    if line.startswith("|"):
        named.update(re.findall(r"`(srs[a-z-]*)` —", line))
if named != shipped:
    fail("FR-DOC-160 — the skills table names %s; the installer copies %s"
         % (sorted(named - shipped) or "nothing extra", sorted(shipped - named) or "nothing missing")
         if named ^ shipped else "FR-DOC-160 — no table rows found")

# --- verifies: FR-DOC-170 — the map names exactly the top level, less the
# --- page itself and git's own configuration.
tracked = subprocess.run(["git", "ls-files"], capture_output=True, text=True).stdout.split("\n")
top = set(path.split("/")[0] for path in tracked if path) - {"README.md", ".gitattributes", ".gitignore"}
rows = []
for number, line in section("Where things are"):
    if line.startswith("| `"):
        first = line.split("|")[1]
        rows.append((number, re.findall(r"`([^`]+)`", first)))
mapped = set()
for number, paths in rows:
    for path in paths:
        mapped.add(path.rstrip("/").split("/")[0])
        if not os.path.exists(path.rstrip("/")):
            fail("README.md:%d — FR-DOC-170 — the map names %s, which does not exist" % (number, path))
for path in sorted(top - mapped):
    fail("FR-DOC-170 — %s is at the top level and has no row in the map" % path)

# --- verifies: FR-DOC-180 — the exit codes the agent document lists are the
# --- installer's: every `N  text` line inside a fenced block of docs/agents.md
# --- is one, and the set equals what the installer's usage text states.
usage = subprocess.run(["python3", "tools/srs_init.py", "-h"], capture_output=True, text=True).stdout
usage = " ".join(usage.split())
stated = re.search(r"Exit codes: (.*?)\.(?:\s|$)", usage)
tool_codes = set(re.findall(r"(?:^|;\s*)(\d+)\s", stated.group(1))) if stated else set()
# Every document that lists them is held, each on its own: two lists that
# disagree with each other are two findings, not one.
listed = {}
for path in sorted(glob.glob("docs/*.md")):
    codes, inside = set(), False
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("```"):
                inside = not inside
                continue
            matched = re.match(r"^(\d)\s{2,}\S", line)
            if inside and matched:
                codes.add(matched.group(1))
    if codes:
        listed[path] = codes
if not tool_codes:
    fail("FR-DOC-180 — the installer's usage text states no exit codes; the pattern is broken, not the page")
elif not listed:
    fail("FR-DOC-180 — no document under docs/ lists the installer's exit codes in a fenced block")
for path, codes in sorted(listed.items()):
    if codes != tool_codes:
        fail("FR-DOC-180 — %s lists exit codes %s; the installer states %s"
             % (path, sorted(codes), sorted(tool_codes)))

# --- verifies: FR-DOC-210 — the picture the page shows is the file the
# --- pipeline publishes: the image's file name on the page is the name the
# --- Pages job writes with --svg, and the image links to the page.
picture = section("What it looks like")
shown = re.findall(r"!\[[^\]]*\]\((\S+?)\)", "\n".join(line for _n, line in picture))
with open(".github/workflows/srs.yml", encoding="utf-8") as handle:
    published = re.findall(r"--svg\s+site/(\S+)", handle.read())
if not shown:
    fail("FR-DOC-210 — the picture section shows no image")
elif not published:
    fail("FR-DOC-210 — the Pages job writes no image with --svg; the pattern is broken, not the page")
elif shown[0].rsplit("/", 1)[-1] != published[0]:
    fail("FR-DOC-210 — the page shows %s; the pipeline publishes %s" % (shown[0], published[0]))
if not any(re.search(r"\[!\[[^\]]*\]\([^)]*\)\]\(https://[^)]+\)", line) for _n, line in picture):
    fail("FR-DOC-210 — the picture is not wrapped in a link to the live page")

# --- verifies: FR-DOC-190 — a relative link leads to a file that exists.
LINK = re.compile(r"\]\(([^)\s#]+)(?:#[^)]*)?\)")
for path in ["README.md"] + sorted(glob.glob("docs/*.md")):
    with open(path, encoding="utf-8") as handle:
        for number, line in enumerate(handle, 1):
            for target in LINK.findall(line):
                if re.match(r"^[a-z]+:", target):
                    continue
                if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(path), target))):
                    fail("%s:%d — FR-DOC-190 — links to %s, which does not exist" % (path, number, target))

for text in failures:
    print(text)
if failures:
    sys.exit(1)
print("docs-content: headings, example, skills, map, exit codes, picture and links hold to the repository")
PY
