#!/usr/bin/env bash
# Each standard names every rule its checker reports by name, with what it
# reports — the specification's, the register's and the layer's. A project
# sets a rule's cost in `rules` by name, and a table kept by hand beside a
# tuple in code is the one that falls behind, so each table is held to its
# checker's RULES both ways, and the specification's *Annotations* section
# to every annotation rule it restates.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# verifies: FR-SPEC-050, FR-GND-560, FR-ARCH-290
python3 - <<'PY'
import re, sys

sys.dont_write_bytecode = True
sys.path.insert(0, "tools")
import srs_arch
import srs_check
import srs_grounds

# Each standard beside the checker whose rules it names.
STANDARDS = (("specs/README.md", srs_check.RULES),
             ("grounds/README.md", srs_grounds.RULES),
             ("arch/README.md", srs_arch.RULES))

RE_ROW = re.compile(r"^\| `([a-z][a-z-]*)` \|([^|\n]*)\|\s*$", re.M)


def section(text, heading):
    """The body of a `## heading` section, up to the next `## `."""
    start = text.find("\n## %s\n" % heading)
    if start < 0:
        return ""
    end = text.find("\n## ", start + 1)
    return text[start:end if end >= 0 else len(text)]


def rule_table(text):
    """The table headed `| Rule | What it reports |`, up to the first line
    that is not a table row: a name in prose is not a row."""
    start = text.find("| Rule | What it reports |")
    if start < 0:
        return ""
    lines = []
    for line in text[start:].splitlines():
        if not line.startswith("|"):
            break
        lines.append(line)
    return "\n".join(lines) + "\n"


def check(text, rules):
    problems = []
    rows = RE_ROW.findall(rule_table(text))
    tabled = {name for name, _ in rows}
    problems += ["the checker reports `%s` and the standard's table does not name it" % name
                 for name in rules if name not in tabled]
    problems += ["the standard's table names `%s`, which the checker does not report" % name
                 for name in sorted(tabled - set(rules))]
    problems += ["the standard names `%s` without saying what it reports" % name
                 for name, what in rows if not what.strip()]
    annotations = section(text, "Annotations")
    problems += ["the Annotations section does not name `%s`" % name
                 for name in rules
                 if name.startswith("annotation-") and "`%s`" % name not in annotations]
    return problems


# --- Negation first: a rule missing from the table, a row for a rule that
# --- does not exist, a row saying nothing, and an annotation rule the
# --- Annotations section leaves out must each be reported; a name in prose
# --- outside the table is not a row.
lab = ("# Standard\n\n## Configuration\n\n| Key | Default | Meaning |\n|---|---|---|\n| `rules` | `{}` | x |\n\n"
       "**Rules.** Each warning carries a name.\n\n| Rule | What it reports |\n|---|---|\n"
       "| `kept` | Something |\n| `gone` | Something |\n| `annotation-quiet` |  |\n\n"
       "Prose naming `forgotten` is no row.\n\n"
       "## Annotations\n\nWarns on `annotation-quiet`.\n")
found = check(lab, ("kept", "forgotten", "annotation-quiet", "annotation-loud"))
assert "the checker reports `forgotten` and the standard's table does not name it" in found, found
assert "the standard's table names `gone`, which the checker does not report" in found, found
assert "the standard names `annotation-quiet` without saying what it reports" in found, found
assert "the checker reports `annotation-loud` and the standard's table does not name it" in found, found
assert "the Annotations section does not name `annotation-loud`" in found, found
assert len(found) == 5, found
print("standard-rules: a rule the table leaves out or invents, a row saying nothing, "
      "and an annotation rule the section leaves out are each red")

# --- Then the three standards, each against its own checker.
found = []
for path, rules in STANDARDS:
    with open(path, encoding="utf-8") as handle:
        found += ["%s: %s" % (path, problem) for problem in check(handle.read(), rules)]
for line in found:
    print("  " + line)
if found:
    print("standard-rules: %d problem(s)" % len(found))
    sys.exit(1)
print("standard-rules: each standard names every rule its checker reports, with what it reports (%s)"
      % ", ".join("%s %d" % (path.split("/")[0], len(rules)) for path, rules in STANDARDS))
PY
