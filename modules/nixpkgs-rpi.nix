{ nixos-raspberrypi, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      rpi = import nixos-raspberrypi.inputs.nixpkgs (
        {
          localSystem = { inherit (prev.stdenv.buildPlatform) system; };
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
        }
        // prev.lib.optionalAttrs (prev.stdenv.buildPlatform.system != prev.stdenv.hostPlatform.system) {
          crossSystem = { inherit (prev.stdenv.hostPlatform) system; };
        }
      );
    })
  ];
}
