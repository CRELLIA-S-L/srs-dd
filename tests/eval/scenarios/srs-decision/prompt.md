---
# A change that needs an algorithm its requirement does not dictate: the
# procedure asks the agent to name the way it would take as a decision for
# specs/adr/, not to leave it in the code — without writing anything.
procedure: srs
max_turns: 30
check: skill srs
check: ran python3 tools/srs_view.py
check: answer (specs/adr|ADR|decision)
check: answer (edit distance|Levenshtein|typo|one (letter|character))
check: no_tool Edit
check: no_tool Write
---
I want `python3 tools/srs_view.py --grep WORD` to find a word even when it is misspelled by one letter. Go through what the project's procedure asks, from before the code down to what you would record when the loop is closed, then stop and report what you would write and where. Do not edit any file.
