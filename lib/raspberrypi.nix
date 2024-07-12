{ flib, ... }: # flake's library

{
  mkRaspberrypiBootloader = variant: bootloader: ({ config, pkgs, ... }: {
    imports = [ ../modules/raspberrypi.nix ];
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
            (import ../overlays/raspberrypi/vendor-utils.nix)
            (import ../overlays/raspberrypi/pkgs.nix)
            (import ../overlays/raspberrypi/pkgs-global.nix)
          ];
        };
      })
      (import ../overlays/raspberrypi/pkgs.nix)
      (import ../overlays/raspberrypi/vendor-utils.nix)
      (import ../overlays/raspberrypi/vendor-kernel.nix)
      # (import ./overlays/raspberrypi/vendor-kernel-nixpkgs.nix)
      (import ../overlays/raspberrypi/bootloader.nix)
    ];
  };
  inject-raspberrypi-overlays-global = { lib, ... }: {
    nixpkgs.overlays = [
      # !!! causes a _lots_ of rebuilds for graphical stuff via ffmpeg, SDL2
      (import ../overlays/raspberrypi/pkgs-global.nix)
    ];
  };
}