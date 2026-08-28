#!/usr/bin/env bash
# The line-width gate: 120 columns in code, and markdown is not looked at.
#
# implements: FR-CI-100
#
# The rule and its reasoning are CONTRIBUTING.md's, under Ground rules; this
# file is the part that refuses. Prose is where a rule of this kind goes to
# be ignored — the width was inferred from how the files look, applied to
# markdown, which that same document explicitly exempts, and never once
# checked against what it says.
set -eo pipefail
cd "${1:-$(dirname "$0")/..}"

python3 - <<'PY'
import glob
import io
import os
import re
import sys

LIMIT = 120
# Same-line quoted runs. A line is long for a reason somebody chose only
# after what a literal contributes is taken out of it.
QUOTED = re.compile(r"'[^']*'|\"[^\"]*\"")
TRIPLE = re.compile(r'"""|\'\'\'')

# What a person writes and could have written narrower. The hooks are shell
# without the extension to say so, and ci/pre-commit is the one that ships
# into every target. JSON is not here: both files of it in this repository
# are written by tools/srs_init.py, and the limit does not govern what the
# tools print (FR-CI-100). Markdown is not here either, for its own reason.
SOURCES = (glob.glob("tools/*.py") + glob.glob("tools/*.sh")
           + glob.glob("tests/*.sh") + glob.glob("ci/*.yml")
           + glob.glob(".github/workflows/*.yml")
           + [p for p in ("ci/pre-commit", ".githooks/pre-commit")
              if os.path.exists(p)])

bad = []
for path in sorted(SOURCES):
    inside = False
    for num, line in enumerate(io.open(path, encoding="utf-8"), 1):
        line = line.rstrip("\n")
        was_inside = inside
        # A Python triple-quoted block is literal throughout, so every line
        # of it is exempt — that is where the viewer keeps the CSS it emits,
        # and a marker inside a declaration would change the bytes it ships.
        if path.endswith(".py") and len(TRIPLE.findall(line)) % 2:
            inside = not inside
        if len(line) <= LIMIT or was_inside or inside:
            continue
        if len(QUOTED.sub("''", line)) > LIMIT:
            bad.append((path, num, len(line)))

for path, num, width in bad:
    sys.stderr.write(
        "line-width: %s:%d is %d columns wide, and none of it is a string "
        "literal — split it (CONTRIBUTING.md, Ground rules)\n"
        % (path, num, width))
if bad:
    sys.exit(1)
sys.stdout.write("line-width: no code line is wider than %d columns for a "
                 "reason anybody chose\n" % LIMIT)
PY
