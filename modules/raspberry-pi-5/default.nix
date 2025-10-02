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
    "panel_clockwork_cwu50" # display
    "vc4"
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
