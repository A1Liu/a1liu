let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/1d060086d60cb76a40cf37109f979d88a5bd6396.tar.gz";

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
