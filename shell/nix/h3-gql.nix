let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/1d060086d60cb76a40cf37109f979d88a5bd6396.tar.gz";

  pkgs = import nixpkgs { config = {}; overlays = []; };
in


pkgs.mkShell {
  packages = with pkgs; [
    # Programming Languages
    pyenv
    python311
    # nodejs_22
    yarn
    awscli2
    jq
    skaffold

    # Python LSP: types from ty, lints and formatting from ruff. Both are
    # enabled in vim/lua/plugins.lua.
    ty
    ruff
  ];
  buildInputs = with pkgs; [
    # postgresql # https://mgdm.net/weblog/postgresql-in-a-nix-shell/
  ];
}
