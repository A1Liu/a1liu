{ config, lib, pkgs, ... }:

# There's probably better way to get cross-platform support; for now I'm just
# using this: https://github.com/crasm/dead-simple-home-manager
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  unsupported = builtins.abort "Unsupported platform";
  homeDir =
    if isLinux then "/home/aliu" else
    if isDarwin then "/Users/aliu" else
    unsupported;
  aliuRepo = "${homeDir}/code/aliu";
  programsDir = "${aliuRepo}/config/programs";
  symlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "aliu";
  home.homeDirectory = homeDir;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    git-lfs

    neovim
    neovide
    ripgrep
    tmux
    fd
    ydiff

    cached-nix-shell
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".inputrc".source = ./inputrc;
    ".tmux.conf".source = ./tmux.conf;
    ".gitconfig".source = ./gitconfig;
    ".gitignore_global".source = ./gitignore_global;
    ".ssh/config".source = ./ssh-config;

    # TODO: Apparently Flakes make it so that you can't do this in the sensible way,
    # because symlinking directly to a file would not be deterministic/pure.
    ".config/nvim/init.lua".source = symlink "${aliuRepo}/vim/init.lua";
    ".vimrc".source = symlink "${aliuRepo}/vim/init.vim";
    ".vim".source = symlink "${aliuRepo}/vim";

    ".bash_profile".source = symlink "${aliuRepo}/home-manager/local/shell_interact_init";
    ".bashrc".source = symlink "${aliuRepo}/home-manager/local/shell_interact_init";
    ".zshrc".source = symlink "${aliuRepo}/home-manager/local/shell_interact_init";
    ".zprofile".source = symlink "${aliuRepo}/home-manager/local/shell_init";

  };

  # https://nix-community.github.io/home-manager/options.xhtml#opt-home.activation
  home.activation = let
    writeFileIfNotExists = { filepath, isInteractive }: lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "${filepath}" ]; then
        mkdir -p $(dirname "${filepath}")
        touch ${filepath}
        echo '#!/bin/sh' >> "${filepath}"
        echo "" >> "${filepath}"
        echo 'export CFG_DIR="${aliuRepo}"' >> "${filepath}"
        echo 'CUR_SHELL="$(basename "$0" 2>/dev/null || echo "$0" | tr -d "-")"' >> "${filepath}"
        echo 'IS_INTERACTIVE_SHELL=${isInteractive}' >> "${filepath}"
        echo "" >> "${filepath}"
        echo '. "${aliuRepo}/shell/dispatch"' >> "${filepath}"

      else
        echo "File '${filepath}' already exists, skipping."
      fi
    '';
  in {
    createShellInteractiveEntrypoint = writeFileIfNotExists {
      filepath = "${aliuRepo}/home-manager/local/shell_interact_init";
      isInteractive = "true";
    };
    createShellEntrypoint = writeFileIfNotExists {
      filepath = "${aliuRepo}/home-manager/local/shell_init";
      isInteractive = "false";
    };
    createSshKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "$HOME/.ssh/id_aliu" ]; then
        ssh-keygen -t ed25519 -C 'albertymliu@gmail.com' -N "" -q -f $HOME/.ssh/id_aliu
      else
        echo "File \"$HOME/.ssh/id_aliu\" already exists, skipping."
      fi
    '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/aliu/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
