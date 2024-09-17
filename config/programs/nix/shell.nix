let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/e6cfe7821dc7ebf4e68014de11508d7aeb566fdc.tar.gz";
 
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
