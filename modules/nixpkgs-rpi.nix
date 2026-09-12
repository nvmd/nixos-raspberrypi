{ nixos-raspberrypi, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      rpi = import nixos-raspberrypi.inputs.nixpkgs (
        {
          # Preserve the build/host platform split so that `pkgs.rpi` is
          # cross-compiled too when the enclosing nixpkgs is cross-compiled
          # (build != host). Otherwise this re-import would build natively for
          # the host platform, requiring emulation (binfmt).
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
        // prev.lib.optionalAttrs
          (prev.stdenv.buildPlatform.system != prev.stdenv.hostPlatform.system)
          {
            crossSystem = { inherit (prev.stdenv.hostPlatform) system; };
          }
      );
    })
  ];
}
