{ self, lib, pkgs, ... }:

{
  imports = [ ../raspberrypi.nix ];

  boot.loader.raspberryPi = {
    variant = "5";
    bootloader = lib.mkDefault "kernelboot";
    firmwarePackage = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.raspberrypifw;
  };

  boot.kernelPackages = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi5;
  boot.initrd.availableKernelModules = [
    "nvme" # nvme drive connected with pcie
  ];
}
