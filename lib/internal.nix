{ lib, self, ... }:

{
  nixosSystemRPi =
    { nixpkgs ? self.inputs.nixpkgs
    , trustCaches ? true
    , rpiModules
    }:
    { modules, ... }@args:
    assert nixpkgs.lib.assertMsg (args.specialArgs ? nixos-raspberrypi)
      "specialArgs must provide nixos-raspberrypi";
    nixpkgs.lib.nixosSystem (args // {
      modules = rpiModules
        # Nix cache with prebuilt packages,
        # see `devshells/nix-build-to-cachix.nix` for a list
        ++ lib.optional trustCaches self.nixosModules.trusted-nix-caches
        # User modules
        ++ args.modules;
    });

  full-nixos-raspberrypi-config = { config, ... }: {
    imports = with self.nixosModules; [
      self.lib.int.default-nixos-raspberrypi-config
      # Optonally add overlays with optimised packages into the global scope
      self.lib.inject-overlays-global
    ];
  };

  default-nixos-raspberrypi-config = { config, ... }: {
    # the only fully supported architecture
    nixpkgs.hostPlatform = "aarch64-linux";

    imports = with self.nixosModules; [
      # All RPi and RPi-optimised packages to be available in `pkgs.rpi`
      nixpkgs-rpi
      # Add necessary overlays with kernel, firmware, vendor packages
      self.lib.inject-overlays
    ];
  };

}