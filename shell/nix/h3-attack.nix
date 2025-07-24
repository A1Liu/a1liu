let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/b6eaf97c6960d97350c584de1b6dcff03c9daf42.tar.gz";

  pkgs = import nixpkgs { config = {}; overlays = []; };
in


pkgs.mkShell {
  packages = with pkgs; [
    git

    # Programming Languages
    pipx
    python310
    python311
    python312

    nuclei

    yarn
    awscli2
    jq
    skaffold

    pyright
  ];
  buildInputs = with pkgs; [
    # postgresql # https://mgdm.net/weblog/postgresql-in-a-nix-shell/
  ];
}
