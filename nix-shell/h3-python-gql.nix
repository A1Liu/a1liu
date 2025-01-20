let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/e6cfe7821dc7ebf4e68014de11508d7aeb566fdc.tar.gz";
 
  pkgs = import nixpkgs { config = {}; overlays = []; };
in


pkgs.mkShell {
  packages = with pkgs; [
    # Tools

    # Programming Languages
    python311
    pyright
  ];
}
