{
  nixos-raspberrypi,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberry-pi = {
    variant = "02";
    bootloader = lib.mkDefault "uboot";
    firmwarePackage =
      lib.mkDefault
        nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.raspberrypifw;
  };

  boot.kernelPackages =
    lib.mkDefault
      nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi02;

  hardware.raspberry-pi.config.all.dt-overlays.vc4-kms-v3d.params.cma-128.enable = lib.mkDefault true;
}
