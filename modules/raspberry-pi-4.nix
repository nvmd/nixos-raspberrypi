{ self, config, lib, pkgs, ... }:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberryPi = {
    variant = "4";
    bootloader = lib.mkDefault "uboot";
    firmwarePackage = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.raspberrypifw;
  };

  boot.kernelPackages = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi4;
  boot.initrd.availableKernelModules = [
    "nvme"  # cm4 may have nvme drive connected with pcie
  ];
}
