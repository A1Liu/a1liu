{ lib, pkgs, ... }:

# The VPS: a headless AlmaLinux box that runs Claude Code sessions in a tmux
# session (`claude remote-control`), as the unprivileged `aliu`. Agents work out
# of repos under ~/code, so this profile is the machine's whole toolchain. See
# SETUP.md for creating the user.
#
# Deliberately not in here:
# - the `claude` CLI, which installs and updates itself into ~/.local/bin
# - per-repo tooling (duckdb, pulumi, gcloud, ...), which belongs to each
#   repo's own shell.nix
{
  imports = [ ./common.nix ];

  home.username = "aliu";
  home.homeDirectory = "/home/aliu";
  aliu.repoDir = "/home/aliu/code/aliu";

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

    # psql, for the test databases. The running cluster is the system postgres
    # under /var/lib/pgsql, which only `postgres` and root can administer.
    postgresql
  ];

  # The shared tmux.conf wraps the shell in `reattach-to-user-namespace`, which
  # is MacOS-only. Last `set` wins, so this undoes it.
  programs.tmux.extraConfig = lib.mkAfter ''
    set -g default-command "$SHELL"
  '';
}
