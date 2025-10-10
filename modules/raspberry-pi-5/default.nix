{ self, config, lib, pkgs, ... }:

{
  imports = [ ../raspberrypi.nix ];

  boot.loader.raspberryPi = {
    variant = "5";
    bootloader = lib.mkDefault "kernel";
    firmwarePackage = lib.mkDefault self.packages.${pkgs.hostPlatform.system}.raspberrypifw;
  };

  boot.kernelPackages = lib.mkDefault self.packages.${pkgs.hostPlatform.system}.linuxPackages_rpi5;

  boot.initrd.kernelModules = [
    "panel-cwu50" # display
    "ocp8178_bl" # backlight
    "axp20x"
    "axp20x_regulator"
    "axp20x_i2c"
    "axp20x_battery"
    "axp20x_ac_power"
    "axp20x_pek"
    "axp20x_adc"
    "i2c_mux_pinctrl"
    "i2c_mux"
    "i2c_brcmstb"
    "i2c_bcm2835"
    "i2c_dev"
    "dwc2"
  ];

  # config.txt
  hardware.raspberry-pi.config = {
    all = {
      options = {
        ignore_lcd = {
          enable = true;
          value = 1;
        };
      };
      base-dt-params = {
        ant2 = {
          enable = true;
        };
      };
      dt-overlays = {
        audremap = {
          enable = true;
          params = {
            pins_12_13 = {
              enable = true;
            };
          };
        };
        vc4-kms-v3d = {
          enable = lib.mkForce false;
        };
      };
    };
    cm5 = {
      base-dt-params = {
        pciex1 = {
          enable = true;
          value = "off";
        };
        uart0 = {
          enable = true;
        };
      };
      dt-overlays = {
        clockworkpi-uconsole-cm5 = {
          enable = true;
        };
        vc4-kms-v3d-pi5 = {
          enable = true;
          params = {
            cma-384 = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
