{ lib, self, ... }:

{
  nixosSystemRPi =
    {
      nixpkgs ? self.inputs.nixpkgs,
      trustCaches ? true,
      rpiModules,
      # Cross-compilation: set buildPlatform to compile FROM a different system
      # e.g., buildPlatform = "x86_64-linux" to cross-compile on an AMD64 workstation
      buildPlatform ? null,
    }:
    { modules, ... }@args:
    assert nixpkgs.lib.assertMsg (
      args.specialArgs ? nixos-raspberrypi
    ) "specialArgs must provide nixos-raspberrypi";
    nixpkgs.lib.nixosSystem (
      builtins.removeAttrs args [
        "nixpkgs"
        "trustCaches"
        "buildPlatform"
      ]
      // {
        modules =
          rpiModules
          # Nix cache with prebuilt packages,
          # see `dev-shells/nix-build-to-cachix.nix` for a list
          ++ lib.optional trustCaches self.nixosModules.trusted-nix-caches
          # Cross-compilation support: inject buildPlatform if specified
          ++ lib.optional (buildPlatform != null) (
            { lib, ... }:
            {
              nixpkgs.buildPlatform = lib.mkDefault buildPlatform;
            }
          )
          # User modules
          ++ args.modules;
      }
    );

  full-nixos-raspberrypi-config =
    { ... }:
    {
      imports = with self.nixosModules; [
        self.lib.int.default-nixos-raspberrypi-config
        # Optionally add overlays with optimised packages into the global scope
        self.lib.inject-overlays-global
      ];
    };

  default-nixos-raspberrypi-config =
    { ... }:
    {
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
