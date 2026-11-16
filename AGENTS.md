# AGENTS.md

Agent instructions for this repo. The machine-wide ones live in
[home-manager/claude/AGENTS.md](home-manager/claude/AGENTS.md) and apply here
too.

## Instruction files

- Agent instructions go in a file named `AGENTS.md`. Every tool reads that
  name; `CLAUDE.md` is Claude Code's alone.
- Don't add a `CLAUDE.md` next to an `AGENTS.md`. Claude Code loads a project's
  `AGENTS.md` only when the project has no `CLAUDE.md` of its own, so adding
  one hides the file every other tool reads.
- Where a tool insists on its own name, link it to an `AGENTS.md` rather than
  copying the content. `~/.claude/CLAUDE.md` is the only user-level file Claude
  Code reads, and `common.nix` links it to the machine-wide `AGENTS.md`.
- Nested `AGENTS.md` files are fine, and load when work touches their
  directory. Keep each one about its own directory.
