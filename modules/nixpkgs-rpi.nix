{ self, ... }:

{
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
  ];
}