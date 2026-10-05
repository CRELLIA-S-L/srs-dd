#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# SRS-DD-VERSION — the framework release this file came from
# implements: FR-INIT-280
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
# srs-end: FR-INIT-280
"""The architecture document: what the layer holds, written for a person to read.

    python3 srs-dd/tools/srs_arch_doc.py              print the document
    python3 srs-dd/tools/srs_arch_doc.py > ARCH.md    put it where you want it

A projection of `arch/` and of what the specification says about it — the parts with their
responsibilities and obligations, the dependencies they declare as a Mermaid drawing, the
dependencies the code has and they do not, and what the layer leaves unsaid. It writes
nothing: where the document lands is the caller's.

Not a gate: the checker says what is wrong with the layer, this says what the layer holds.
Standard library only, compatible with Python 3.9.
"""
# file implements: FR-ARCH-410, CON-ARCH-010
# file implements: NFR-SPEC-010, CON-SPEC-030, INV-SPEC-090
import os
import sys

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
try:
    import srs_arch
except ImportError:
    sys.stderr.write("srs-dd/tools/srs_arch.py is not beside this file; the document is a "
                     "projection of what it reads\n")
    sys.exit(2)

__version__ = srs_arch.__version__


def in_force(elements):
    """The elements a reader is being told about: well-formed, and not dissolved."""
    return [r for r in elements if srs_arch.RE_ID.match(r.id)
            and r.fields.get("status") not in srs_arch.CANCELLED]


def responsibility(record):
    """The record's own sentence about what the part is for: its body down to the rationale."""
    out = []
    for line in record.body:
        if line.strip().startswith("**Rationale."):
            break
        out.append(line.strip())
    return " ".join(part for part in out if part)


# implements: FR-ARCH-420
def parts_section(elements, moves, model, cfg):
    """Every element in force: what it is, what it carries, what it answers for, what moves."""
    titles = {r["id"]: r.get("title", "") for r in model["requirements"]}
    written, computed = srs_arch.carried_by(elements, model, cfg)
    order = srs_arch.spec_order(model)
    out = ["## What the system is made of", ""]
    # implements: FR-ARCH-460
    if not in_force(elements):
        return out + ["_No part is written down yet: the layer is installed and empty._", ""]
    # srs-end: FR-ARCH-460
    for record in sorted(elements, key=lambda r: srs_arch.srs_parse.id_key(r.id)):
        if record.fields.get("status") in srs_arch.CANCELLED:
            continue
        out += ["### %s — %s" % (record.id, record.title), "",
                "%s" % (responsibility(record) or "_Not determined: the record says nothing._"), "",
                "- **Status:** `%s`" % (record.fields.get("status") or "?")]
        carries = srs_arch.as_list(record.fields.get("carries"))
        out.append("- **Carries:** %s" % (", ".join("`%s`" % p for p in carries) or "_nothing_"))
        interface = record.fields.get("interface")
        out.append("- **Interface:** %s" % (interface or "_Not determined._"))
        # implements: FR-ARCH-510
        # The two or three a part was cut to keep, before the forty it merely carries: this is
        # the answer to what breaks if the boundary moves. Absent where the record names none.
        protects = srs_arch.as_list(record.fields.get("protects"))
        if protects:
            out.append("- **Exists to protect:**")
            for rid in sorted(protects, key=order):
                out.append("  - %s — %s" % (rid, titles.get(rid, "_unknown to the specification_")))
        # srs-end: FR-ARCH-510
        held = sorted(written[record.id] | computed[record.id], key=order)
        out.append("- **Answers for %d requirement(s):**" % len(held))
        for rid in held:
            out.append("  - %s — %s" % (rid, titles.get(rid, "_unknown to the specification_")))
        touching = [m for m in moves
                    if record.id in srs_arch.as_list(m.fields.get("from"))
                    + srs_arch.as_list(m.fields.get("to"))]
        for move in touching:
            out.append("- **Moving:** %s — %s (`%s`)"
                       % (move.id, move.title, move.fields.get("status") or "?"))
        out.append("")
    return out
# srs-end: FR-ARCH-420


# implements: FR-ARCH-430
def drawing_section(elements):
    """The declared dependencies as Mermaid: text a forge, an editor or a wiki renders itself."""
    live = in_force(elements)
    declared = srs_arch.declared_dependencies(elements)
    out = ["## How the parts depend on each other", ""]
    # implements: FR-ARCH-460
    # No block at all rather than one holding its own declaration: a forge renders that as an
    # error, which reads as a broken generator.
    if not live:
        return out + ["_Nothing to draw: no part is written down yet._", ""]
    # srs-end: FR-ARCH-460
    out += ["What the elements declare, not what the code does — the two are compared below.", "",
            "```mermaid", "flowchart TD"]
    for record in sorted(live, key=lambda r: srs_arch.srs_parse.id_key(r.id)):
        out.append('    %s["%s %s"]' % (record.id.replace("-", "_"), record.id, record.title))
    edges = 0
    for record in sorted(live, key=lambda r: srs_arch.srs_parse.id_key(r.id)):
        for target in sorted(declared.get(record.id, ()), key=srs_arch.srs_parse.id_key):
            out.append("    %s --> %s" % (record.id.replace("-", "_"), target.replace("-", "_")))
            edges += 1
    out += ["```", "",
            "%d part(s), %d declared dependency(ies)." % (len(live), edges), ""]
    return out
