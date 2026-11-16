# AGENTS.md

Agent instructions for this repo. The machine-wide ones live in
[home-manager/agents/agents.md](../home-manager/agents/agents.md) and apply here
too.

## Agent config

- `.agents/` is the source of truth for this repo's agent config, following the
  [dotagents](https://github.com/bgreenwell/dotagents) layout. Instructions go
  in `.agents/agents.md`; skills, when there are any, in `.agents/skills/`.
- Every other path a tool looks in is a relative symlink into `.agents/`, never
  a copy. `AGENTS.md` and `.claude/CLAUDE.md` both link to `.agents/agents.md`.
  Add a link the same way when another tool needs its own path.
- `home-manager/agents/` is the machine-wide equivalent: user-level agent
  instructions and each AI tool's user config. `common.nix` and `home.nix` link
  them into `$HOME`.
- Nested `AGENTS.md` files are fine, and load when work touches their
  directory. Keep each one about its own directory.
