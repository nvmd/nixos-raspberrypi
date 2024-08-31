{ config, lib, pkgs, ... }:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberryPi = {
    variant = "5";
    bootloader = lib.mkDefault "rpiboot";
  };

  boot.kernelPackages = pkgs.linuxPackages_rpi5;
}