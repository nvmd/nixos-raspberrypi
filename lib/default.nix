{ lib, self, ... }:

let
  # use makeScope instead?
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

      nixosSystem =
        {
          nixpkgs ? self.inputs.nixpkgs,
          trustCaches ? true,
          ...
        }@args:
        flib.int.nixosSystemRPi {
          inherit nixpkgs trustCaches;
          rpiModules = [ flib.int.default-nixos-raspberrypi-config ];
        } args;
      nixosSystemFull =
        {
          nixpkgs ? self.inputs.nixpkgs,
          trustCaches ? true,
          ...
        }@args:
        flib.int.nixosSystemRPi {
          inherit nixpkgs trustCaches;
          rpiModules = [ flib.int.full-nixos-raspberrypi-config ];
        } args;

      nixosInstaller =
        {
          nixpkgs ? self.inputs.nixpkgs,
          trustCaches ? true,
          ...
        }@args:
        flib.int.nixosSystemRPi {
          inherit nixpkgs trustCaches;
          rpiModules = [
            flib.int.full-nixos-raspberrypi-config
            self.nixosModules.sd-image
            ../modules/installer/raspberrypi-installer.nix
          ];
        } args;

      # NOTE: Not sure how long these two will be provided as a part of public
      # interface, please consider using `nixosSystem` or `nixosSystemFull`
      inject-overlays =
        { config, lib, ... }:
        {
          nixpkgs.overlays = [
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
