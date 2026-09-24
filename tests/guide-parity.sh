#!/usr/bin/env bash
# The framework's own counterpart of a file it ships carries every rule the
# shipped file states: this repository is the first project it is applied
# to, and its guides and hook are its instances of what a target gets.
# Two roads bring a rule into a guide, so two checks hold it: a requirement
# naming the shipped file names the counterpart too, and a list of literal
# tokens per pair is found in both files.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# verifies: INV-SKILL-010
python3 - <<'PY'
import glob, os, re, sys

# (this repository's counterpart, the shipped file, the token list)
PAIRS = (("AGENTS.md", "skeleton/AGENTS.md", "AGENTS.txt"),
         ("CLAUDE.md", "skeleton/CLAUDE.md", "CLAUDE.txt"),
         (".githooks/pre-commit", "ci/pre-commit", "pre-commit.txt"))

# A requirement that names only the shipped file, each with its reason:
# what concerns a target alone.
TARGET_ONLY = {
    "FR-INIT-220": "the width line the installer fills in for a target",
}

RE_HEAD = re.compile(r"^### (\S+) — ", re.M)
RE_CODE = re.compile(r"^code: \[(.*?)\]", re.M)


def code_fields(text):
    """(identifier, [paths]) for every block that has a `code` field, each
    read inside its own section so that a heading without one never lends
    it the next block's."""
    heads = list(RE_HEAD.finditer(text))
    for index, head in enumerate(heads):
        end = heads[index + 1].start() if index + 1 < len(heads) else len(text)
        code = RE_CODE.search(text, head.end(), end)
        if code:
            yield head.group(1), [item.strip() for item in code.group(1).split(",")]


def tokens(path):
    with open(path, encoding="utf-8") as handle:
        return [line.strip() for line in handle
                if line.strip() and not line.startswith("#")]


def check(root, pairs, exempt):
    problems = []
    for own, shipped, listed in pairs:
        with open(os.path.join(root, own), encoding="utf-8") as handle:
            own_text = handle.read()
        with open(os.path.join(root, shipped), encoding="utf-8") as handle:
            shipped_text = handle.read()
        wanted = tokens(os.path.join(root, "tests/guide-parity", listed))
        if not wanted:
            problems.append((own, "has an empty list, which holds the pair to nothing"))
        for token in wanted:
            for path, text in ((own, own_text), (shipped, shipped_text)):
                if token not in text:
                    problems.append((path, "no longer names `%s`" % token))
    for path in sorted(glob.glob(os.path.join(root, "specs", "**", "*.md"), recursive=True)):
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
        for rid, items in code_fields(text):
            for own, shipped, _ in pairs:
                if shipped in items and own not in items and rid not in exempt:
                    problems.append((rid, "names %s in `code` and not %s" % (shipped, own)))
    return problems


# --- Negation first, on a lab: a token lost from either side, a requirement
# --- naming only the shipped file, and an empty list must each be red.
import shutil, tempfile
lab = tempfile.mkdtemp()
for sub in ("skeleton", "specs", "tests/guide-parity"):
    os.makedirs(os.path.join(lab, sub))
open(os.path.join(lab, "OWN.md"), "w").write("Run `tools/srs_check.py`. ART-030 binds.\n")
open(os.path.join(lab, "skeleton/OWN.md"), "w").write("Run `tools/srs_check.py`.\n")
open(os.path.join(lab, "HOOK"), "w").write("hook\n")
open(os.path.join(lab, "skeleton/HOOK"), "w").write("hook\n")
open(os.path.join(lab, "tests/guide-parity/own.txt"), "w").write("# list\ntools/srs_check.py\nART-030\n")
open(os.path.join(lab, "tests/guide-parity/hook.txt"), "w").write("# nothing\n")
open(os.path.join(lab, "specs/10-fr-x.md"), "w").write(
    "### FR-X-010 — Both\n\n```yaml\ncode: [OWN.md, skeleton/OWN.md]\n```\n\n"
    "### FR-X-020 — Shipped only\n\n```yaml\ncode: [skeleton/OWN.md]\n```\n\n"
    "### FR-X-030 — Excused\n\n```yaml\ncode: [skeleton/OWN.md]\n```\n")
lab_pairs = (("OWN.md", "skeleton/OWN.md", "own.txt"), ("HOOK", "skeleton/HOOK", "hook.txt"))
found = check(lab, lab_pairs, {"FR-X-030": "a target alone"})
assert ("skeleton/OWN.md", "no longer names `ART-030`") in found, found
assert ("FR-X-020", "names skeleton/OWN.md in `code` and not OWN.md") in found, found
assert any(path == "HOOK" and "empty list" in why for path, why in found), found
assert not any(path in ("OWN.md", "FR-X-010", "FR-X-030") for path, _ in found), found
assert len(found) == 3, found
shutil.rmtree(lab)
print("guide-parity: a lost token, a requirement naming only the shipped file and an empty list are each red")

# --- Then the repository.
found = check(".", PAIRS, TARGET_ONLY)

# A file identical in every project is no pair: it ships from this
# repository's own tree, so there is one copy and nothing to keep in step.
sys.path.insert(0, "tools")
import srs_init
template = os.path.join("specs", "adr", "template.md")
if (template, template) not in srs_init.collect_spec_skeleton():
    found.append((template, "is not shipped from this repository's own tree"))
if os.path.exists(os.path.join("skeleton", template)):
    found.append((os.path.join("skeleton", template), "is a second copy of %s" % template))

for path, why in found:
    print("  %s: %s" % (path, why))
if found:
    print("guide-parity: %d problem(s)" % len(found))
    sys.exit(1)
count = sum(len(tokens(os.path.join("tests/guide-parity", listed))) for _, _, listed in PAIRS)
print("guide-parity: every counterpart carries what its shipped file states (%d tokens over %d pairs)"
      % (count, len(PAIRS)))
PY
