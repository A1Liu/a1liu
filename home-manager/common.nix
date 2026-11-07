{ config, lib, pkgs, ... }:

# Config that every machine gets. The per-machine entrypoints (`home.nix` for
# workstations, `vps.nix` for the server) own the identity bits -- username,
# home directory, where this repo is checked out -- and add whatever else that
# machine needs on top.
let
  symlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  options.aliu.repoDir = lib.mkOption {
    type = lib.types.str;
    description = "Checkout of github.com/A1Liu/a1liu to link configs out of.";
  };

  config = {
    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "24.11"; # Please read the comment before changing.

    home.packages = with pkgs; [
      # Editor
      neovim

      # CLI Tools
      git-lfs
      ripgrep
      fd
      fzf
      ydiff

      just # Runs ./justfile

      tmux

      cached-nix-shell

      # Programming languages
      bun
    ];

    programs.tmux = {
      enable = true;

      plugins = with pkgs; [
        tmuxPlugins.yank
        tmuxPlugins.sensible
      ];

      extraConfig = builtins.readFile ./tmux.conf;
    };

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    home.file = {
      ".inputrc".source = ./inputrc;
      ".gitconfig".source = ./gitconfig;
      ".gitignore_global".source = ./gitignore_global;

      # TODO: Apparently Flakes make it so that you can't do this in the sensible way,
      # because symlinking directly to a file would not be deterministic/pure.
      ".config/nvim/init.lua".source = symlink "${config.aliu.repoDir}/vim/init.lua";
      ".vimrc".source = symlink "${config.aliu.repoDir}/vim/init.vim";
      ".vim".source = symlink "${config.aliu.repoDir}/vim";

      ".bash_profile".source = symlink "${config.aliu.repoDir}/home-manager/local/shell_interact_init";
      ".bashrc".source = symlink "${config.aliu.repoDir}/home-manager/local/shell_interact_init";
      ".zshrc".source = symlink "${config.aliu.repoDir}/home-manager/local/shell_interact_init";
      ".zprofile".source = symlink "${config.aliu.repoDir}/home-manager/local/shell_init";
    };

    # Generates the entrypoints the rc files above link to, once; they're
    # gitignored, so each machine can edit its own.
    # https://nix-community.github.io/home-manager/options.xhtml#opt-home.activation
    home.activation = let
      writeFileIfNotExists = { filepath, isInteractive }: lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -f "${filepath}" ]; then
          mkdir -p $(dirname "${filepath}")
          touch ${filepath}
          echo '#!/bin/sh' >> "${filepath}"
          echo "" >> "${filepath}"
          echo 'export CFG_DIR="${config.aliu.repoDir}"' >> "${filepath}"
          echo 'if [ -n "$ZSH_VERSION" ]; then CUR_SHELL=zsh; elif [ -n "$BASH_VERSION" ]; then CUR_SHELL=bash; fi' >> "${filepath}"
          echo 'IS_INTERACTIVE_SHELL=${isInteractive}' >> "${filepath}"
          echo "" >> "${filepath}"
          echo '. "${config.aliu.repoDir}/shell/dispatch"' >> "${filepath}"

        else
          echo "File '${filepath}' already exists, skipping."
        fi
      '';
    in {
      createShellInteractiveEntrypoint = writeFileIfNotExists {
        filepath = "${config.aliu.repoDir}/home-manager/local/shell_interact_init";
        isInteractive = "true";
      };
      createShellEntrypoint = writeFileIfNotExists {
        filepath = "${config.aliu.repoDir}/home-manager/local/shell_init";
        isInteractive = "false";
      };
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
