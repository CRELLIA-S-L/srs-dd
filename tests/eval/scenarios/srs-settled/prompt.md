---
# A rule is settled in passing while a change is discussed: the guide asks
# the agent to notice that nothing states it and to offer the requirement,
# naming what it would oblige and its area — without writing anything.
procedure: srs
max_turns: 30
check: skill srs
check: ran python3 tools/srs_view.py
check: answer (no requirement|nothing (states|says)|not (yet )?(described|specified|written)|missing requirement|no existing requirement)
check: answer SKILL
check: answer (measured over|what it measured|the set)
check: no_tool Edit
check: no_tool Write
---
Two things. First: I want `python3 tools/srs_check.py` to print how long the run took, in milliseconds, on its last line. Second, a house rule from now on, for this project and every project built on it — whenever a procedure reports a number it measured, it says what it measured over, so a count is never read against the wrong set. Do what the project's procedure asks before any code is changed, then stop and report. Do not edit any file.
