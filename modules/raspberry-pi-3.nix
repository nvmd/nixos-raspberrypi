{
  nixos-raspberrypi,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberry-pi = {
    variant = "3";
    bootloader = lib.mkDefault "uboot";
    firmwarePackage =
      lib.mkDefault
        nixos-raspberrypi.kernelPackages.${pkgs.stdenv.hostPlatform.system}.raspberrypifw;
  };

  boot.kernelPackages =
    lib.mkDefault
      nixos-raspberrypi.kernelPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi3;
}
