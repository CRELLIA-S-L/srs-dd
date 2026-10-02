#!/usr/bin/env bash
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
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

# file verifies: INV-SKILL-010, FR-SKILL-380, FR-SKILL-390, FR-SKILL-430, FR-SKILL-440
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
open(os.path.join(lab, "OWN.md"), "w").write("Run `srs-dd/tools/srs_check.py`. SRS-DD-ART-030 binds.\n")
open(os.path.join(lab, "skeleton/OWN.md"), "w").write("Run `srs-dd/tools/srs_check.py`.\n")
open(os.path.join(lab, "HOOK"), "w").write("hook\n")
open(os.path.join(lab, "skeleton/HOOK"), "w").write("hook\n")
open(os.path.join(lab, "tests/guide-parity/own.txt"), "w").write("# list\nsrs-dd/tools/srs_check.py\nSRS-DD-ART-030\n")
open(os.path.join(lab, "tests/guide-parity/hook.txt"), "w").write("# nothing\n")
open(os.path.join(lab, "specs/10-fr-x.md"), "w").write(
    "### FR-X-010 — Both\n\n```yaml\ncode: [OWN.md, skeleton/OWN.md]\n```\n\n"
    "### FR-X-020 — Shipped only\n\n```yaml\ncode: [skeleton/OWN.md]\n```\n\n"
    "### FR-X-030 — Excused\n\n```yaml\ncode: [skeleton/OWN.md]\n```\n")
lab_pairs = (("OWN.md", "skeleton/OWN.md", "own.txt"), ("HOOK", "skeleton/HOOK", "hook.txt"))
found = check(lab, lab_pairs, {"FR-X-030": "a target alone"})
assert ("skeleton/OWN.md", "no longer names `SRS-DD-ART-030`") in found, found
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
sys.dont_write_bytecode = True
sys.path.insert(0, "tools"); sys.path.insert(0, "srs-dd/tools")
import srs_init
template = os.path.join("specs", "adr", "template.md")
if (template, template) not in srs_init.collect_spec_skeleton():
    found.append((template, "is not shipped from this repository's own tree"))
if os.path.exists(os.path.join("skeleton", template)):
    found.append((os.path.join("skeleton", template), "is a second copy of %s" % template))

# The shipped guide names every command the installer ships: a layer or a
# tool added later reaches a project's agents only through the guide they
# read in every session. `srs_parse.py` is a module the checkers import,
# not a command anybody runs, so it is not asked for.
NOT_COMMANDS = {"srs_parse.py": "a module the checkers import, not a command"}


def unnamed(text, commands):
    return ["srs-dd/tools/%s" % name for name in commands
            if name not in NOT_COMMANDS and "srs-dd/tools/%s" % name not in text]


assert unnamed("run `python3 srs-dd/tools/srs_check.py`", ("srs_check.py", "srs_parse.py", "srs_dates.py")) \
    == ["srs-dd/tools/srs_dates.py"], "a command the guide leaves out must be reported"
shipped = srs_init.TOOLS + srs_init.GROUNDS_TOOLS + srs_init.ARCH_TOOLS
with open("srs-dd/guide.md", encoding="utf-8") as handle:
    for command in unnamed(handle.read(), shipped):
        found.append(("srs-dd/guide.md", "does not name %s, which the installer ships" % command))

# The framework's guide is one text: the region of this repository's
# AGENTS.md and of the shipped starter each carry srs-dd/guide.md verbatim.
REGION = re.compile(r"<!-- srs-dd -->\n(.*?)\n<!-- /srs-dd -->", re.S)


def region_gaps(guide, guides):
    gaps = []
    for path, text in guides:
        hit = REGION.search(text)
        if not hit:
            gaps.append((path, "carries no region <!-- srs-dd --> … <!-- /srs-dd -->"))
        elif hit.group(1).strip("\n") != guide.strip("\n"):
            gaps.append((path, "its region differs from srs-dd/guide.md"))
    return gaps


assert region_gaps("a\nb", (("x", "t\n<!-- srs-dd -->\na\nb\n<!-- /srs-dd -->\nz"),)) == []
assert region_gaps("a\nb", (("x", "t\n<!-- srs-dd -->\na\n<!-- /srs-dd -->"),)) == [("x", "its region differs from srs-dd/guide.md")]
assert region_gaps("a", (("x", "no region"),)) == [("x", "carries no region <!-- srs-dd --> … <!-- /srs-dd -->")]
with open("srs-dd/guide.md", encoding="utf-8") as handle:
    guide_text = handle.read()
found += region_gaps(guide_text, [(path, open(path, encoding="utf-8").read())
                                  for path in ("AGENTS.md", "skeleton/AGENTS.md")])

# What the installer ships keeps sensitive data out of the repository: the
# guide names the article, and the constitution carries it with each kind
# of data it names. A guide that drops the line and a constitution that drops
# the article or one of its kinds are each reported.
SENSITIVE_KINDS = ("credentials", "personal data", "in confidence", "raw output")


def sensitive_gaps(guide, method):
    gaps = []
    if "SRS-DD-ART-100" not in guide:
        gaps.append(("srs-dd/guide.md", "does not name SRS-DD-ART-100"))
    start = method.find("## SRS-DD-ART-100")
    article = method[start:method.find("\n## ", start + 1)] if start >= 0 else ""
    if not article:
        gaps.append(("srs-dd/method.md", "carries no SRS-DD-ART-100"))
    gaps += [("srs-dd/method.md", "SRS-DD-ART-100 does not name %s" % kind)
             for kind in SENSITIVE_KINDS if article and kind not in article]
    return gaps


