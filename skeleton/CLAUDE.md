# <Your Project Name>

Read `AGENTS.md` first — the shared agent guide for this SRS-DD project.

Claude-specific additions:

- **Invoke the `srs` skill** before any code change that alters behavior,
  and when planning a task — it also covers multi-requirement plans.
- To author a new requirement through a dialog, use the `srs-new` skill;
  to audit spec ↔ code drift and test adequacy, use `srs-audit`.
- To pick up a new framework version, use the `srs-upgrade` skill — one
  command, no framework clone to keep around.
