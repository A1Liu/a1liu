#!/bin/sh

# Sets up a machine from scratch: nix, the system-level nix config for the
# profile if it has one, then home-manager.
#
#   curl -fsSL https://raw.githubusercontent.com/A1Liu/a1liu/main/bootstrap.sh | sh -s -- vps
#
# A profile is a home-manager output in home-manager/flake.nix without the
# `aliu-` prefix. `--check` builds everything instead of activating it, which is
# what CI does, since a runner is neither `aliu` nor root on the VPS.

set -eu

REPO_URL="https://github.com/A1Liu/a1liu"

usage() {
  echo "usage: bootstrap.sh <macos|vps> [--check]" >&2
  exit 2
}

profile=""
check=false
for arg in "$@"; do
  case "$arg" in
    macos | vps) profile="$arg" ;;
    --check) check=true ;;
    *) usage ;;
  esac
done

[ -n "$profile" ] || usage

# Where each profile links its configs out of; see home-manager/*.nix.
case "$profile" in
  macos) repo_default="$HOME/code/aliu" ;;
  vps) repo_default="/root/aliu" ;;
esac

# Run from a checkout, this uses it. Piped from curl there's no checkout to use,
# so clone to wherever the profile expects to find one.
script_dir=""
case "$0" in
  */*) script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd) ;;
esac

if [ -n "$script_dir" ] && [ -d "$script_dir/home-manager" ]; then
  repo="$script_dir"
else
  repo="$repo_default"
fi

if [ "$repo" != "$repo_default" ]; then
  echo "warning: $profile links its configs out of $repo_default, not $repo" >&2
fi

if ! command -v nix > /dev/null 2>&1; then
  echo "==> Installing nix"

  installer=$(mktemp)
  curl -fsSL https://nixos.org/nix/install -o "$installer"

  case "$profile" in
    # MacOS only supports the multi-user install; single-user is the one that
    # works without systemd, e.g. in a container.
    macos) sh "$installer" --daemon --yes ;;
    vps) sh "$installer" --no-daemon ;;
  esac

  rm -f "$installer"
fi

# The installer only edits shell rc files, which does nothing for this shell.
set +u
for profile_script in \
  "$HOME/.nix-profile/etc/profile.d/nix.sh" \
  /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; do
  if [ -e "$profile_script" ]; then
    . "$profile_script"
  fi
done
set -u

mkdir -p "$HOME/.config/nix"
if ! grep -q experimental-features "$HOME/.config/nix/nix.conf" 2> /dev/null; then
  echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
fi

if [ ! -d "$repo" ]; then
  echo "==> Cloning $REPO_URL into $repo"

  if command -v git > /dev/null 2>&1; then
    git clone "$REPO_URL" "$repo"
  else
    nix run nixpkgs#git -- clone "$REPO_URL" "$repo"
  fi
fi

case "$profile" in
  macos)
    echo "==> nix-darwin"
    if [ "$check" = true ]; then
      nix build --no-link "$repo/nix/darwin#darwinConfigurations.aliu.system"
    else
      sudo nix run nix-darwin -- switch --flake "$repo/nix/darwin#aliu"
    fi
    ;;
  vps)
    # Nothing: the VPS runs AlmaLinux, and nix/nixos/configuration.nix only
    # applies to NixOS.
    ;;
esac

echo "==> home-manager"
if [ "$check" = true ]; then
  nix build --no-link "$repo/home-manager#homeConfigurations.aliu-$profile.activationPackage"
else
  nix run home-manager/master -- switch -b bak --flake "$repo/home-manager#aliu-$profile"
fi
