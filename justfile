# `just` on its own lists these.
#
# A profile is a home-manager output in home-manager/flake.nix without the
# `aliu-` prefix: macos, linux, vps. There's no default, because activating the
# wrong one reconfigures the machine.

[private]
default:
    @just --list --unsorted

# Activate a home-manager profile.
switch profile:
    nix run home-manager/master -- switch -b bak --flake ./home-manager#aliu-{{ profile }}

# Build a profile without activating it, which is what CI does.
build-profile profile:
    nix build --no-link ./home-manager#homeConfigurations.aliu-{{ profile }}.activationPackage

# Activate the nix-darwin system config. MacOS only.
switch-darwin:
    # sudo resets PATH, and nix lives outside of it.
    sudo "$(command -v nix)" run nix-darwin -- switch --flake ./nix/darwin#aliu

# Update every nix pin in the repo.
update: update-flakes update-shells

# Update every flake lock: this repo's, home-manager's, nix-darwin's, and the
# `alenv` envs.
update-flakes:
    nix flake update
    cd home-manager && nix flake update
    cd nix/darwin && nix flake update
    for dir in shell/flakes/*/; do (cd "$dir" && nix flake update); done

# Point the nix-shell files at current nixos-unstable.
update-shells:
    #!/usr/bin/env bash
    # They name a revision with no hash, so swapping it is the whole update.
    set -euo pipefail
    rev="$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/nixos-unstable | cut -f1)"
    [ -n "$rev" ] || { echo "error: could not resolve nixos-unstable" >&2; exit 1; }
    echo "==> nixpkgs $rev"
    for f in $(grep -rl 'nixpkgs/archive/' --include='*.nix' .); do
      # -i.bak so this works with both GNU and BSD sed.
      sed -i.bak -E "s|(nixpkgs/archive/)[0-9a-f]{40}|\1$rev|" "$f"
      rm -f "$f.bak"
    done

# Build this branch's bootstrap the way CI does, off the pushed branch.
bootstrap profile:
    ALIU_REF="$(git branch --show-current)" ./bootstrap.sh {{ profile }} --check

lint:
    shellcheck bootstrap.sh

# The rest is the a1liu.com site; see package.json.

install:
    pnpm install --frozen-lockfile

# Serve the site at localhost:1337.
dev:
    pnpm run dev

# Build the static site into .out.
build:
    pnpm run build

# Serve the contents of .out.
preview:
    pnpm run preview

# Typecheck the Svelte sources.
check:
    pnpm run check

# Prettier over the Svelte and TS sources.
format:
    pnpm run format

clean:
    pnpm run clean
