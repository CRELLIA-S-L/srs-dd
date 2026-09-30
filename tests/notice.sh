#!/usr/bin/env bash
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# The notice gate: every file of code this repository keeps says whose it
# is and on what terms, in its first lines.
#
# file implements: FR-CI-170
# file verifies: FR-CI-170
#
# The licence covers the repository from its root, and a file lifted from
# it on its own carries nothing of that; the tools that ship are exactly
# such files (FR-INIT-280). Over the same files as the width gate, the
# starters under ci/ aside: those become a project's hook and pipeline and
# carry no notice of ours. Markdown is not looked at.
set -eo pipefail
cd "${1:-$(dirname "$0")/..}"

python3 - <<'PY'
import glob
import io
import os
import sys
import tempfile

HOLDER = "Copyright (c) 2026 CRELLIA S.L."
LICENCE = "MIT License"
HEAD = 12          # a notice sits with the shebang and the marker, not at line 300


def sources(root):
    with_root = lambda pattern: glob.glob(os.path.join(root, pattern))
    return sorted(with_root("tools/*.py") + with_root("tools/*.sh") + with_root("tests/*.sh")
                  + with_root(".github/workflows/*.yml")
                  + [p for p in (os.path.join(root, ".githooks", "pre-commit"),) if os.path.exists(p)])


def missing(root):
    found = []
    for path in sources(root):
        with io.open(path, encoding="utf-8") as handle:
            head = [next(handle, "") for _ in range(HEAD)]
        if not any(HOLDER in line and LICENCE in line for line in head):
            found.append(os.path.relpath(path, root))
    return found


# --- Negation first, on a lab: a file without the notice, one with it past
# --- the first lines, and one with it where it belongs.
lab = tempfile.mkdtemp()
os.makedirs(os.path.join(lab, "tools")); os.makedirs(os.path.join(lab, "tests"))
with open(os.path.join(lab, "tools", "bare.py"), "w") as handle:
    handle.write("#!/usr/bin/env python3\nprint(1)\n")
with open(os.path.join(lab, "tests", "late.sh"), "w") as handle:
    handle.write("#!/bin/sh\n" + "\n" * HEAD + "# %s — %s\n" % (HOLDER, LICENCE))
with open(os.path.join(lab, "tools", "said.py"), "w") as handle:
    handle.write("#!/usr/bin/env python3\n# %s — part of SRS-DD, distributed under the %s\n" % (HOLDER, LICENCE))
assert missing(lab) == ["tests/late.sh", "tools/bare.py"], missing(lab)
print("notice: a file without the notice, and one carrying it past line %d, are each red" % HEAD)

bad = missing(".")
for path in bad:
    sys.stderr.write("notice: %s does not say whose it is — add, in its first lines: "
                     "# %s — part of SRS-DD, distributed under the %s (CONTRIBUTING.md, Ground rules)\n"
                     % (path, HOLDER, LICENCE))
if bad:
    sys.exit(1)
sys.stdout.write("notice: every file of code this repository keeps names the copyright holder and the "
                 "licence in its first %d lines (%d files)\n" % (HEAD, len(sources("."))))
PY
