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
      # Nothing in environment.systemPackages: home-manager installs itself,
      # and the editor is a home-manager package too.

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

      # Where the GUI apps come from, rather than nixpkgs.
      homebrew = {
        enable = true;
        # onActivation.cleanup = "uninstall";

        casks = [
          "obsidian"
          "mozilla-vpn"
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
    # A config is named after the profile that activates it, so the machine
    # uses one name throughout: `just switch h3` and `just switch-darwin h3`.
    # Build one without activating it:
    # $ darwin-rebuild build --flake ./nix/darwin#aliu-macos
    darwinConfigurations."aliu-macos" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # The work machine: the shared configuration plus the TLS-intercepting
    # proxy's CA, which the personal machines must not have. See h3.nix.
    darwinConfigurations."aliu-h3" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ./h3.nix ];
    };
  };
}
