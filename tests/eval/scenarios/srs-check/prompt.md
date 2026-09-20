---
# After a change: name exactly the checks the touched requirements call for,
# read from their fields, and run no suite unasked.
procedure: srs-check
max_turns: 20
check: skill srs-check
check: ran python3 tools/srs_view.py
check: answer tests/arch-rules\.sh
check: answer FR-ARCH-260 — Edges the project supplies are compared as the ones the checker reads \(specs/10-fr-arch\.md, implemented\)
check: not_ran (^|[;&|]\s*)(bash |sh |\./)?tests/\S+\.sh
check: not_ran ci_selftest
---
A change to `tools/srs_arch.py` has just been finished: it reads `arch/edges.json` and compares the edges with the declared model. Following the project's procedure for a finished change, name the checks this change calls for and offer them — do not run any test suite yourself.
