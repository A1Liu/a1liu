{
  description = "Dev shell for this repo: the a1liu.com site, and the configs around it.";

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
            just # Runs ./justfile

            # The site. Everything else it needs is a devDependency.
            nodejs_22
            pnpm

            # Shell: shell/, bootstrap.sh, and what `just lint` runs
            bash-language-server
            shellcheck

            # Lua: vim/
            lua-language-server
            stylua

            # TypeScript and Svelte: src/
            typescript-language-server
          ];
        };
      });
    };
}
