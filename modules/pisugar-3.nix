{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      linuxPackages = super.linuxPackages.extend (
        lpself: lpsuper: {
          pisugar3 = super.linuxPackages.callPackage ../pkgs/pisugar-kmod.nix {
            pisugarVersion = "3";
          };
        }
      );
    })
  ];

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [
      pisugar3-kmod
    ];

    kernelModules = [ "pisugar_3_battery" ];

    extraModprobeConfig =
      let
        i2cBus = "0x01";
        i2cAddr = "0x57";
      in
      ''
        options pisugar_3_battery i2c_bus=${i2cBus} i2c_addr=${i2cAddr}
      '';
  };

  hardware.raspberry-pi.config.all.base-dt-params = {
    i2c = {
      enable = true;
      value = "on";
    };
  };
}
