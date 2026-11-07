let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/1d060086d60cb76a40cf37109f979d88a5bd6396.tar.gz";
 
  pkgs = import nixpkgs { config = {}; overlays = []; };
in


pkgs.mkShellNoCC {
  packages = with pkgs; [
    # Tools
    zsh
    ripgrep
    git
    git-lfs
    tmux
    jq
    (vim_configurable.override {
      python3 = pkgs.python3;
    })

    # Programming Languages
    python3
    go
    rustup
    nodejs_22
    pnpm
  ];
}
