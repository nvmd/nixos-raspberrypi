{ lib, self, ... }:

{
  add-global-nix-substituter = { config, ... }: {
    nix.settings = {
      substituters = [
        "https://nixos-raspberrypi.cachix.org"
      ];
      trusted-public-keys = [
        "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      ];
    };
  };

  inject-overlays = { config, lib, ... }: {
    nixpkgs.overlays = [
      (final: prev: {
        rpi = self.legacyPackages.${config.nixpkgs.system};
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