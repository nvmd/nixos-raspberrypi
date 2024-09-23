{ config, lib, pkgs, ... }:

{
  imports = [
    ./raspberrypi.nix
    ./display-vc4.nix
  ];

  boot.loader.raspberryPi = {
    variant = "4";
    bootloader = lib.mkDefault "uboot";
  };

  boot.kernelPackages = pkgs.linuxPackages_rpi4;
  boot.initrd.availableKernelModules = [
    "nvme"  # cm4 may have nvme drive connected with pcie
  ];
}