---
# Authoring: type, area, the next free number, a statement in the lexicon's
# form, a method, and what is already written — without writing the file.
procedure: srs-new
max_turns: 24
free: FR-VIEW-390
check: skill srs-new
check: ran python3 tools/srs_view.py
check: answer FR-VIEW-390
check: answer \*\*shall\*\*
check: answer FR-VIEW-240 — A citation is printed, not typed \(specs/10-fr-view\.md, implemented\)
check: no_tool Edit
check: no_tool Write
---
Draft a new requirement, without writing it to any file: the viewer's `--cite` refuses an identifier whose area is written in lowercase and says so. Follow the project's authoring procedure and report what you would write — type, area, the next free number, the statement, the verification method, the links to what is already written — and stop before the file.
