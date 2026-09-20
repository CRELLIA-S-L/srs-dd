#!/usr/bin/env bash
# tools/srs_proc_eval.py reads every shipped scenario and holds its
# expectations to the specification as it stands, accounts the tokens of a
# run from the per-turn usage the client reports, scores the checks off the
# trace exactly, refuses a malformed scenario before anything runs, and
# stops where there is no agent to ask. The suite asks nobody: the live run
# is a measurement for whoever changes a procedure, never a gate.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# verifies: FR-SKILL-310
# --- Every shipped scenario parses, names a procedure that ships, checks
# --- that its procedure was invoked, and expects only what the project
# --- prints today: a citation in an `answer` check matches what --cite
# --- prints for that record now, and an identifier the scenario assumes
# --- free is one the specification does not carry. Without this a
# --- scenario fails for the specification having moved, not the procedure.
python3 - <<'PY'
import os, re, subprocess, sys
sys.path.insert(0, "tools")
import srs_proc_eval as e

scenarios, problem = e.read_scenarios()
assert problem is None, problem
assert len(scenarios) >= 4, "fewer than four scenarios ship: %d" % len(scenarios)
TOOL = {"E": "srs_arch.py", "H": "srs_grounds.py", "B": "srs_grounds.py", "U": "srs_grounds.py"}
RE_CITED = re.compile(r"((?:FR|NFR|IF|INV|CON)-[A-Z0-9]+-\d{3,}|ADR-\d{4}|[EHBU]-\d{3,}) — ")
for s in scenarios:
    assert any(k == "skill" and a == s["procedure"] for k, a in s["checks"]), \
        "%s does not check that its procedure `%s` was invoked" % (s["name"], s["procedure"])
    for rid in s["free"]:
        run = subprocess.run([sys.executable, "tools/srs_view.py", "--cite", rid], capture_output=True, text=True)
        assert run.returncode == 1 and not run.stdout.strip(), \
            "%s assumes %s is free and the specification carries it: %s" % (s["name"], rid, run.stdout.strip())
    for kind, argument in s["checks"]:
        if kind != "answer":
            continue
        for rid in RE_CITED.findall(argument):
            tool = TOOL.get(rid.split("-")[0], "srs_view.py")
            run = subprocess.run([sys.executable, "tools/" + tool, "--cite", rid], capture_output=True, text=True)
            assert run.returncode == 0, "%s expects %s, which no tool cites: %s" % (s["name"], rid, run.stderr.strip())
            assert re.search(argument, run.stdout.strip()), \
                "%s expects `%s`, and %s prints `%s`" % (s["name"], argument, tool, run.stdout.strip())
print("proc-eval: %d scenarios read; every citation and every free number they expect holds today" % len(scenarios))
PY

# --- Two canned traces for one scenario, built the way the client reports a
# --- run: one that follows the procedure, one that edits instead. The floor
# --- is the first turn's context, what the run added is the last turn's
# --- beyond it, the procedure's size is the one the trace carries — the
# --- file as it was when the run was taken — or the file's where a trace
# --- carries none, and the checks read the trace and the answer, nothing
# --- else.
CANNED=$(mktemp)
python3 - > "$CANNED" <<'PY'
import json
def turn(created, read, out, fresh=2):
    return {"input_tokens": fresh, "cache_creation_input_tokens": created,
            "cache_read_input_tokens": read, "output_tokens": out}
good = {"tools": [{"name": "Skill", "input": {"skill": "srs-arch"}},
                  {"name": "Bash", "input": {"command": "python3 tools/srs_arch.py --cite E-050"}}],
        "turns": [turn(20000, 0, 10), turn(1500, 20000, 40), turn(300, 21500, 200)],
        "answer": "It is E-050 — The grounds layer (arch/00-elements.md, built), which answers for the register.",
        "cost_usd": 0.25, "num_turns": 3, "stop": "success", "is_error": False,
        "procedure_size": {"words": 999, "bytes": 6000}}
bad = {"tools": [{"name": "Edit", "input": {"file_path": "arch/00-elements.md"}}],
       "turns": [turn(20000, 0, 60)],
       "answer": "I moved it; E-050 carries grounds.",
       "cost_usd": 0.10, "num_turns": 1, "stop": "error_max_turns", "is_error": False}
print(json.dumps({"scenario": "srs-arch", "run": 1, "trace": good}))
print(json.dumps({"scenario": "srs-arch", "run": 2, "trace": bad}))
print(json.dumps({"scenario": "no-such-scenario", "run": 1, "trace": bad}))
PY
WORDS=$(wc -w < .claude/skills/srs-arch/SKILL.md | tr -d ' ')
python3 tools/srs_proc_eval.py --score "$CANNED" --only srs-arch --json /tmp/srs-proc-eval.json > /tmp/srs-proc-eval.out
# floor 20002; end 300 + 21500 + 2 = 21802; added 1800; out 250;
# burned = 21800 created + 41500 read + 6 fresh + 250 out = 63556.
grep -q '^srs-arch       run 1  floor  20002  added   1800  burned    63556  out   250  turns  3  checks 5/5$' /tmp/srs-proc-eval.out \
    || { echo "proc-eval: the good run is not accounted as floor 20002, added 1800, burned 63556, out 250, 5/5"; cat /tmp/srs-proc-eval.out; exit 1; }
