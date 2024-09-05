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
    firmwareBuilder = firmwarePopulateCmd.firmware;
  };
  ubootBuilder = import ./uboot-builder.nix {
    inherit pkgs ubootBinName;
    inherit (cfg) ubootPackage;
    firmwareBuilder = firmwarePopulateCmd.firmware;
    extlinuxConfBuilder = config.boot.loader.generic-extlinux-compatible.populateCmd;
  };
  uefiBuilder = import ./uefi-builder.nix {
    inherit pkgs configTxt;
    inherit (cfg) uefiPackage;
    firmwareBuilder = firmwarePopulateCmd.firmware;
  };
  # Builders exposed via populateCmd, which run on the build architecture
  populateFirmwareBuilder = import  ./firmware-builder.nix {
    inherit configTxt;
    pkgs = pkgs.buildPackages;
    firmware = cfg.firmwarePackage;
  };
  populateRpibootBuilder = import ./raspberrypi-builder.nix {
    pkgs = pkgs.buildPackages;
    firmwareBuilder = firmwarePopulateCmd.firmware;
  };
  populateUbootBuilder = import ./uboot-builder.nix {
    inherit ubootBinName;
    pkgs = pkgs.buildPackages;
    inherit (cfg) ubootPackage;
    firmwareBuilder = firmwarePopulateCmd.firmware;
    extlinuxConfBuilder = config.boot.loader.generic-extlinux-compatible.populateCmd;
  };
  populateUefiBuilder = import ./uefi-builder.nix {
    pkgs = pkgs.buildPackages;
    inherit configTxt;
    inherit (cfg) uefiPackage;
    firmwareBuilder = firmwarePopulateCmd.firmware;
  };


  firmwareBuilderArgs = lib.optionalString (!cfg.useGenerationDeviceTree) " -r";
  uefiBuilderArgs = builtins.concatStringsSep " " [
    (lib.optionalString (cfg.uefiUseVendorFirmware) "-r")
    (lib.optionalString (cfg.uefiUseUefiFirmware) "-u")
  ];

  builder = {
    firmware = "${firmwareBuilder} -d ${cfg.firmwarePath} ${firmwareBuilderArgs} -c";
    uboot = "${ubootBuilder} -f ${cfg.firmwarePath} -d ${cfg.bootPath} -c";
    # uefi = "${uefiBuilder} -f ${cfg.firmwarePath} -d ${cfg.bootPath} ${uefiBuilderArgs} -c";
    # running from `extraInstallCommands` won't supply us with an argument for `-c`
    uefi = "${uefiBuilder} -f ${cfg.firmwarePath} -d ${cfg.bootPath} ${uefiBuilderArgs}";
    rpiboot = "${rpibootBuilder} -d ${cfg.firmwarePath} -c";
  };
  firmwarePopulateCmd = {
    firmware = "${populateFirmwareBuilder} ${firmwareBuilderArgs}";
    rpiboot = "${populateRpibootBuilder}";
    uboot = "${populateUbootBuilder}";
    uefi = "${populateUefiBuilder} ${uefiBuilderArgs}";
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
          - uefi: systemd configuration
          This partition must have set for the bootloader to work:
          - uboot: either GPT Legacy BIOS Bootable partition attribute, or 
                   MBR bootable flag
          - uefi: GPT partition type EF00 (EFI System Partition)
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
          - uefi: uefi firmware image, supplied dtbs
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
          Contains the builder command used to populate an image with both
          selected bootloader and firmware.

          Honors all relevant module options except the
          `-c <path-to-default-configuration>`
          `-d <target-dir>` arguments, which can be specified
          by the caller of firmwarePopulateCmd.

          Useful to have for sdImage.populateFirmwareCommands
        '';
      };

      bootloader = mkOption {
        default = if cfg.variant == "5" then "rpiboot" else "uboot";
        type = types.enum [ "rpiboot" "uboot" "uefi" ];
        description = ''
          Bootloader to use:
          - `"uboot"`: U-Boot, uses extlinux to manage nixos boot configurations
          - `"uefi"`: UEFI firmware image installed to firmware directory, 
            allowing to use systemd-boot to manage boot configurations
          - `"rpiboot"`: The linux kernel is installed directly into the
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

      ubootPackage = mkOption {
        default = {
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
      };
      uefiPackage = mkOption {
        default = {
          "0_2" = {
            aarch64 = pkgs.uefi_rpi3;
          };
          "3" = {
            aarch64 = pkgs.uefi_rpi3;
          };
          "4" = {
            aarch64 = pkgs.uefi_rpi4;
          };
          "5" = {
            aarch64 = pkgs.uefi_rpi5;
          };
        }.${cfg.variant}.${if isAarch64 then "aarch64" else "armhf"};
      };

      uefiUseVendorFirmware = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Use vendor's firmware package (usually `pkgs.raspberrypifw`)
        '';
      };
      uefiUseUefiFirmware = mkOption {
        default = true;
        type = types.bool;
        description = ''
          Use firmware files provided with UEFI firmware image.

          When enabled together with uefiUseVendorFirmware will 
          merge with vendor firmware, overwriting conflicting files
        '';
      };

    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      system.build.installFirmware = builder."firmware";
      boot.loader.raspberryPi.firmwarePopulateCmd = firmwarePopulateCmd."${cfg.bootloader}";
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

    (mkIf (cfg.enable && (cfg.bootloader == "uefi")) {
      assertions = let supportAarch64 = [ "0_2" "3" "4" "5" ];
      in singleton {
        assertion = !pkgs.stdenv.hostPlatform.isAarch64
                    || builtins.elem cfg.variant supportAarch64;
        message = ''
          UEFI is supported only on aarch64: (only Raspberry Pi boards 
          ${builtins.concatStringsSep ", " supportAarch64} supported).
        '';
      };
      # https://github.com/tianocore/edk2-platforms/tree/master/Platform/RaspberryPi/RPi4
      # https://github.com/pftf/RPi4/tree/master
      hardware.raspberry-pi.config = {
        all = {
          options = {
            armstub = {
              enable = true;
              value = "RPI_EFI.fd";
            };
            device_tree_address = {
              enable = true;
              value = "0x1f0000";
            };
            device_tree_end = {
              enable = true;
              value = ({
                "4" = "0x200000";
                "5" = "0x210000";
              }.${cfg.variant});
            };
            framebuffer_depth = {
              # Force 32 bpp framebuffer allocation.
              enable = lib.mkDefault (cfg.variant == "5");
              value = 32;
            };
            disable_overscan = {
              # Disable compensation for displays with overscan.
              enable = true;
              value = 1;
            };
            disable_commandline_tags = {
              enable = lib.mkDefault (cfg.variant == "4");
              value = 1;
            };
            enable_uart = {
              enable = lib.mkDefault (cfg.variant == "4");
              value = true;
            };
            uart_2ndstage = {
              enable = lib.mkDefault (cfg.variant == "4");
              value = 1;
            };
            enable_gic = {
              enable = lib.mkDefault (cfg.variant == "4");
              value = 1;
            };
          };
          dt-overlays = {
            miniuart-bt = {
              enable = lib.mkDefault (cfg.variant == "4");
              params = { };
            };
            upstream-pi4 = {
              enable = lib.mkDefault (cfg.variant == "4");
              params = { };
            };
          };
        };
      };

      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot = {
        enable = true;
        extraInstallCommands = ''
          ${builder.uefi}
        '';
      };
      # boot.initrd.systemd.enable = true;

    })

  ];
}
