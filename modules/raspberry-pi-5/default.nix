{
  self,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [../raspberrypi.nix];

  boot.loader.raspberryPi = {
    variant = "5";
    bootloader = lib.mkDefault "kernel";
    firmwarePackage = lib.mkDefault self.packages.${pkgs.hostPlatform.system}.raspberrypifw;
  };

  boot.kernelPackages = lib.mkDefault self.packages.${pkgs.hostPlatform.system}.linuxPackages_rpi5;

  boot.initrd.kernelModules = [
    # Display
    "panel_cwu50"
    "ocp8178_bl"
    "backlight"
    "drm"
    "drm_kms_helper"
    "drm_dma_helper"
    "drm_display_helper"
    "drm_shmem_helper"
    "drm_ttm_helper"
    "ttm"
    "drm_rp1_dsi"

    # Power management (AXP20x PMIC)
    "axp20x_battery"
    "axp20x_ac_power"
    "axp20x_adc"
    "industrialio"

    # Input (keyboard)
    "gpio_keys"

    # I2C/SPI/GPIO buses
    "i2c_brcmstb"
    "i2c_gpio"
    "i2c_algo_bit"
    "spi_bcm2835"
    "raspberrypi_gpiomem"
    "i2c_designware_core"
    "i2c_designware_platform"

    # Optional RP1 stuff
    "rp1_pio"
    "rp1_fw"
    "rp1_mailbox"
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
