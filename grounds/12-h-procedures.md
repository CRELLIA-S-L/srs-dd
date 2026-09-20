# Hypotheses — procedures

What the procedures the framework ships are expected to cost the agent that follows them, once that cost is measured rather than assumed.

### H-040 — A procedure is followed within a bounded cost

```yaml
status: assumed
class: II
population: runs of a fresh agent instance through the scenarios shipped in tests/eval/scenarios of this repository, under the procedures as shipped at the release being measured
refuted_if: proportion < 0.50 at n >= 12
expires: 2026-12-19
owner: @crellia_admin
impact: the tokens every procedure run costs in every project the framework is installed in — the one number the positioning "fewer tokens, more control" can be held to
```

At least four runs in five meet every check their scenario states and add no more than twenty thousand tokens to the context beyond the session's floor — the context of the run's first turn.

**Rationale.** A procedure is read by an agent at every invocation, and what it costs was never measured: the first numbers, taken on 2026-09-19 and 2026-09-20 from three runs a scenario under the procedures of 0.18.0, put a run under the `srs` procedure at about thirty-four thousand tokens beyond the floor, under the authoring procedure at about thirty-two, under the architecture procedure at about seventeen and under the check procedure at about nine.
The claim is written in absolute terms on purpose.
A claim about a saving against 0.18.0 would have nothing to be measured against once those procedures are gone, and the rows this table collects are meant to be read release after release: a procedure that grows back is a row that crosses the line.
The floor — the context of the run's first turn, before anything is read — is subtracted because it belongs to the client and the session, not to the procedure, and it varies between clients by more than a procedure costs.

Both halves are read off the run's own trace, and neither asks a person: the checks are what the scenario states a good run leaves behind, the tokens are what the client reports per turn.
Class II rather than I because the number does not arrive on its own — somebody runs `tools/srs_proc_eval.py`, and each run costs an account and a network.

Four in five rather than every run, because a model's runs vary and a single failed run refutes nothing about the procedure; the threshold is set well below the magnitude for the same reason, so that a result between the two says the claim survived and its size was wrong.
Twelve is one call at three runs per scenario.
No frame refuses the claim: this register holds no frames, so the step is walked and finds nothing to walk against.

The claim says nothing about how the cost is held — a shorter text, a denser answer from the viewer, a section pointed at instead of a standard read whole.
Those are the interventions, they stay outside the sentence, and the rows are how they are compared.
