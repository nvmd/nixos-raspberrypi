{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.boot.loader.raspberryPi;
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;

  ubootBinName = if isAarch64 then "u-boot-rpi-arm64.bin" else "u-boot-rpi.bin";


  # Builders used to write during system activation
  firmwareBuilder = import ./firmware-builder.nix {
    inherit pkgs configTxt;
    firmware = cfg.firmwarePackage;
  };
  rpibootBuilder = import ./raspberrypi-builder.nix {
    inherit pkgs;
    firmwareBuilder = firmwarePopulateCmd;
  };
  ubootBuilder = import ./uboot-builder.nix {
    inherit pkgs ubootBinName;
    inherit (cfg) ubootPackage;
    firmwareBuilder = firmwarePopulateCmd;
    extlinuxConfBuilder = config.boot.loader.generic-extlinux-compatible.populateCmd;
  };

  # Builders exposed via populateCmd, which run on the build architecture
  populateFirmwareBuilder = import  ./firmware-builder.nix {
    inherit configTxt;
    pkgs = pkgs.buildPackages;
    firmware = cfg.firmwarePackage;
  };
  populateRpibootBuilder = import ./raspberrypi-builder.nix {
    pkgs = pkgs.buildPackages;
    firmwareBuilder = firmwarePopulateCmd;
  };
  populateUbootBuilder = import ./uboot-builder.nix {
    inherit ubootBinName;
    pkgs = pkgs.buildPackages;
    ubootPackage = cfg.ubootPackage;
    firmwareBuilder = firmwarePopulateCmd;
    extlinuxConfBuilder = config.boot.loader.generic-extlinux-compatible.populateCmd;
  };

  firmwarePopulateCmd = "${populateFirmwareBuilder} ${firmwareBuilderArgs}";
  firmwareBuilderArgs = lib.optionalString (!cfg.useGenerationDeviceTree) " -r";

  builder = {
    firmware = "${firmwareBuilder} -d ${cfg.firmwarePath} ${firmwareBuilderArgs} -c";
    uboot = "${ubootBuilder} -f ${cfg.firmwarePath} -b ${cfg.bootPath} -c";
    rpiboot = "${rpibootBuilder} -d ${cfg.firmwarePath} -c";
  };

  populateCmds = {
    uboot = {
      firmware = "${populateUbootBuilder}"; # call with `-f <firmware target path>`
      boot = "${populateUbootBuilder}";     # call with `-b <boot-dir>`
    };
    rpiboot = {
      firmware = "${populateRpibootBuilder}";
      boot = "";
    };
  };

  configTxt = config.hardware.raspberry-pi.config-output;

in

{
  disabledModules = [
    # the module has been remove in nixpkgs, but that shouldn't prevent us
    # from using the now free (!) name for our module
    # mkRemovedOptionModule in `"modulesPath + rename.nix"`, unfortunately,
    # prevents us from doing so in upstream nixpkgs
    { key = "removedOptionModule#boot_loader_raspberryPi"; }
  ];

  options = {

    boot.loader.raspberryPi = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to manage boot firmware, device trees and bootloader
          with this module
        '';
      };

      firmwarePackage = mkPackageOption pkgs "raspberrypifw" { };

      bootPath = mkOption {
        default = "/boot";
        type = types.str;
        description = ''
          Target path for:
          - uboot: extlinux configuration - (extlinux/extlinux.conf, initrd, 
              kernel Image)
          This partition must have set for the bootloader to work:
          - uboot: either GPT Legacy BIOS Bootable partition attribute, or 
                   MBR bootable flag
        '';
      };

      firmwarePath = mkOption {
        default = "/boot/firmware";
        type = types.str;
        description = ''
          Target path for system firmware and:
          - rpi: system generations, `<firmwarePath>/old` will hold
            files from old generations.
          - uboot: uboot binary
        '';
      };

      useGenerationDeviceTree = mkOption {
        default = false;  # generic-extlinux-compatible defaults to `true`
        type = types.bool;
        description = ''
          Whether to use device tree supplied from the generation's kernel
          or from the vendor's firmware package (usually `pkgs.raspberrypifw`).

          When enabled, the device tree binaries will be copied to
          `firmwarePath` from the generation's kernel.

          This affects `rpiboot` and `uboot` bootloaders.

          Note that this affects all generations, regardless of the
          setting value used in their configurations.
        '';
      };

      firmwarePopulateCmd = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          Contains the builder command used to populate image of the firmware partition.

          Copies boards' firmware.
          Depending on the chosen bootloader, may also copy bootloader image.

          Honors all relevant module options except the
          `-c <path-to-default-configuration>`
          `-d <target-dir>` arguments, which can be specified
          by the caller of firmwarePopulateCmd.

          Useful to have for sdImage.populateFirmwareCommands
        '';
      };

      bootPopulateCmd = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          Contains the builder command used to populate /boot

          May or may not do anything depending on chosen the bootloader.

          Useful to have for sdImage.populateRootCommands
        '';
      };

      bootloader = mkOption {
        default = if cfg.variant == "5" then "rpiboot" else "uboot";
        type = types.enum [ "rpiboot" "uboot" ];
        description = ''
          Bootloader to use:
          - `"uboot"`: U-Boot
          - `"rpiboot"`: The linux kernel is installed directly into the
            firmware directory as expected by the Raspberry Pi boot
            process.
            This can be useful for newer hardware that doesn't yet have
            uboot compatibility or less common setups, like booting a
            cm4 with an nvme drive.
        '';
      };

      variant = mkOption {
        type = types.enum [ "0" "02" "1" "2" "3" "4" "5" ];
        description = "";
      };

      ubootPackage = mkOption {
        default = {
          "0" = {
            armhf = pkgs.ubootRaspberryPiZero;
          };
          "02" = {
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
      };

    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      assertions = let
        supportAarch64 = [ "02" "3" "4" "5" ];
      in singleton {
        assertion = !pkgs.stdenv.hostPlatform.isAarch64
                    || builtins.elem cfg.variant supportAarch64;
        message = ''
          Only Raspberry Pi versions
          ${builtins.concatStringsSep ", " supportAarch64} support aarch64.
        '';
      };
      system.build.installFirmware = builder."firmware";
      boot.loader.raspberryPi.firmwarePopulateCmd = populateCmds."${cfg.bootloader}".firmware;
      boot.loader.raspberryPi.bootPopulateCmd = populateCmds."${cfg.bootloader}".boot;
    })

    (mkIf (cfg.enable && (cfg.bootloader == "rpiboot")) {
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
        # if false, don't add FDTDIR to the extlinux conf file to use the device tree
        # provided by firmware. (we usually want this to be false)
        useGenerationDeviceTree = cfg.useGenerationDeviceTree;
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
