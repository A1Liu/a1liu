{
  description = "The env `alenv` falls back to: everything I reach for, in one shell.";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      # x86_64-darwin is gone as of nixpkgs 26.11.
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            # Shell
            zsh
            tmux
            just # Runs ./justfile

            # CLI tools
            git
            git-lfs
            gh # Clone and push over https
            ripgrep
            fd
            fzf
            ydiff
            tree
            jq
            yq-go # jq for YAML: Windmill's script.yaml, k8s manifests
            curl
            wget
            unzip
            openssl
            lsof

            # Language servers. Neovim enables these by name; without them on
            # PATH the LSP client starts nothing. See vim/lua/plugins.lua.
            typescript-language-server
            bash-language-server
            gopls
            rust-analyzer
            ty # Python types

            # Formatters and linters, also driven from Neovim
            biome
            ruff # Python lints and formatting
            shellcheck
            shfmt
            clang-tools # clang-format

            # Programming languages
            bun
            nodejs_22
            pnpm
            typescript
            python3
            uv
            go
            rustup

            # Databases. postgresql is psql and pg_dump; duckdb reads DuckLake.
            postgresql
            duckdb

            # Cloud and clusters
            pulumi
            pulumiPackages.pulumi-nodejs
            kubectl
            k9s
            doctl
          ];
        };
      });
    };
}