# srs-end: FR-ARCH-430


# implements: FR-ARCH-440
def divergence_section(elements, edges, cfg):
    """Where the code disagrees with the model, from the checker's own computation."""
    warnings, reports = [], []
    quiet = dict(cfg)
    quiet["rules"] = dict(cfg["rules"])
    quiet["rules"]["dependency-undeclared"] = "warn"
    srs_arch.check_conformance(elements, edges, warnings, reports, quiet)
    out = ["## Where the code disagrees with the model", ""]
    # implements: FR-ARCH-460
    # The absence of a verdict is not a verdict: with no part written down there is nothing to
    # compare the code against, and saying "everything is declared" would read as one.
    if not in_force(elements):
        return out + ["_Nothing to compare: no part is written down yet._", ""]
    # srs-end: FR-ARCH-460
    if warnings or reports:
        out.append("A dependency the code has and no element declares:")
        out.append("")
        for text in warnings + reports:
            out.append("- %s" % text)
    else:
        out.append("Nothing: every dependency the checker can read is declared.")
    out.append("")
    return out
# srs-end: FR-ARCH-440


# implements: FR-ARCH-450
def silences_section(elements, model, cfg):
    """What the layer leaves unsaid, named rather than left to read as absence of a problem."""
    written, computed = srs_arch.carried_by(elements, model, cfg)
    claimed = set()
    carried = set()
    for record in elements:
        if not srs_arch.RE_ID.match(record.id):
            continue
        if record.fields.get("status") in srs_arch.CANCELLED:
            continue
        claimed |= written[record.id] | computed[record.id]
        if record.fields.get("status") not in srs_arch.DESIGNED:
            for path in srs_arch.as_list(record.fields.get("carries")):
                carried.add(path.rstrip("/"))
    out = ["## What nobody has said", ""]
    silent = [r.id for r in sorted(elements, key=lambda r: srs_arch.srs_parse.id_key(r.id))
              if srs_arch.RE_ID.match(r.id)
              and r.fields.get("status") not in srs_arch.CANCELLED
              and not r.fields.get("interface")]
    out.append("- **Parts that declare no interface:** %s"
               % (", ".join(silent) if silent else "_none_"))
    unassigned = [r["id"] for r in model["requirements"]
                  if r.get("status") in srs_arch.APPROVED and r["id"] not in claimed]
    out.append("- **Approved requirements no part answers for:** %s"
               % (", ".join(unassigned) if unassigned else "_none_"))
    unowned = []
    for requirement in model["requirements"]:
        if requirement.get("status") not in srs_arch.REALIZED:
            continue
        for path in (requirement.get("code") or []):
            if srs_arch.owner_of(path, carried) is None and path not in unowned:
                unowned.append(path)
    out.append("- **Files of a realized requirement no part carries:** %s"
               % (", ".join("`%s`" % p for p in unowned) if unowned else "_none_"))
    out.append("")
    return out
# srs-end: FR-ARCH-450


# implements: FR-ARCH-410
def render(elements, moves, model, edges, cfg):
    """The whole document, in the order a reader's questions arise."""
    live_moves = [m for m in moves if srs_arch.RE_MOVE.match(m.id)
                  and m.fields.get("status") not in srs_arch.MOVE_CLOSED]
    out = ["# Architecture", "",
           "What this project is made of, projected from `arch/` and from what `specs/` says "
           "about it by `srs-dd/tools/srs_arch_doc.py` (srs-dd %s). Generated: do not edit — "
           "edit the records and print it again." % __version__, ""]
    out += parts_section(elements, live_moves, model, cfg)
    out += drawing_section(elements)
    out += divergence_section(elements, edges, cfg)
    out += silences_section(elements, model, cfg)
    out += ["## Where this comes from", "",
            "- The parts, their responsibilities and the moves: the records in `arch/`",
            "- The requirements and their titles: the specification, through "
            "`srs-dd/tools/srs_view.py --json`",
            "- The disagreement with the code: the architecture checker's own reading",
            ""]
    return "\n".join(out)
# srs-end: FR-ARCH-410


# implements: FR-ARCH-410
def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    if args:
        sys.stderr.write("unknown flag(s): %s\nusage: srs_arch_doc.py            "
                         "(the document goes to stdout)\n" % " ".join(args))
        return 2
    if not os.path.isdir(srs_arch.ARCH):
        sys.stderr.write("arch/ directory not found: %s\nThe architecture layer is optional; "
                         "install it with tools/srs_init.py --arch yes.\n" % srs_arch.ARCH)
        return 2
    cfg, problem = srs_arch.load_config()
    if problem:
        sys.stderr.write("%s\n" % problem)
        return 2
    model, problem = srs_arch.read_model()
    if problem:
        sys.stderr.write("%s\n" % problem)
        return 2
    edges, problem = srs_arch.load_edges()
    if problem:
        sys.stderr.write("%s\n" % problem)
        return 2
    unread = []
    elements, moves = srs_arch.partition(srs_arch.read_records(unread), unread)
    if unread:
        sys.stderr.write("%d record(s) could not be read and are not in this document; the "
                         "checker names them.\n" % len(unread))
    sys.stdout.write(render(elements, moves, model, edges, cfg) + "\n")
    return 0
# srs-end: FR-ARCH-410


if __name__ == "__main__":
    sys.exit(main())
