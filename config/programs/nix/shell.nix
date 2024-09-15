let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
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
