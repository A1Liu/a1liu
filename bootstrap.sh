#!/bin/sh

# Sets up a machine with nothing on it: nix, a checkout of this repo, the
# system-level nix config for the profile if it has one, then home-manager.
#
#   curl -fsSL https://raw.githubusercontent.com/A1Liu/a1liu/main/bootstrap.sh | sh -s -- vps
#
# A profile is a home-manager output in home-manager/flake.nix without the
# `aliu-` prefix. `--check` builds everything instead of activating it, which is
# what CI does, since a runner is neither `aliu` nor root on the VPS.

set -eu

REPO_URL="https://github.com/A1Liu/a1liu"

# Branch or tag to check out. CI points this at the branch under test.
REF="${ALIU_REF:-main}"

usage() {
  echo "usage: bootstrap.sh <macos|vps> [--check]" >&2
  exit 2
}

# For tools that have to exist before nix does. Everything after the nix install
# comes from nix instead.
install_missing() {
  missing=""
  for tool in "$@"; do
    if ! command -v "$tool" > /dev/null 2>&1; then
      missing="$missing $tool"
    fi
  done

  [ -n "$missing" ] || return 0

  echo "==> Installing$missing"

  sudo=""
  if [ "$(id -u)" -ne 0 ]; then
    sudo="sudo"
  fi

  # shellcheck disable=SC2086 # $missing is a list of package names
  if command -v dnf > /dev/null 2>&1; then
    $sudo dnf install -y $missing
  elif command -v apt-get > /dev/null 2>&1; then
    $sudo apt-get update && $sudo apt-get install -y $missing
  else
    echo "error: install$missing by hand, then re-run this" >&2
    exit 1
  fi
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

# home-manager configures one user, so as root this would configure the wrong
# one. Package installs escalate on their own.
if [ "$(id -u)" -eq 0 ]; then
  echo "error: run this as the user to set up, not as root" >&2
  exit 1
fi

# Where the profiles link their configs out of; see home-manager/*.nix.
repo="$HOME/code/aliu"

if ! command -v nix > /dev/null 2>&1; then
  # The installer unpacks a .tar.xz, and GNU tar shells out to xz to do it.
  # MacOS needs nothing here, since bsdtar handles .tar.xz itself.
  if [ "$profile" = vps ]; then
    install_missing tar xz
  fi

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

# git comes from nix rather than the machine, so this needs nothing preinstalled
# -- and on MacOS it doesn't set off the Command Line Tools prompt.
if [ ! -d "$repo" ]; then
  echo "==> Cloning $REPO_URL#$REF into $repo"

  mkdir -p "$(dirname "$repo")"
  nix run nixpkgs#git -- clone --branch "$REF" "$REPO_URL" "$repo"
fi

case "$profile" in
  macos)
    echo "==> nix-darwin"
    if [ "$check" = true ]; then
      nix build --no-link "$repo/nix/darwin#darwinConfigurations.aliu.system"
    else
      # Absolute path because sudo resets PATH, and nix lives outside of it.
      sudo "$(command -v nix)" run nix-darwin -- switch --flake "$repo/nix/darwin#aliu"
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
