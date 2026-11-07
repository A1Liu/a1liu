# https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/inputs
{
  description = "Home Manager configuration of aliu";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      profile = system: modules: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};

        inherit modules;
      };
    in {
      homeConfigurations = {
        "aliu-macos" = profile "aarch64-darwin" [ ./home.nix ];
        "aliu-linux" = profile "x86_64-linux" [ ./home.nix ];

        # The headless VPS, which runs everything as root. See vps.nix.
        "aliu-vps" = profile "x86_64-linux" [ ./vps.nix ];
      };
    };
}