whole = "## SRS-DD-ART-100 — x\n\nNo credentials; no personal data; nothing in confidence; no raw output.\n"
assert sensitive_gaps("rule (SRS-DD-ART-100)", whole) == []
assert sensitive_gaps("rule", whole) == [("srs-dd/guide.md", "does not name SRS-DD-ART-100")]
assert sensitive_gaps("SRS-DD-ART-100", "## SRS-DD-ART-090 — y\n") == [("srs-dd/method.md", "carries no SRS-DD-ART-100")]
assert sensitive_gaps("SRS-DD-ART-100", whole.replace("no raw output", "no logs")) \
    == [("srs-dd/method.md", "SRS-DD-ART-100 does not name raw output")]
with open("srs-dd/method.md", encoding="utf-8") as method:
    method_text = method.read()
found += sensitive_gaps(guide_text, method_text)

# The method's articles are the framework's: each of the six stands in
# srs-dd/method.md. The numbers themselves are the project's, freed when the
# six moved out and spelled apart since (SRS-DD-ART-*), so the starter uses
# the first two rather than the gap the six left behind.
METHOD_ARTICLES = ("010", "020", "030", "050", "060", "100")
with open("skeleton/specs/constitution.md", encoding="utf-8") as handle:
    shipped_constitution = handle.read()
for number in METHOD_ARTICLES:
    if "## SRS-DD-ART-%s — " % number not in method_text:
        found.append(("srs-dd/method.md", "carries no SRS-DD-ART-%s" % number))

STARTING_ARTICLES = ("ART-010", "ART-020")
# A rule that is true of this framework and of nobody else, stated in the
# constitution a stranger receives as their own. The stdlib rule travelled
# that way until 2026-10-02: ADR-0003 holds it of our Python tools because
# targets are written in other languages, and it then told those targets
# what their own tooling may depend on.
FRAMEWORK_ONLY = ("standard-library", "standard library", "virtualenv")


def constitution_gaps(text):
    """What the constitution the installer ships must and must not hold.

    It defines the project's own starting articles and no article of the
    method's. Every article number it names outside its amendment log is one
    it defines: a number only mentioned is one a reader looks up and does
    not find. And no rule in it holds of this framework alone. The log is
    exempt — it is the history of this document, and the numbers in it are
    the ones the method's articles held before they moved out.
    """
    gaps = []
    where = "skeleton/specs/constitution.md"
    if re.search(r"^## SRS-DD-ART-", text, re.M):
        gaps.append((where, "carries an article of the method's"))
    defined = set(re.findall(r"^## (ART-\d{3}) — ", text, re.M))
    for wanted in STARTING_ARTICLES:
        if wanted not in defined:
            gaps.append((where, "defines no %s, a starting article of the project's own" % wanted))
    for line in text.splitlines():
        if line.startswith("- **Amended:**"):
            continue
        for named in sorted(set(re.findall(r"(?<!SRS-DD-)\bART-\d{3}\b", line))):
            if named not in defined:
                gaps.append((where, "names %s outside its amendment log and defines no such article" % named))
    for rule in FRAMEWORK_ONLY:
        if rule in text:
            gaps.append((where, "states as the project's a rule that holds of this framework alone: %r" % rule))
    return gaps


# --- Negation first, on strings: each of the four must be red.
assert constitution_gaps("## ART-010 — A\n\n## ART-020 — B\n") == []
assert constitution_gaps("## ART-010 — A\n\n## ART-020 — B\n\n## SRS-DD-ART-030 — C\n") \
    == [("skeleton/specs/constitution.md", "carries an article of the method's")]
assert constitution_gaps("## ART-010 — A\n") \
    == [("skeleton/specs/constitution.md", "defines no ART-020, a starting article of the project's own")]
assert constitution_gaps("rejected per ART-040\n\n## ART-010 — A\n\n## ART-020 — B\n") \
    == [("skeleton/specs/constitution.md",
         "names ART-040 outside its amendment log and defines no such article")]
assert constitution_gaps("- **Amended:** ART-040 moved\n\n## ART-010 — A\n\n## ART-020 — B\n") == []
assert constitution_gaps("## ART-010 — A\n\nTooling stays standard-library only.\n\n## ART-020 — B\n") \
    == [("skeleton/specs/constitution.md",
         "states as the project's a rule that holds of this framework alone: 'standard-library'")]
print("guide-parity: an article of the method's, a missing starting article, a number named and "
      "not defined, and a rule only ours are each red in the shipped constitution")
found += constitution_gaps(shipped_constitution)

# A starter that points at `README.md` pointed at the standard until it moved
# to srs-dd/ in 0.22.0; the path then resolved to nothing a target has, and
# no link check reaches the payload — FR-DOC-190 covers the landing page and
# docs/ alone.
for path in sorted(glob.glob("skeleton/**/*.md", recursive=True)):
    with open(path, encoding="utf-8") as handle:
        if "`README.md`" in handle.read():
            found.append((path, "points at `README.md`, which a target has only under srs-dd/"))

for path, why in found:
    print("  %s: %s" % (path, why))
if found:
    print("guide-parity: %d problem(s)" % len(found))
    sys.exit(1)
count = sum(len(tokens(os.path.join("tests/guide-parity", listed))) for _, _, listed in PAIRS)
print("guide-parity: every counterpart carries what its shipped file states (%d tokens over %d pairs)"
      % (count, len(PAIRS)))
PY
