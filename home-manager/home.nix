{ config, lib, pkgs, ... }:

# Workstation profile: MacOS and desktop Linux. See `vps.nix` for the server,
# and `common.nix` for what the two share.
#
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
in
{
  imports = [ ./common.nix ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "aliu";
  home.homeDirectory = homeDir;
  aliu.repoDir = aliuRepo;

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

    # Editor
    neovide

    # Postgres
    pgweb

    # ai
    herdr

    reattach-to-user-namespace

    # Programming languages
    rustup
    fnm
    uv
  ];

  home.file = {
    ".ssh/config".source = ./ssh-config;

    # NOTE: Use this one: https://opencode.ai/ there's another one with the same name
    # that's the wrong one and doesn't work.
    ".config/opencode/opencode.json".source = ./opencode.json;
  };

  # https://nix-community.github.io/home-manager/options.xhtml#opt-home.activation
  home.activation = {
    # We need to use the absolute path for ssh-keygen because... I don't know.
    # It was failing with a `ssh-keygen not found` before. Very cool.
    createSshKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "$HOME/.ssh/id_aliu" ]; then
        /usr/bin/ssh-keygen -t ed25519 -C 'albertymliu@gmail.com' -N "" -q -f $HOME/.ssh/id_aliu
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
}
