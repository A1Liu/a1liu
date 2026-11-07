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
      # `nixpkgs.config` is a no-op once a configuration is handed its `pkgs`,
      # so orbstack being unfree has to be dealt with here.
      profile = system: modules: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

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
