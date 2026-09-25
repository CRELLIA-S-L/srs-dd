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

# srs-end: FR-DOC-140
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
        ids = set(re.findall(r"\b[A-Z]+-[A-Z]+-\d{3,}\b", example))
        own = re.search(r"^### ([A-Z]+-[A-Z]+-\d{3,})", example, re.M)
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

# srs-end: FR-DOC-150
# --- verifies: FR-DOC-160 — the skills table names exactly what the installer copies.
sys.dont_write_bytecode = True
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

# srs-end: FR-DOC-160
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

# srs-end: FR-DOC-170
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
# And the upgrade page says them in a sentence, outside any block: held the
# same way, since the upgrader passes the installer's codes through.
with open("docs/upgrade.md", encoding="utf-8") as handle:
    sentence = next((line for line in handle if line.startswith("Exit codes match the installer:")), "")
said_codes = set(re.findall(r"\b(\d) [a-z]", sentence))
if said_codes != tool_codes:
    fail("docs/upgrade.md — FR-DOC-180 — the sentence on exit codes says %s; the installer states %s"
         % (sorted(said_codes), sorted(tool_codes)))

# srs-end: FR-DOC-180
# --- verifies: FR-DOC-210 — the picture the page shows is the file the
# --- pipeline publishes: the image's file name on the page is the name the
# --- Pages job writes with --svg, and the image links to the page.
picture = section("What it looks like")
# And it says how to read the picture: what a box is, what a line is, and
# which lane is the page's own — the clause the image alone cannot carry.
said = " ".join(line for _n, line in picture)
for what, rx in (("what a box is", r"\bbox is\b"), ("what a line is", r"\bline is\b"),
                 ("which lane is the page's own", r"lane is this page's own")):
    if not re.search(rx, said):
        fail("README.md — FR-DOC-210 — the picture section does not say %s" % what)
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

# srs-end: FR-DOC-210
# --- verifies: FR-DOC-220 — every list of this repository's tools names each
# --- one: the row for tools/ on the landing page's map and in the agent guide
# --- names every file tracked there, and the hand install names every tool
# --- the installer copies. Each fell behind a tool added after it was written.
in_tools = sorted(path[len("tools/"):] for path in tracked
                  if path.startswith("tools/") and "/" not in path[len("tools/"):])
for doc in ("README.md", "AGENTS.md"):
    with open(doc, encoding="utf-8") as handle:
        row = next((line for line in handle if line.startswith("| `tools/` |")), "")
    if not row:
        fail("%s — FR-DOC-220 — has no row for tools/" % doc)
    for name in in_tools:
        if "`%s`" % name not in row:
            fail("%s — FR-DOC-220 — the row for tools/ does not name %s" % (doc, name))
sys.dont_write_bytecode = True
sys.path.insert(0, "tools")
import srs_init
with open("docs/install.md", encoding="utf-8") as handle:
    by_hand = next((line for line in handle if line.startswith("- `tools/srs_check.py`")), "")
for name in srs_init.TOOLS:
    if "`tools/%s`" % name not in by_hand:
        fail("docs/install.md — FR-DOC-220 — the hand install does not name tools/%s, which the installer copies" % name)
# And each tool in the group it is said to be in, both ways: shipped with
# every install, with a layer, or kept here. A name moved to the wrong group
# passes a check that only asks whether it is named.
kept_tools = set(in_tools) - set(srs_init.TOOLS + srs_init.GROUNDS_TOOLS + srs_init.ARCH_TOOLS)
GROUPS = {"README.md": {"yours after install": srs_init.TOOLS,
                        "yours if you keep a register": srs_init.GROUNDS_TOOLS,
                        "yours if you keep an architecture layer": srs_init.ARCH_TOOLS,
                        "stay here": kept_tools},
          "AGENTS.md": {"shipped to targets": srs_init.TOOLS,
                        "shipped where a project keeps a register": srs_init.GROUNDS_TOOLS,
                        "shipped where a project keeps an architecture layer": srs_init.ARCH_TOOLS,
                        "framework-only": kept_tools}}
for doc, groups in GROUPS.items():
    with open(doc, encoding="utf-8") as handle:
        row = next((line for line in handle if line.startswith("| `tools/` |")), "")
    said = {label: set(re.findall(r"`([^`]+)`", names))
            for names, label in re.findall(r"((?:`[^`]+`(?:, | and )?)+) \(([^)]*)\)", row)}
    for label, members in groups.items():
        if said.get(label) != set(members):
            fail("%s — FR-DOC-220 — the tools/ row says %r of %s, and it is %s"
                 % (doc, label, sorted(said.get(label, ())), sorted(members)))
# The procedures the same way: the map's row and the agent document's table
# name every procedure here, the hand install every one the installer
# copies, and the contributors' list of what travels every shipped tool.
procedures = sorted(os.path.basename(os.path.dirname(p)) for p in glob.glob(".claude/skills/*/SKILL.md"))
with open("README.md", encoding="utf-8") as handle:
    row = next((line for line in handle if line.startswith("| `.claude/skills/` |")), "")
with open("docs/agents.md", encoding="utf-8") as handle:
    table = "".join(line for line in handle if line.startswith("| `"))
listed_in_table = set(n for first in re.findall(r"^\| ((?:`[^`]+`(?:, )?)+) \|", table, re.M)
                      for n in re.findall(r"`([^`]+)`", first))
for name in sorted(listed_in_table - set(procedures)):
    fail("docs/agents.md — FR-DOC-220 — the table names %s, which is no procedure here" % name)
for name in procedures:
    if "`%s`" % name not in row:
        fail("README.md — FR-DOC-220 — the row for .claude/skills/ does not name %s" % name)
    if "`%s`" % name not in table:
        fail("docs/agents.md — FR-DOC-220 — the table of procedures does not name %s" % name)
# The agent guide names the procedures that never leave this repository:
# every procedure the installer does not copy, and none that it does.
with open("AGENTS.md", encoding="utf-8") as handle:
    guide_row = next((line for line in handle if line.startswith("| `.claude/skills/` |")), "")
kept_here = set(procedures) - set(srs_init.SKILLS + srs_init.GROUNDS_SKILLS + srs_init.ARCH_SKILLS)
said_here = set(re.findall(r"`([a-z-]+)`", guide_row.split("framework-only")[0])) if "framework-only" in guide_row else set()
for name in sorted(kept_here - said_here):
    fail("AGENTS.md — FR-DOC-220 — the row for .claude/skills/ does not name %s as framework-only" % name)
for name in sorted(said_here - kept_here - {".claude/skills/"}):
    fail("AGENTS.md — FR-DOC-220 — the row for .claude/skills/ calls %s framework-only, and the installer copies it" % name)
with open("docs/install.md", encoding="utf-8") as handle:
    by_hand = next((line for line in handle if line.startswith("- from `.claude/skills/`:")), "")
for name in srs_init.SKILLS:
    if "`%s`" % name not in by_hand:
        fail("docs/install.md — FR-DOC-220 — the hand install does not name %s, which the installer copies" % name)
with open("CONTRIBUTING.md", encoding="utf-8") as handle:
    travels = next((line for line in handle if line.startswith("The tooling that travels")), "")
for name in srs_init.TOOLS + srs_init.GROUNDS_TOOLS + srs_init.ARCH_TOOLS:
    if "`%s`" % name not in travels:
        fail("CONTRIBUTING.md — FR-DOC-220 — the tooling that travels does not name %s" % name)

# srs-end: FR-DOC-220
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
# srs-end: FR-DOC-190
