{ lib, self, ... }:

let
  # makeExtensible is the right choice: lighter than makeScope since we don't
  # need callPackage semantics, just self-referential attribute extension.
  flib = lib.makeExtensible (
    flib_self:
    let
      callLibs =
        file:
        import file {
          flib = flib_self;
          inherit self lib;
        };
    in
    {

      # NOTE: Endusers: please avoid using `int` (`internal`) directly
      int = callLibs ./internal.nix;

      # Build NixOS systems for Raspberry Pi with cross-compilation support.
      #
      # Cross-compilation: Set buildPlatform to compile from a different system.
      # Example:
      #   nixosSystem {
      #     buildPlatform = "x86_64-linux";  # Cross-compile from AMD64
      #     specialArgs = { ... };
      #     modules = [ ... ];
      #   }
      #
      mkBuilder =
        rpiModules:
        {
          nixpkgs ? self.inputs.nixpkgs,
          trustCaches ? true,
          buildPlatform ? null,
          ...
        }@args:
        flib.int.nixosSystemRPi {
          inherit
            nixpkgs
            trustCaches
            buildPlatform
            rpiModules
            ;
        } args;

      # Minimal NixOS system for Raspberry Pi
      nixosSystem = flib.mkBuilder [ flib.int.default-nixos-raspberrypi-config ];

      # Full NixOS system with all RPi optimizations
      nixosSystemFull = flib.mkBuilder [ flib.int.full-nixos-raspberrypi-config ];

      # Installer image (SD card image)
      nixosInstaller = flib.mkBuilder [
        flib.int.full-nixos-raspberrypi-config
        self.nixosModules.sd-image
        ../modules/installer/raspberrypi-installer.nix
      ];

      # NOTE: Not sure how long these two will be provided as a part of public
      # interface, please consider using `nixosSystem` or `nixosSystemFull`
      inject-overlays =
        { config, lib, ... }:
        {
          nixpkgs.overlays = [
            self.overlays.cross-fixes
            self.overlays.bootloader

            self.overlays.vendor-kernel
            self.overlays.vendor-firmware
            self.overlays.kernel-and-firmware

            self.overlays.vendor-pkgs
          ];
        };
      inject-overlays-global =
        { lib, ... }:
        {
          nixpkgs.overlays = lib.mkBefore [
            # !!! causes _lots_ of rebuilds for graphical stuff via ffmpeg, pipewire
            self.overlays.pkgs
          ];
        };

    }
  ); # flib
in
flib
