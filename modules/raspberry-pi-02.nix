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
        pkgs.raspberrypifw;
  };

  boot.kernelPackages =
    lib.mkDefault
      pkgs.linuxPackages_rpi02;
}
