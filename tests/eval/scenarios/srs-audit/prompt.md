---
# Test adequacy for one requirement: the procedure derives the cases from
# the statement, maps them against the listed suite, names the requirement
# as printed, and runs nothing.
procedure: srs-audit
max_turns: 24
check: skill srs-audit
check: ran python3 tools/srs_view.py
check: answer FR-VIEW-240 — A citation is printed, not typed \(specs/10-fr-view\.md, implemented\)
check: answer (?i)uncovered|covered
check: answer tests/view-smoke\.sh
check: not_ran (^|[;&|]\s*)(bash |sh |\./)?tests/\S+\.sh
check: not_ran ci_selftest
check: no_tool Edit
check: no_tool Write
---
Audit the test adequacy of the requirement that says a citation is printed rather than typed: derive the test cases its statement implies, map them against what its listed suite actually asserts, and report which are covered, partial or uncovered — for each covered case, name the change to the code that would turn the test red. Follow the project's audit procedure. Run no tests and change nothing.
