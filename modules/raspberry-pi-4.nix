{ config, lib, pkgs, ... }:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberryPi = {
    variant = "4";
    bootloader = lib.mkDefault "uboot";
  };

  boot.kernelPackages = pkgs.linuxPackages_rpi4;
}