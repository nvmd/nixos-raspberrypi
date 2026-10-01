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
        pkgs.raspberrypifw;
  };

  boot.kernelPackages =
    lib.mkDefault
      pkgs.linuxPackages_rpi5;
  boot.initrd.availableKernelModules = [
    "nvme" # nvme drive connected with pcie
  ];
}
