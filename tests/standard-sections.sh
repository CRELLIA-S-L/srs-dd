#!/usr/bin/env bash
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# A rule a standard is the only home of stays in it: each pair below names a
# section of a standard and the words that section exists to say, and the
# suite fails when the section goes or the words do.
#
# A ratchet over prose, and it says so: it holds the sentence the standard was
# given, not every way of saying the same thing. It is worth having because a
# rule stated once has nothing else watching it — the copy in a procedure is
# what `FR-SKILL-020` took out — and a reader who read the standard and
# nothing else is the reader these sections were written for.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# file verifies: FR-ARCH-770
python3 - <<'PY'
import sys

# (the standard, its section, the words the section must say)
SECTIONS = (
    ("srs-dd/arch.md", "Naming a part",
     ("drawn from what the part is responsible for", "not from the files it holds")),
)


def section(text, heading):
    """The body of a `## heading` section, up to the next `## `."""
    start = text.find("\n## %s\n" % heading)
    if start < 0:
        return ""
    end = text.find("\n## ", start + 1)
    return text[start + 1:end if end >= 0 else len(text)]


def check(text, heading, wanted):
    body = section(text, heading)
    if not body:
        return ["has no *%s* section" % heading]
    prose = "\n".join(body.splitlines()[1:])        # the heading is not the section's words
    if not prose.strip():
        return ["has an empty *%s* section" % heading]
    return ["*%s* no longer says `%s`" % (heading, token)
            for token in wanted if token not in prose]


# --- Negation first: a section that is gone, one left empty, and one that
# --- lost a word must each be reported, and a heading of another level is
# --- not the section.
kept = "# S\n\n## Kept\n\nThe boundary is drawn from the responsibility, never the files.\n\n## After\n\nx\n"
assert check(kept, "Kept", ("drawn from the responsibility", "never the files")) == []
assert check(kept, "Gone", ("x",)) == ["has no *Gone* section"]
assert check(kept, "Kept", ("never the tree",)) == ["*Kept* no longer says `never the tree`"]
assert check("# S\n\n## Kept\n\n## After\n\nx\n", "Kept", ("x",)) == ["has an empty *Kept* section"]
assert check("# S\n\n### Kept\n\nThe boundary is drawn from the responsibility.\n", "Kept",
             ("drawn from",)) == ["has no *Kept* section"]
print("standard-sections: a section that is gone, one left empty, one that lost a word, "
      "and a heading of another level are each red")

# --- Then the standards.
found = []
for path, heading, wanted in SECTIONS:
    with open(path, encoding="utf-8") as handle:
        found += ["%s: %s" % (path, problem) for problem in check(handle.read(), heading, wanted)]
for line in found:
    print("  " + line)
if found:
    print("standard-sections: %d problem(s)" % len(found))
    sys.exit(1)
print("standard-sections: every section a standard is the only home of still says it (%d)"
      % sum(len(wanted) for _p, _h, wanted in SECTIONS))
PY
