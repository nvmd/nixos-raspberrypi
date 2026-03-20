# =============================================================================
# nixos-raspberrypi Flake
# =============================================================================
#
# Cross-Compilation Usage (from x86_64 workstation):
# ---------------------------------------------------
#
# Packages:
#   nix build .#packages.x86_64-linux.linux_rpi5      # RPi 5 kernel
#   nix build .#packages.x86_64-linux.linux_rpi4      # RPi 4 kernel
#   nix build .#packages.x86_64-linux.ffmpeg_7        # FFmpeg (aarch64)
#   nix build .#packages.x86_64-linux.libcamera       # libcamera
#
# Installer Images:
#   nix build .#installerImagesCross.x86_64-linux.rpi5   # RPi 5 SD image
#   nix build .#installerImagesCross.x86_64-linux.rpi4   # RPi 4 SD image
#   nix build .#installerImagesCross.x86_64-linux.rpi3   # RPi 3 SD image
#   nix build .#installerImagesCross.x86_64-linux.rpi02  # RPi Zero 2 SD image
#
# Explicit target architectures (via legacyPackages):
#   nix build .#legacyPackages.x86_64-linux.aarch64-linux.linux_rpi5  # 64-bit
#   nix build .#legacyPackages.x86_64-linux.armv7l-linux.linux_rpi3   # 32-bit
#
# Native builds (on aarch64 machine):
#   nix build .#packages.aarch64-linux.linux_rpi5
#   nix build .#installerImagesCross.aarch64-linux.rpi5
#
# See docs/cross-compilation.md for detailed documentation.
#
# =============================================================================

{
  description = "Flake for RaspberryPi support on NixOS";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    connect-timeout = 5;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    argononed = {
      url = "github:nvmd/argononed";
      flake = false;
    };

    nixos-images = {
      url = "github:nvmd/nixos-images/sdimage-installer";
      inputs.nixos-stable.follows = "nixpkgs";
      inputs.nixos-unstable.follows = "nixpkgs";
    };

    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    {
      self,
      nixpkgs,
      argononed,
      nixos-images,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;

      systems = import ./lib/systems.nix { inherit lib; };
      overlayDefs = import ./overlays;
      pkgHelpers = import ./lib/pkgs.nix {
        inherit
          lib
          nixpkgs
          inputs
          systems
          ;
        rpiOverlays = overlayDefs.rpiOverlaysList;
      };
      installerOutputs = import ./installers {
        inherit
          lib
          self
          inputs
          nixos-images
          systems
          ;
      };

      packageOutputs = import ./pkgs { inherit lib systems pkgHelpers; };

    in
    {
      formatter = lib.genAttrs systems.allSystems (
        system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );
      devShells = import ./dev-shells { inherit nixpkgs systems; };
      lib = import ./lib ({ inherit (nixpkgs) lib; } // inputs);
      nixosModules = import ./modules { inherit self argononed; };
      overlays = overlayDefs.outputOverlays;
      packages = packageOutputs.packages;

      # legacyPackages: native RPi pkgs + per-target cross packages
      #   legacyPackages.aarch64-linux         → full native pkgs (for nix repl, etc.)
      #   legacyPackages.x86_64-linux.aarch64-linux.linux_rpi5  → cross-compiled
      legacyPackages = lib.recursiveUpdate pkgHelpers.mkLegacyPackagesFor packageOutputs.crossPackagesByTarget;

      inherit (installerOutputs)
        nixosConfigurations
        installerImages
        installerImagesZstd
        installerImagesCross
        installerImagesCrossZstd
        ;

      # Build-all check: `nix build .#checks.x86_64-linux.all-installer-images`
      # Forces all 4 RPi models × 2 formats (raw + zstd) = 8 images to build.
      checks = lib.genAttrs systems.buildSystems (
        buildSystem:
        let
          pkgs = nixpkgs.legacyPackages.${buildSystem};
          images = installerOutputs.installerImagesCross.${buildSystem};
          imagesZstd = installerOutputs.installerImagesCrossZstd.${buildSystem};
        in
        {
          all-installer-images = pkgs.linkFarm "all-installer-images" (
            lib.mapAttrsToList (name: drv: {
              inherit name;
              path = drv;
            }) images
            ++ lib.mapAttrsToList (name: drv: {
              name = "${name}-zstd";
              path = drv;
            }) imagesZstd
          );
        }
      );
    };
}
