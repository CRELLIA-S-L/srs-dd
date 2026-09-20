---
# A measurement lands: the procedure reads the hypothesis with its tool,
# names it as printed, judges the value against the threshold rather than
# the magnitude, and appends nothing without being asked.
procedure: srs-bet
max_turns: 20
check: skill srs-bet
check: ran python3 tools/srs_grounds.py
check: answer H-030 — Specified documents stay current \(grounds/11-h-documentation\.md, assumed\)
check: answer supported
check: no_tool Edit
check: no_tool Write
---
A measurement has come in for the hypothesis about specified documents staying current: over the four releases since it was written, exactly one claim on the landing page was corrected after a release. Following the project's procedure for the grounds register, say what row you would append to its evidence table and what verdict it carries, and which requirements stand on it. Write nothing to any file.
