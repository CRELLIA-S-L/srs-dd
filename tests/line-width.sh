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
import re
import sys

LIMIT = 120
# Same-line quoted runs. A line is long for a reason somebody chose only
# after what a literal contributes is taken out of it.
QUOTED = re.compile(r"'[^']*'|\"[^\"]*\"")
TRIPLE = re.compile(r'"""|\'\'\'')

bad = []
for path in sorted(glob.glob("tools/*.py") + glob.glob("tools/*.sh")
                   + glob.glob("tests/*.sh")):
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
