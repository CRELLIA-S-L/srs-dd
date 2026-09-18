# SRS-DD framework repository

`AGENTS.md` is the agent guide for this repository, and it is imported here so that every session starts with it in front of you rather than behind a pointer:

@AGENTS.md

It explains that this is the framework itself rather than a project using it, where the payload (`skeleton/`) ends and the framework begins, and the two rules that keep framework content out of other people's repositories.

Claude-specific additions:

- **Invoke the `srs` skill** before any code change that alters behavior of the checker, the viewer or the installer, when planning a task, and when the question is how this repository works rather than a change to it — it is itself an SRS-DD project.
- To set SRS-DD up in another repository, use the `srs-init` skill; it is available only here and is never copied into targets.
- To author a new requirement through a dialog, use `srs-new`; to audit spec ↔ code drift, test adequacy and the links between requirements, use `srs-audit`.
- To freeze the specification at a milestone, use `srs-baseline`; to cut a release of the framework, `srs-release`.
  They are separate acts with separate numbers, and neither command commits or tags — that is left to the git client this repository is driven by.
