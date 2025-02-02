let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/e6cfe7821dc7ebf4e68014de11508d7aeb566fdc.tar.gz";

  pkgs = import nixpkgs { config = {}; overlays = []; };
in


pkgs.mkShellNoCC {
  packages = with pkgs; [
    # Tools
    lua-language-server
    typescript-language-server
    nodePackages.prettier
    bash-language-server
    shellcheck

    # Programming Languages
    nodejs_22
    pnpm
  ];
}
