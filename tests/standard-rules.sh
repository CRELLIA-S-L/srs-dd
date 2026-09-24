#!/usr/bin/env bash
# The standard names every rule the checker reports by name, with what it
# reports: a project sets a rule's cost in `rules` and excuses a requirement
# from one in `exempt`, both by name, and a table kept by hand beside a
# tuple in code is the one that falls behind. The table under
# *Configuration* is held to RULES both ways, and the *Annotations* section
# to every annotation rule it restates.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# verifies: FR-SPEC-050
python3 - <<'PY'
import re, sys

sys.path.insert(0, "tools")
from srs_check import RULES

RE_ROW = re.compile(r"^\| `([a-z][a-z-]*)` \|([^|\n]*)\|\s*$", re.M)


def section(text, heading):
    """The body of a `## heading` section, up to the next `## `."""
    start = text.find("\n## %s\n" % heading)
    if start < 0:
        return ""
    end = text.find("\n## ", start + 1)
    return text[start:end if end >= 0 else len(text)]


def check(text, rules):
    problems = []
    config = section(text, "Configuration")
    table = config[config.find("**Rules.**"):] if "**Rules.**" in config else ""
    rows = RE_ROW.findall(table)
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

# --- Then the standard.
with open("specs/README.md", encoding="utf-8") as handle:
    found = check(handle.read(), RULES)
for line in found:
    print("  " + line)
if found:
    print("standard-rules: %d problem(s)" % len(found))
    sys.exit(1)
print("standard-rules: the standard names all %d rules the checker reports, each with what it reports"
      % len(RULES))
PY
