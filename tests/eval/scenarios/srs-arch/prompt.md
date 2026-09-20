---
# A question about the parts: the procedure reads the layer with its tool and
# names the element as the tool prints it.
procedure: srs-arch
max_turns: 20
check: skill srs-arch
check: ran python3 tools/srs_arch.py
check: answer E-050 — The grounds layer \(arch/00-elements\.md, built\)
check: no_tool Edit
check: no_tool Write
---
Which element of the architecture layer carries `tools/srs_grounds.py`, what does that element answer for, and what would the architecture checker report if `grounds/README.md` were moved out of it into `docs/`? Follow the project's procedure for the architecture layer; change nothing.
