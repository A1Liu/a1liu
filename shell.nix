let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/1d060086d60cb76a40cf37109f979d88a5bd6396.tar.gz";

  pkgs = import nixpkgs { config = {}; overlays = []; };
in


pkgs.mkShellNoCC {
  packages = with pkgs; [
    # Lang Tools
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
