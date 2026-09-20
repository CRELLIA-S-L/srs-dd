---
# The survey step of a harvest: the procedure reads the configuration and
# the areas from the tools, proposes a map and an order, and writes nothing —
# a batch is shown before it is written, and this run stops before a batch.
procedure: srs-harvest
max_turns: 20
check: skill srs-harvest
check: ran python3 tools/srs_view.py
check: answer (?s)VIEW.*CHK|CHK.*VIEW
check: answer srs_view\.py
check: no_tool Edit
check: no_tool Write
---
Suppose the tools under `tools/` had no requirements yet and you were asked to mine a specification from them. Do the survey step of the project's harvesting procedure only: say which files map to which of the project's declared areas and in what order you would work, and stop before drafting any requirement. Write nothing to any file.
