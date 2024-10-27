{ config, lib, pkgs, ... }:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberryPi = {
    variant = "02";
    bootloader = lib.mkDefault "uboot";
  };

  boot.kernelPackages = pkgs.linuxPackages_rpi02;
}