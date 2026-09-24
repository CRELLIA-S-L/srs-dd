#!/usr/bin/env bash
# Every shipped procedure, and each agent guide, fits a budget of words —
# the file itself, and the file together with what it tells the reader to
# open before its first step. A procedure is read by an agent at every
# invocation and paid for in tokens each time; this suite is where growing
# back into an essay, or sending the reader to a standard whole, turns red.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# verifies: NFR-SKILL-020
# The budgets, each beside the reason for its number. Raising one is a
# visible act: change the number here and say why in the commit. Lowering
# one follows a procedure that was shortened, so that the floor stays
# under the cost as it falls.
#
#   OWN         words of the file itself, frontmatter and description
#               included — the description sits in the prompt of every
#               session. 2 950 was where the longest procedure stood on
#               2026-09-19 (`srs`, 2 902 words); 1 300 is where the longest
#               stands since the five longest were rewritten on 2026-09-20
#               (`srs-init`, 1 250); the number falls with it.
#   TRANSITIVE  OWN plus the words of every file the preamble — the text
#               before the first `## ` heading — tells the reader to open:
#               a line beginning `Read` that names a file in backticks, or
#               a line beginning `Read first:`. 6 700 is where `srs-bet`
#               stands with the register's standard, which it tells the
#               reader to open whole and once (1 242 + 5 368 on 2026-09-21,
#               after the standard gained the sentences on the minimum and
#               on a class III verdict): measured on 2026-09-20,
#               one whole read in one turn burned fewer tokens over the run
#               than three section reads in three, because every turn
#               re-reads the context before it. The number is a ceiling on
#               what a procedure sends the reader to, not a verdict on
#               reading it.
#   GUIDE       OWN for the two agent guides, which carry more than a
#               procedure does: every session reads them, whatever it was
#               asked. 1 500 is where this repository's guide stands on
#               2026-09-23 once it carries every rule the shipped guide
#               states (INV-SKILL-010) — the constitution, the generated
#               files, ART-030, three procedures — beside its own.
OWN=1300
TRANSITIVE=6700
GUIDE=1500

# What is measured: every shipped procedure, and the two agent guides —
# this repository's and the one the installer ships — which are loaded by
# every session whether or not a procedure is invoked.
python3 - "$OWN" "$TRANSITIVE" "$GUIDE" <<'PY'
import glob, os, re, sys

own_budget, transitive_budget, guide_budget = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
GUIDES = ("AGENTS.md", "skeleton/AGENTS.md")
RE_PATH = re.compile(r"`([^`\s]+\.(?:md|json))`")


def words(path):
    with open(path, encoding="utf-8") as handle:
        return len(handle.read().split())


def preamble(text):
    body = text.split("\n---\n", 2)[-1] if text.startswith("---") else text
    return body.split("\n## ", 1)[0]


def told_to_open(text):
    """The files the preamble tells the reader to open, in order, once
    each: named on a line that begins `Read` (bold or not) — `Read
    `specs/README.md` first…` — or on a `Read first:` line. A mention on
    any other line is a mention, not an instruction, and is not counted;
    a `Read it` line that names no file counts nothing, which is why a
    procedure says `Read first:` with the path on that line."""
    opens = []
    for line in preamble(text).splitlines():
        if re.match(r"\**Read\b", line.strip()):
            for candidate in RE_PATH.findall(line):
                if candidate not in opens:
                    opens.append(candidate)
    return opens


def measure(root):
    """[(name, own, transitive, opens, missing)] for every procedure and
    guide under root; missing is what a Read line names that is not there."""
    paths = sorted(glob.glob(os.path.join(root, ".claude/skills/*/SKILL.md")))
    for guide in ("AGENTS.md", "skeleton/AGENTS.md"):
        if os.path.isfile(os.path.join(root, guide)):
            paths.append(os.path.join(root, guide))
    rows = []
    for path in paths:
        rel = os.path.relpath(path, root)
        name = rel.split("/")[2] if rel.startswith(".claude/") else rel
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
        opens = told_to_open(text)
        missing = [p for p in opens if not os.path.isfile(os.path.join(root, p))]
        transitive = len(text.split()) + sum(
            words(os.path.join(root, p)) for p in opens if p not in missing)
        rows.append((name, len(text.split()), transitive, opens, missing))
    return rows


