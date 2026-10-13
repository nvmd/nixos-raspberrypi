{
  nixos-raspberrypi,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ../raspberrypi.nix ];

  boot.loader.raspberry-pi = {
    variant = "5";
    bootloader = lib.mkDefault "kernelboot";
    firmwarePackage =
      lib.mkDefault
        nixos-raspberrypi.kernelPackages.${pkgs.stdenv.hostPlatform.system}.raspberrypifw;
  };

  boot.kernelPackages =
    lib.mkDefault
      nixos-raspberrypi.kernelPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi5;
  boot.initrd.availableKernelModules = [
    "nvme" # nvme drive connected with pcie
  ];
}
