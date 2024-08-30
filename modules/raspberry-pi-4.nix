{ config, lib, ... }:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberryPi = {
    variant = "4";
    bootloader = lib.mkDefault "rpiboot";
  };

  boot.kernelPackages = pkgs.linuxPackages_rpi4;
}