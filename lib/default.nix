{ lib, self, ... }:

{
  inject-overlays = { config, lib, ... }: {
    nixpkgs.overlays = [
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