{ nixos-raspberrypi, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      rpi = import nixos-raspberrypi.inputs.nixpkgs {
        inherit (prev.stdenv.hostPlatform) system;
        config = {
          inherit (prev.config) allowUnfree allowUnfreePredicate;
        };

        overlays = [
          nixos-raspberrypi.overlays.bootloader

          nixos-raspberrypi.overlays.pkgs

          nixos-raspberrypi.overlays.vendor-pkgs

          nixos-raspberrypi.overlays.vendor-firmware
          nixos-raspberrypi.overlays.vendor-kernel

          nixos-raspberrypi.overlays.kernel-and-firmware
        ];
      };
    })
  ];
}
