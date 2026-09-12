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
    firmwarePackage = lib.mkDefault pkgs.rpi.raspberrypifw;
  };

  boot.kernelPackages = lib.mkDefault pkgs.rpi.linuxPackages_rpi02;
}