grep -q '^srs-arch       run 2  floor  20002  added      0  burned    20062  out    60  turns  1  checks 1/5  stopped: error_max_turns$' /tmp/srs-proc-eval.out \
    || { echo "proc-eval: the bad run is not scored 1 of 5 with nothing added and its stop reason beside it"; cat /tmp/srs-proc-eval.out; exit 1; }
grep -q "failed: skill srs-arch" /tmp/srs-proc-eval.out && grep -q "failed: no_tool Edit" /tmp/srs-proc-eval.out \
    && grep -q "failed: answer E-050 — The grounds layer" /tmp/srs-proc-eval.out \
    && grep -q "failed: ran python3 tools/srs_arch.py" /tmp/srs-proc-eval.out \
    || { echo "proc-eval: the bad run's failed checks are not the ones expected"; cat /tmp/srs-proc-eval.out; exit 1; }
grep -q "^srs-arch       2 run(s)  procedure srs-arch $WORDS/999 words  added    900  burned    41809  checks met 6 of 10$" /tmp/srs-proc-eval.out \
    || { echo "proc-eval: the per-scenario summary is not the mean of the two runs, naming both sizes the runs were taken under"; cat /tmp/srs-proc-eval.out; exit 1; }
grep -q "no-such-scenario" /tmp/srs-proc-eval.out && { echo "proc-eval: a saved run of no scenario was scored"; exit 1; }
python3 - "$WORDS" <<'PY' || { echo "proc-eval: the JSON report disagrees with the text"; exit 1; }
import json, sys
rows = json.load(open("/tmp/srs-proc-eval.json"))["runs"]
assert len(rows) == 2
assert rows[0]["tokens"] == {"floor": 20002, "end": 21802, "added": 1800, "output": 250,
                             "cache_created": 21800, "cache_read": 41500, "input": 6,
                             "burned": 63556}, rows[0]["tokens"]
assert rows[0]["procedure"] == "srs-arch" and rows[0]["procedure_size"]["words"] == 999, rows[0]["procedure_size"]
assert rows[1]["procedure_size"]["words"] == int(sys.argv[1]), rows[1]["procedure_size"]
assert [c["passed"] for c in rows[1]["checks"]] == [False, False, False, False, True], rows[1]["checks"]
assert rows[0]["stop"] == "success" and rows[1]["stop"] == "error_max_turns", (rows[0]["stop"], rows[1]["stop"])
PY
echo "proc-eval: canned traces are accounted and scored exactly, and the procedure's size is the file's"

# --- A malformed scenario is refused before anything runs, with the fault
# --- named: a check of an unknown kind, a missing procedure, a procedure
# --- that does not ship, a max_turns that is not a number, no checks.
BROKEN=$(mktemp -d)
python3 - "$BROKEN" <<'PY' || { echo "proc-eval: a malformed scenario was accepted"; exit 1; }
import os, sys
sys.path.insert(0, "tools")
import srs_proc_eval as e
cases = {
    "shouted": ("---\nprocedure: srs\ncheck: shouted LOUD\n---\nDo.\n", "kinds are"),
    "noproc": ("---\ncheck: skill srs\n---\nDo.\n", "no `procedure:`"),
    "ghost": ("---\nprocedure: srs-ghost\ncheck: skill srs-ghost\n---\nDo.\n", "does not ship"),
    "turns": ("---\nprocedure: srs\nmax_turns: many\ncheck: skill srs\n---\nDo.\n", "max_turns"),
    "nocheck": ("---\nprocedure: srs\n---\nDo.\n", "no `check:`"),
    "noprompt": ("---\nprocedure: srs\ncheck: skill srs\n---\n\n", "no prompt"),
    "key": ("---\nprocedure: srs\ncolour: blue\ncheck: skill srs\n---\nDo.\n", "unknown header key"),
}
for name, (text, expected) in cases.items():
    directory = os.path.join(sys.argv[1], name)
    os.makedirs(directory)
    open(os.path.join(directory, "prompt.md"), "w").write(text)
    scenario, problem = e.read_scenario(directory)
    assert scenario is None and expected in problem, (name, problem)
PY
echo "proc-eval: a malformed scenario is refused with the fault named"

# --- Where no agent client is on the path the command says so and exits 2,
# --- rather than reporting a measurement nobody took.
EMPTY=$(mktemp -d)
ln -s "$(command -v python3)" "$EMPTY/python3"
set +e
PATH="$EMPTY" python3 tools/srs_proc_eval.py > /tmp/srs-proc-eval-noclient.out 2>&1
status=$?
set -e
[ "$status" -eq 2 ] && grep -q 'no `claude` on the path' /tmp/srs-proc-eval-noclient.out \
    || { echo "proc-eval: without a client the command did not stop with exit 2 (got $status)"; cat /tmp/srs-proc-eval-noclient.out; exit 1; }
echo "proc-eval: without an agent client the command stops and says so"
