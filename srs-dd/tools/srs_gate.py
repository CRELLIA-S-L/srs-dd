#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# SRS-DD-VERSION — the framework release this file came from
# implements: FR-INIT-280
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# srs-end: FR-INIT-280
"""The specification gate — what the pre-commit hook and the pipeline run.

    python3 srs-dd/tools/srs_gate.py            check, regenerate, compare
    python3 srs-dd/tools/srs_gate.py --staged   the same, then the register's
                                         report on what the commit touches
    python3 srs-dd/tools/srs_gate.py --strict   warnings fail the checkers too

The checker runs, and where the project keeps them the grounds register's
and the architecture layer's checkers, each regenerating the file it
writes. Every file is regenerated before any is compared, and the gate
fails naming every one that differs from what git holds for it, or that
git does not hold at all. In a pipeline what git holds is the commit; in
the hook it is what is staged — one comparison serves both.

Exit codes: 0 passed · 1 a checker failed or a generated file is stale ·
2 could not run, or a checker could not.
"""

# file implements: NFR-SPEC-010, CON-SPEC-030

import os
import subprocess
import sys

sys.dont_write_bytecode = True

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# implements: FR-CI-180
# (checker, the file it writes, the configuration that says the project
# keeps it — None for the specification, which every project keeps). The
# one list of what the gate compares byte for byte, which is also what
# the shipped .gitattributes has to pin to LF.
GENERATED = (
    ("srs-dd/tools/srs_check.py", "specs/90-traceability.md", None),
    ("srs-dd/tools/srs_grounds.py", "grounds/90-dashboard.md", "grounds/grounds-config.json"),
    ("srs-dd/tools/srs_arch.py", "arch/90-map.md", "arch/arch-config.json"),
)
# srs-end: FR-CI-180


def git(*args):
    return subprocess.run(["git"] + list(args), cwd=ROOT,
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)


# implements: FR-CI-010, FR-CI-020, FR-GND-370, FR-GND-570, FR-ARCH-170, FR-ARCH-300
def stale(path):
    """Whether what git holds for a generated file is not what was just
    written: git does not hold it, or the copy on disk differs from the
    one git holds — the index, which in a fresh checkout is the commit."""
    if git("ls-files", "--error-unmatch", "--", path).returncode != 0:
        return True
    return git("diff", "--quiet", "--", path).returncode != 0


def run_gate(strict, show):
    """Runs every checker the project keeps, then compares every file they
    wrote. A checker that fails stops the gate with its exit code, as it
    would have stopped the pipeline's step."""
    compared = []
    for checker, written, config in GENERATED:
        if config and not os.path.isfile(os.path.join(ROOT, config)):
            continue
        command = [sys.executable, checker] + (["--strict"] if strict else [])
        code = subprocess.run(command, cwd=ROOT).returncode
        if code != 0:
            return code
        compared.append(written)
    found = [path for path in compared if stale(path)]
    for path in found:
        # A pipeline's log is read after the fact, and the difference is
        # what says whether the file is stale or the checker changed.
        if show:
            subprocess.run(["git", "--no-pager", "diff", "--", path], cwd=ROOT)
        sys.stderr.write("srs_gate.py: %s was regenerated and differs from what git holds — "
                         "stage it and commit again.\n" % path)
    return 1 if found else 0
# srs-end: FR-CI-010, FR-CI-020, FR-GND-370, FR-GND-570, FR-ARCH-170, FR-ARCH-300


# implements: FR-GND-310
def report_staged():
    """What the requirements this commit touches are staked on. A report
    and never a verdict: a refuted hypothesis is not the committer's fault
    and may be what they are repairing, so nothing here fails the commit.
    Every staged file counts, not only the specification — a requirement
    owns the files its `code` and `tests` fields name."""
    if not os.path.isfile(os.path.join(ROOT, "grounds", "grounds-config.json")):
        return
    listing = git("diff", "--cached", "--name-only", "-z", "--diff-filter=ACM")
    paths = [p for p in listing.stdout.decode("utf-8", "replace").split("\0") if p]
    if paths:
        subprocess.run([sys.executable, "srs-dd/tools/srs_grounds.py", "--blast"] + paths, cwd=ROOT)
# srs-end: FR-GND-310


def main(argv):
    flags = set(argv)
    unknown = sorted(flags - {"--staged", "--strict"})
    if unknown:
        sys.stderr.write("srs_gate.py: unknown flag %s — usage: python3 srs-dd/tools/srs_gate.py "
                         "[--staged] [--strict]\n" % " ".join(unknown))
        return 2
    if git("rev-parse", "--is-inside-work-tree").returncode != 0:
        sys.stderr.write("srs_gate.py: this is not a git repository, and the gate compares "
                         "what the checkers write with what git holds.\n")
        return 2
    code = run_gate("--strict" in flags, show="--staged" not in flags)
    if code == 0 and "--staged" in flags:
        report_staged()
    return code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
