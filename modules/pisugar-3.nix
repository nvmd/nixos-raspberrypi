{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.raspberry-pi.pisugar3;
in
{
  options.hardware.raspberry-pi.pisugar3 = {
    i2cBus = lib.mkOption {
      type = lib.types.str;
      default = "0x01";
      description = "I2C bus address for the PiSugar 3 battery module.";
    };

    i2cAddr = lib.mkOption {
      type = lib.types.str;
      default = "0x57";
      description = "I2C device address for the PiSugar 3 battery module.";
    };
  };

  config = {
    boot = {
      extraModulePackages = [
        (config.boot.kernelPackages.callPackage ../pkgs/pisugar-kmod.nix {
          pisugarVersion = "3";
        })
      ];

      kernelModules = [ "pisugar_3_battery" ];

      extraModprobeConfig = ''
        options pisugar_3_battery i2c_bus=${cfg.i2cBus} i2c_addr=${cfg.i2cAddr}
      '';
    };

    hardware.raspberry-pi.config.all.base-dt-params = {
      i2c = {
        enable = true;
        value = "on";
      };
    };
  };
}
