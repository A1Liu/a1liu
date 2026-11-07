# Agent instructions

Albert's personal config monorepo: machine setup (nix, home-manager, shell,
vim) plus the SvelteKit source for a1liu.com. `AGENTS.md` at the repo root is a
symlink to this file, which is where every agent that follows
[agents.md](https://agents.md) looks; Claude Code loads it from there too.

## Layout

| Path              | What's in it                                                                       |
| ----------------- | ---------------------------------------------------------------------------------- |
| `.agents/`        | This config. `skills/` and `USER_AGENTS.md` get linked into `~/.claude` (see below). |
| `home-manager/`   | Home Manager flake. `common.nix` is shared; `home.nix` is workstations, `vps.nix` the server. |
| `nix/`            | System-level config: `nixos/`, `darwin/`, and per-OS notes.                          |
| `shell/`          | bash and zsh config, entered through `shell/dispatch`.                               |
| `vim/`            | Vim and Neovim config.                                                               |
| `src/`, `static/` | a1liu.com, a static SvelteKit site deployed to GitHub Pages.                          |

## Commands

`just` on its own lists them all. The ones worth knowing:

- `just build-profile <macos|linux|vps>` — build a home-manager profile without
  activating it. This is what CI runs, and the right way to check a nix change.
- `just switch <profile>` — activate a profile. Reconfigures the machine, so
  don't run it unless asked.
- `just update` — refresh every nix pin (both flake locks and the `nix-shell`
  revisions).
- `just lint` — shellcheck over `bootstrap.sh`.
- `just check`, `just format`, `just build` — the site.

## Conventions

- `home-manager/flake.lock` and `nix/darwin/flake.lock` are generated. Change
  them with `just update-flakes`, never by hand.
- `common.nix` is every machine. Anything one machine needs belongs in that
  machine's entrypoint instead.
- Files are linked out of this checkout with `config.lib.file.mkOutOfStoreSymlink`,
  so editing them here takes effect without re-activating. Adding or removing a
  link still needs `just switch`.
- `home-manager/local/` is gitignored: it holds the shell entrypoints that
  activation generates once per machine.
