{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.raspberry-pi;
in
{
  imports = [
    ./system/boot/loader/raspberrypi
    ./configtxt.nix
    ./udev.nix
    # config.txt is in `config.hardware.raspberry-pi.config-generated`
    ./configtxt-config.nix
  ];
  options = {
    hardware.raspberry-pi.appendKernelParams = lib.mkOption {
      default = true;
      description = "Whether to add /dev/serial0 and /dev/tty1 as consoles in kernel commandline. You may want to disable this when /dev/serial0 is missing or when /dev/tty1 is not desired as a kernel console.";
    };
    hardware.raspberry-pi.appendKernelModulesInitrd = lib.mkOption {
      default = true;
      description = "Whether to include some kernel modules specific to Raspberry Pi hardware in the initramfs (`boot.initrd.availableKernelModules`).";
    };
    hardware.raspberry-pi.addRaspberryPiUtils = lib.mkOption {
      default = true;
      description = "Whether to add `raspberrypi-utils` to `environment.systemPackages`.";
    };
  };
  config = {
    boot.loader.raspberry-pi = {
      enable = lib.mkDefault true;
    };
    hardware.raspberry-pi.config.all.options = {
      arm_64bit = {
        enable = lib.mkDefault true;
        value = lib.mkDefault true;
      };
      enable_uart = {
        enable = lib.mkDefault true;
        value = lib.mkDefault true;
      };
      avoid_warnings = {
        enable = lib.mkDefault true;
        value = lib.mkDefault true;
      };
    };

    boot.consoleLogLevel = lib.mkDefault 7;
    # https://github.com/raspberrypi/firmware/issues/1539#issuecomment-784498108
    # https://github.com/RPi-Distro/pi-gen/blob/master/stage1/00-boot-files/files/cmdline.txt
    boot.kernelParams = lib.mkIf cfg.appendKernelParams [
      "console=serial0,115200n8"
      "console=tty1"
    ];

    boot.initrd.availableKernelModules = lib.mkIf cfg.appendKernelModulesInitrd [
      "xhci_pci"
      # https://github.com/NixOS/nixos-hardware/issues/631#issuecomment-1584100732
      "usbhid"
      "usb_storage"
      "vc4"
      "pcie_brcmstb" # required for the pcie bus to work
      "reset-raspberrypi" # required for vl805 firmware to load
    ];
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    environment.systemPackages = lib.mkIf cfg.addRaspberryPiUtils (
      with pkgs;
      [
        raspberrypi-utils
      ]
    );

    # workaround for "modprobe: FATAL: Module <module name> not found"
    # see https://github.com/NixOS/nixpkgs/issues/154163,
    #     https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
    nixpkgs.overlays = [
      (final: super: {
        makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
      })
    ];
  };
}
