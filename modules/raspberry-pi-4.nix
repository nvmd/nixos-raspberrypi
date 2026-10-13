{
  nixos-raspberrypi,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberry-pi = {
    variant = "4";
    bootloader = lib.mkDefault "uboot";
    firmwarePackage =
      lib.mkDefault
        pkgs.raspberrypifw;
  };

  boot.kernelPackages =
    lib.mkDefault
      pkgs.linuxPackages_rpi4;
  boot.initrd.availableKernelModules = [
    "nvme" # cm4 may have nvme drive connected with pcie
  ];
}