def judge(rows):
    over = []
    for name, own, transitive, opens, missing in rows:
        for path in missing:
            over.append("%s: tells the reader to open %s, which does not exist" % (name, path))
        budget = guide_budget if name in GUIDES else own_budget
        if own > budget:
            over.append("%s: %d words of its own, budget %d" % (name, own, budget))
        if transitive > transitive_budget:
            over.append("%s: %d words with %s, budget %d"
                        % (name, transitive, ", ".join(opens) or "nothing opened",
                           transitive_budget))
    return over


# --- Negation first, on a lab: the suite must be able to go red, on each
# --- of the three counts, or a green over the repository proves nothing.
import tempfile
lab = tempfile.mkdtemp()
os.makedirs(os.path.join(lab, ".claude/skills/fat"))
os.makedirs(os.path.join(lab, ".claude/skills/lean"))
os.makedirs(os.path.join(lab, ".claude/skills/lost"))
os.makedirs(os.path.join(lab, "specs"))
with open(os.path.join(lab, "specs/README.md"), "w") as handle:
    handle.write("word " * (transitive_budget - 10) + "\n")
with open(os.path.join(lab, ".claude/skills/fat/SKILL.md"), "w") as handle:
    handle.write("---\ndescription: x\n---\n\n# Fat\n\n" + "word " * (own_budget + 1) + "\n")
with open(os.path.join(lab, ".claude/skills/lean/SKILL.md"), "w") as handle:
    handle.write("---\ndescription: x\n---\n\n# Lean\n\nRead `specs/README.md` first.\n"
                 "See also `specs/README.md` and `specs/other.md`, mentioned only.\n\n## Step\n\n"
                 + "word " * 20 + "\n")
with open(os.path.join(lab, ".claude/skills/lost/SKILL.md"), "w") as handle:
    handle.write("---\ndescription: x\n---\n\n# Lost\n\nRead `specs/gone.md` first.\n\n## Step\n\nword\n")
os.makedirs(os.path.join(lab, "skeleton"))
with open(os.path.join(lab, "AGENTS.md"), "w") as handle:           # past a procedure's budget, within a guide's
    handle.write("word " * (own_budget + 10) + "\n")
with open(os.path.join(lab, "skeleton/AGENTS.md"), "w") as handle:  # past a guide's
    handle.write("word " * (guide_budget + 1) + "\n")
lab_rows = {name: (own, tr, opens, missing) for name, own, tr, opens, missing in measure(lab)}
assert lab_rows["fat"][0] == own_budget + 1 + 6, lab_rows["fat"]      # the frontmatter and the heading count too
assert lab_rows["lean"][2] == ["specs/README.md"], lab_rows["lean"]  # once, and not the mention
assert lab_rows["lean"][1] == lab_rows["lean"][0] + transitive_budget - 10, lab_rows["lean"]
assert lab_rows["lost"][3] == ["specs/gone.md"], lab_rows["lost"]
lab_over = judge(measure(lab))
assert any(l.startswith("fat: ") and "of its own" in l for l in lab_over), lab_over
assert any(l.startswith("lean: ") and "with specs/README.md" in l for l in lab_over), lab_over
assert any(l.startswith("lost: ") and "does not exist" in l for l in lab_over), lab_over
assert not any(l.startswith("lean: ") and "of its own" in l for l in lab_over), lab_over
assert any(l.startswith("skeleton/AGENTS.md: ") and "of its own" in l for l in lab_over), lab_over
assert not any(l.startswith("AGENTS.md: ") for l in lab_over), lab_over
import shutil
shutil.rmtree(lab)
print("skill-budget: a lab procedure over either budget, a guide over its own, or opening a file that is not there, is red")

# --- Then the repository.
rows = measure(".")
if not [r for r in rows if r[0] not in GUIDES]:
    print("skill-budget: no procedure under .claude/skills — nothing measured")
    sys.exit(1)
print("%-20s %6s %10s  %s" % ("file", "own", "transitive", "told to open first"))
for name, own, transitive, opens, missing in rows:
    print("%-20s %6d %10d  %s" % (name, own, transitive, ", ".join(opens) or "-"))
over = judge(rows)
if over:
    print("skill-budget: over budget:")
    for line in over:
        print("  " + line)
    sys.exit(1)
print("skill-budget: %d files within %d own (%d for a guide) / %d transitive words"
      % (len(rows), own_budget, guide_budget, transitive_budget))
PY
