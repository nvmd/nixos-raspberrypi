{ config, lib, pkgs, raspberry-pi-nix, ... }:

{
  imports = [
    ./raspberrypi/system/boot/loader/raspberrypi
    raspberry-pi-nix.nixosModules.udev
    # generate config.txt with raspberry-pi-nix' generator
    # config.txt is in `config.hardware.raspberry-pi.config-generated`
    raspberry-pi-nix.nixosModules.config-txt.generator
    raspberry-pi-nix.nixosModules.config-txt.default
  ];

  boot.loader.raspberryPi = {
    enable = true;
  };

  boot.initrd.availableKernelModules = [
    # result of the nixos' hardware scan on rpi5
    # with nvme drive connected with pcie
    "nvme" "usbhid"

    # from raspberry-pi-nix
    # "usbhid"
    "usb_storage"
    "vc4"
    "pcie_brcmstb" # required for the pcie bus to work
    "reset-raspberrypi" # required for vl805 firmware to load
  ];
  hardware.enableRedistributableFirmware = true;
}