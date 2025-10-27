{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
        home-manager
        vim
      ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      system.primaryUser = "aliu";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      system.keyboard.enableKeyMapping = true;
      # system.keyboard.remapCapsLockToControl = true;

      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };

      homebrew = {
          enable = true;
          # onActivation.cleanup = "uninstall";

          taps = [];
          brews = [];
          casks = [
            "neovide"
            "obsidian"
            "mozilla-vpn"
            "unnaturalscrollwheels"
          ];
      };

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
 
      # set some OSX preferences that I always end up hunting down and changing.
      system.defaults = {
        NSGlobalDomain = {
          # Dark mode
          AppleInterfaceStyle = "Dark";

          # Disable scrolling left/right to go navigate through history
          AppleEnableMouseSwipeNavigateWithScrolls = false;
          AppleEnableSwipeNavigateWithScrolls = false;
        };

        controlcenter = {
          BatteryShowPercentage = true;

          # Show Bluetooth in menu bar
          Bluetooth = true;
        };

        # minimal dock
        dock = {
          show-recents = false;
          mru-spaces = false;
        };
        # a finder that tells me what I want to know and lets me work
        finder = {
          AppleShowAllExtensions = true;
          ShowPathbar = true;
          FXEnableExtensionChangeWarning = false;
        };
      };

    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."aliu" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
