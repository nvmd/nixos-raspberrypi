{ lib, self, ... }:

{
  mkRaspberrypiBootloader = variant: bootloader: ({ config, pkgs, ... }: {
    imports = [ self.nixosModules.default ];
    boot.loader.raspberryPi = {
      inherit variant bootloader;
    };
  });

  inject-raspberrypi-overlays = rpi-nixpkgs-base: { lib, ... }: {
    nixpkgs.overlays = lib.mkBefore [
      (self: super: { # final: prev:
        rpi = import rpi-nixpkgs-base {
          inherit (self) system config;
          overlays = [
            self.overlays.pkgs
            self.overlays.vendor-pkgs
          ];
        };
      })

      self.overlays.bootloader

      self.overlays.pkgs
      self.overlays.vendor-pkgs

      self.overlays.vendor-kernel
      self.overlays.vendor-firmware
      # self.overlays.vendor-kernel-nixpkgs

      self.overlays.kernel-and-firmware
    ];
  };
  inject-raspberrypi-overlays-global = { lib, ... }: {
    nixpkgs.overlays = [
      # !!! causes _lots_ of rebuilds for graphical stuff via ffmpeg, SDL2
      self.overlays.pkgs
    ];
  };
}