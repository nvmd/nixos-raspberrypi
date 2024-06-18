{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.boot.loader.raspberryPi;
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;

  ubootBinName = if isAarch64 then "u-boot-rpi-arm64.bin" else "u-boot-rpi.bin";

  builderUboot = import ./uboot-builder.nix {
    inherit pkgs configTxt;
    inherit ubootBinName;
    ubootPackage = {
        "0" = {
          armhf = pkgs.ubootRaspberryPiZero;
        };
        "0_2" = {
          aarch64 = pkgs.ubootRaspberryPi_64bit;
        };
        "1" = {
          armhf = pkgs.ubootRaspberryPi;
        };
        "2" = {
          armhf = pkgs.ubootRaspberryPi2;
        };
        "3" = {
          armhf = pkgs.ubootRaspberryPi3_32bit;
          aarch64 = pkgs.ubootRaspberryPi_64bit;
        };
        "4" = {
          aarch64 = pkgs.ubootRaspberryPi_64bit;
        };
        "5" = {
          aarch64 = pkgs.ubootRaspberryPi_64bit;
        };
      }.${cfg.variant}.${if isAarch64 then "aarch64" else "armhf"};
    extlinuxConfBuilder = config.boot.loader.generic-extlinux-compatible.populateCmd;
  };
  builderGeneric = import ./raspberrypi-builder.nix {
    inherit pkgs configTxt;
    targetPath = cfg.firmwarePath;
  };

  builder = {
    uboot = "${builderUboot} -f ${cfg.firmwarePath} -d /boot -c";
    rpiboot = "${builderGeneric} -d ${cfg.firmwarePath} -c";
  };

  configTxt = config.hardware.raspberry-pi.config-output;

in

{
  disabledModules = [ "system/boot/loader/raspberrypi/raspberrypi.nix" ];


  options = {

    boot.loader.raspberryPi = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to create files with the system generations and copy firmware
          files to `firmwarePath`.
          `<firmwarePath>/old` will hold files from old generations.
        '';
      };

      firmwarePath = mkOption {
        default = "/boot/firmware";
        type = types.str;
        description = ''
          Target path for system firmware and system generations.
          `<firmwarePath>/old` will hold files from old generations.
        '';
      };

      bootloader = mkOption {
        default = if cfg.variant == "5" then "rpi" else "uboot";
        type = types.enum [ "rpi" "uboot" ];
        description = ''
          Bootloader to use:
          - `"uboot"`: U-Boot
          - `"rpi"`: The linux kernel is installed directly into the
            firmware directory as expected by the Raspberry Pi boot
            process.
            This can be useful for newer hardware that doesn't yet have
            uboot compatibility or less common setups, like booting a
            cm4 with an nvme drive.
        '';
      };

      variant = mkOption {
        type = types.enum [ "0" "0_2" "1" "2" "3" "4" "5" ];
        description = "";
      };

    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      assertions = let supportAarch64 = [ "0_2" "3" "4" "5" ];
      in singleton {
        assertion = !pkgs.stdenv.hostPlatform.isAarch64
                    || builtins.elem cfg.variant supportAarch64;
        message = ''
          Only Raspberry Pi versions
          ${builtins.concatStringsSep ", " supportAarch64} support aarch64.
        '';
      };
    })

    (mkIf (cfg.enable && (cfg.bootloader == "rpi")) {
      hardware.raspberry-pi.config = {
        all = {
          options = {
            kernel = {
              enable = true;
              value = "kernel.img";
            };
          };
        };
      };
      hardware.raspberry-pi.extra-config = ''
        [all]
        initramfs initrd followkernel
      '';

      boot.loader.grub.enable = false;

      system = {
        build.installBootLoader = builder."rpiboot";
        boot.loader.id = "raspberrypi";
        boot.loader.kernelFile = pkgs.stdenv.hostPlatform.linux-kernel.target;
      };
    })

    (mkIf (cfg.enable && (cfg.bootloader == "uboot")) {
      hardware.raspberry-pi.config = {
        all = {
          options = {
            kernel = {
              enable = true;
              value = ubootBinName;
            };
          };
        };
      };

      # Enable to manage extlinux' options with its builder/populateCmd ...
      boot.loader.generic-extlinux-compatible = {
        enable = true;
        # don't add FDTDIR to the extlinux conf file to use the device tree
        # provided by firmware.
        useGenerationDeviceTree = false;
      };

      boot.loader.grub.enable = false;

      # ... These are also set by generic-extlinux-compatible, but we need to
      # override them here to be able to setup config.txt,firmware, etc
      # before setting up extlinux
      # `lib.mkOverride 60` to override the default, while still allowing
      # consuming modules to override with mkForce
      system = {
        build.installBootLoader = lib.mkOverride 60 (builder."uboot");
        boot.loader.id = lib.mkOverride 60 ("uboot+extlinux");
      };
    })

  ];
}
