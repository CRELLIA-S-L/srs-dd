# SRS-DD framework repository

Read `AGENTS.md` first — the agent guide for this repository. It explains
that this is the framework itself rather than a project using it, where the
payload (`skeleton/`) ends and the framework begins, and the two rules that
keep framework content out of other people's repositories.

Claude-specific additions:

- **Invoke the `srs` skill** before any code change that alters behavior of
  the checker, the viewer or the installer, and when planning a task — this
  repository is itself an SRS-DD project.
- To set SRS-DD up in another repository, use the `srs-init` skill; it is
  available only here and is never copied into targets.
- To author a new requirement through a dialog, use `srs-new`; to audit
  spec ↔ code drift and test adequacy, use `srs-audit`.
