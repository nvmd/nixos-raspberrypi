{ lib, self, ... }:

{
  inject-overlays = { config, lib, ... }: {
    nixpkgs.overlays = [
      (final: prev: {
        rpi = import self.inputs.nixpkgs {
          inherit (prev) system;
          config = {
            inherit (prev.config) allowUnfree allowUnfreePredicate;
          };

          overlays = [
            self.overlays.bootloader

            self.overlays.pkgs

            self.overlays.vendor-pkgs

            self.overlays.vendor-firmware
            self.overlays.vendor-kernel

            self.overlays.kernel-and-firmware
          ];
        };
      })

      self.overlays.bootloader

      self.overlays.vendor-kernel
      self.overlays.vendor-firmware
      # self.overlays.vendor-kernel-nixpkgs
      self.overlays.kernel-and-firmware

      self.overlays.vendor-pkgs
    ];
  };
  inject-overlays-global = { lib, ... }: {
    nixpkgs.overlays = lib.mkBefore [
      # !!! causes _lots_ of rebuilds for graphical stuff via ffmpeg, SDL2, pipewire
      self.overlays.pkgs
    ];
  };
}