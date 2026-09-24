#!/usr/bin/env bash
# A procedure keeps its instructions when it is shortened: every shipped
# procedure is held to a list of what it must name — commands, articles,
# files and other procedures — written off the original before the cut.
# The list proves the command is still named; a person reads whether the
# sentence around it still tells the reader to run it.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# verifies: FR-SKILL-300, FR-SKILL-340, FR-SKILL-350, FR-SKILL-360
# The lists live in tests/skill-instructions/<procedure>.txt, one literal
# token per line, `#` for a comment. A command token is `tools/x.py` or
# `tools/x.py --flag`; the second holds when some invocation of the tool
# in the text carries that flag, whatever else it carries. Every other
# token is a substring the text must contain as written.
python3 - <<'PY'
import glob, os, re, sys


def tokens(path):
    with open(path, encoding="utf-8") as handle:
        return [line.strip() for line in handle
                if line.strip() and not line.startswith("#")]


def invocations(text, tool):
    """Every run of the tool in the text, as the flags that follow it on
    that line — up to a closing backtick or the end of the line."""
    runs = []
    for match in re.finditer(re.escape(tool) + r"([^`\n]*)", text):
        runs.append(set(re.findall(r"(?<!\S)(--?[\w-]+)", match.group(1))))
    return runs


def missing(text, wanted):
    lost = []
    for token in wanted:
        if token.startswith("tools/") and " " in token:
            tool, flag = token.split(" ", 1)
            if not any(flag in flags for flags in invocations(text, tool)):
                lost.append(token)
        elif token not in text:
            lost.append(token)
    return lost


def check(root):
    """[(list name, problem)] over root: a list for a procedure that does
    not ship, a shipped procedure without a list, a token the text lost."""
    problems = []
    shipped = {p.split("/")[-2] for p in glob.glob(os.path.join(root, ".claude/skills/*/SKILL.md"))}
    listed = {os.path.basename(p)[:-4] for p in glob.glob(os.path.join(root, "tests/skill-instructions/*.txt"))}
    for name in sorted(listed - shipped):
        problems.append((name, "has a list and no procedure — a stale list, or one written for a procedure that never shipped"))
    for name in sorted(shipped - listed):
        problems.append((name, "ships with no list of what it must name"))
    for name in sorted(shipped & listed):
        with open(os.path.join(root, ".claude/skills", name, "SKILL.md"), encoding="utf-8") as handle:
            text = handle.read()
        wanted = tokens(os.path.join(root, "tests/skill-instructions", name + ".txt"))
        if not wanted:
            problems.append((name, "has an empty list, which holds the procedure to nothing"))
        for token in missing(text, wanted):
            problems.append((name, "no longer names `%s`" % token))
    return problems


# --- Negation first, on a lab: each of the four findings must be reachable,
# --- or a green over the repository proves nothing.
import shutil, tempfile
lab = tempfile.mkdtemp()
for name in ("kept", "cut", "empty", "unlisted"):
    os.makedirs(os.path.join(lab, ".claude/skills", name))
os.makedirs(os.path.join(lab, "tests/skill-instructions"))
original = ("# Kept\n\nRun `python3 tools/srs_view.py --code <path>` first; then `python3 tools/srs_view.py --list --area X`.\n"
            "Never without confirmation (ART-030). Then `srs-new`.\n")
open(os.path.join(lab, ".claude/skills/kept/SKILL.md"), "w").write(original)
open(os.path.join(lab, ".claude/skills/cut/SKILL.md"), "w").write(original.replace("--code <path>", "<path>"))
open(os.path.join(lab, ".claude/skills/empty/SKILL.md"), "w").write(original)
open(os.path.join(lab, ".claude/skills/unlisted/SKILL.md"), "w").write(original)
wanted = "# list\ntools/srs_view.py\ntools/srs_view.py --code\ntools/srs_view.py --area\nART-030\nsrs-new\n"
for name in ("kept", "cut", "stale"):
    open(os.path.join(lab, "tests/skill-instructions", name + ".txt"), "w").write(wanted)
open(os.path.join(lab, "tests/skill-instructions/empty.txt"), "w").write("# nothing\n")
found = check(lab)
assert ("cut", "no longer names `tools/srs_view.py --code`") in found, found
assert not any(name == "kept" for name, _ in found), found       # --area is found inside `--list --area X`
assert any(name == "stale" and "no procedure" in why for name, why in found), found
assert any(name == "unlisted" and "no list" in why for name, why in found), found
assert any(name == "empty" and "empty list" in why for name, why in found), found
assert len(found) == 4, found
shutil.rmtree(lab)
print("skill-instructions: a lost command, a stale list, an unlisted procedure and an empty list are each red")

# --- Then the repository.
found = check(".")
for name, why in found:
    print("  %s: %s" % (name, why))
if found:
    print("skill-instructions: %d problem(s)" % len(found))
    sys.exit(1)
count = sum(len(tokens(p)) for p in glob.glob("tests/skill-instructions/*.txt"))
print("skill-instructions: every shipped procedure still names what its list asks (%d tokens over %d lists)"
      % (count, len(glob.glob("tests/skill-instructions/*.txt"))))
PY
