{ config, lib, pkgs, ... }:
let 
  luksConfigured = config.boot.initrd.luks.devices != {};
in {
  imports = [
    ./system/boot/loader/raspberrypi
    ./configtxt.nix
    ./udev.nix
    # config.txt is in `config.hardware.raspberry-pi.config-generated`
    ./configtxt-config.nix
  ];

  boot.loader.raspberryPi = {
    enable = true;
  };

  hardware.raspberry-pi.config.all.options = {
    arm_64bit = {
      enable = true;
      value = true;
    };
    enable_uart = {
      enable = true;
      value = true;
    };
    avoid_warnings = {
      enable = lib.mkDefault true;
      value = lib.mkDefault true;
    };
  };

  boot.consoleLogLevel = lib.mkDefault 7;
  # https://github.com/raspberrypi/firmware/issues/1539#issuecomment-784498108
  # https://github.com/RPi-Distro/pi-gen/blob/master/stage1/00-boot-files/files/cmdline.txt
  boot.kernelParams = [ "console=serial0,115200n8" "console=tty1" ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    # https://github.com/NixOS/nixos-hardware/issues/631#issuecomment-1584100732
    "usbhid"
    "usb_storage"
    "pcie_brcmstb" # required for the pcie bus to work
    "reset-raspberrypi" # required for vl805 firmware to load
  ] ++ lib.optional (!luksConfigured) "vc4";

  boot.kernelModules = lib.optional luksConfigured "vc4";

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    raspberrypi-utils
  ];

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
