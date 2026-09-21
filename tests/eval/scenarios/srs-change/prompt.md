---
# Before changing behaviour: the procedure asks for the requirements behind
# the files, from the tools, and a report that names them as printed.
procedure: srs
max_turns: 30
check: skill srs
check: ran python3 tools/srs_view.py --code
check: answer FR-VIEW-240 — A citation is printed, not typed \(specs/10-fr-view\.md, implemented\)
check: no_tool Edit
check: no_tool Write
---
I want `python3 tools/srs_view.py --cite` to print the requirement's `created` date after its status. Do everything the project's procedure asks *before* code is changed, then stop: report which requirements govern this change and what you would edit. Do not edit any file.
