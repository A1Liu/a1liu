{ lib, pkgs, ... }:

# The VPS: a headless AlmaLinux box that runs Claude Code sessions, as root, in
# a tmux session (`claude remote-control`). Agents work out of repos checked out
# in /root, so this profile is the machine's whole toolchain.
#
# Deliberately not in here:
# - the `claude` CLI, which installs and updates itself into ~/.local/bin
# - shell rc files, which the machine keeps its own copies of; the package set
#   is the part worth sharing
# - per-repo tooling (duckdb, pulumi, gcloud, ...), which belongs to each
#   repo's own shell.nix
{
  imports = [ ./common.nix ];

  home.username = "root";
  home.homeDirectory = "/root";
  aliu.repoDir = "/root/aliu";

  home.packages = with pkgs; [
    # CLI Tools
    git
    gh # Agents clone and push over https with this
    jq
    wget
    zsh

    # Programming languages
    nodejs_22
    pnpm

    # psql, for the test databases. The running cluster is still the system
    # postgres under /var/lib/pgsql, so use the system pg_ctl/initdb on it.
    postgresql
  ];

  # The shared tmux.conf wraps the shell in `reattach-to-user-namespace`, which
  # is MacOS-only. Last `set` wins, so this undoes it.
  programs.tmux.extraConfig = lib.mkAfter ''
    set -g default-command "$SHELL"
  '';
}
