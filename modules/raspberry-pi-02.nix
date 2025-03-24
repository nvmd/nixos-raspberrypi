{ self, config, lib, pkgs, ... }:

{
  imports = [ ./raspberrypi.nix ];

  boot.loader.raspberryPi = {
    variant = "02";
    bootloader = lib.mkDefault "uboot";
    firmwarePackage = lib.mkDefault self.packages.${pkgs.hostPlatform.system}.raspberrypifw;
  };

  boot.kernelPackages = lib.mkDefault self.packages.${pkgs.hostPlatform.system}.linuxPackages_rpi02;

  # workaround for "modprobe: FATAL: Module <module name> not found"
  # see https://github.com/NixOS/nixpkgs/issues/154163,
  #     https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];
}