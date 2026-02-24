{ nixos-raspberrypi, lib, pkgs, ... }:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberry-pi = {
    variant = "4";
    bootloader = lib.mkDefault "uboot";
    firmwarePackage = lib.mkDefault nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.raspberrypifw;
  };

  boot.kernelPackages = lib.mkDefault nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi4;
  boot.initrd.availableKernelModules = [
    "nvme" # cm4 may have nvme drive connected with pcie
  ];
}
