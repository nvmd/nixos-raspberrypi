{ config, lib, pkgs, raspberry-pi-nix, ... }:

{
  imports = [
    ./system/boot/loader/raspberrypi
    ./udev.nix
    # generate config.txt with raspberry-pi-nix' generator
    # config.txt is in `config.hardware.raspberry-pi.config-generated`
    raspberry-pi-nix.nixosModules.config-txt.generator
    raspberry-pi-nix.nixosModules.config-txt.default
  ];

  boot.loader.raspberryPi = {
    enable = true;
  };

  boot.consoleLogLevel = lib.mkDefault 7;
  # https://github.com/raspberrypi/firmware/issues/1539#issuecomment-784498108
  boot.kernelParams = [ "console=serial0,115200n8" "console=tty1" ];

  # https://github.com/NixOS/nixos-hardware/issues/631#issuecomment-1584100732
  boot.initrd.availableKernelModules = [
    "usbhid"
    "usb_storage"
    "vc4"
    "pcie_brcmstb" # required for the pcie bus to work
    "reset-raspberrypi" # required for vl805 firmware to load
  ];
  hardware.enableRedistributableFirmware = true;

  # suppress systemd-udevd's
  # `...udev-rules/99-local.rules:33 Unknown group 'gpio', ignoring.` and
  # `...udev-rules/99-local.rules:33 Unknown group 'spi', ignoring.` in logs
  users.extraGroups = {
    i2c = {};
    spi = {};
    gpio = {};
  };

  environment.systemPackages = with pkgs; [
    raspberrypi-utils
  ];

  # RaspberryOS adds this "OutputClass" section by default for all RPis
  #  https://forum.manjaro.org/t/switch-install-from-rpi4-to-rpi5/150632/56
  # https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/5/default.nix#L20
  # Needed for Xorg to start (https://github.com/raspberrypi-ui/gldriver-test/blob/master/usr/lib/systemd/scripts/rp1_test.sh)
  #  also as seen on: https://www.reddit.com/r/voidlinux/comments/19fdtyd/pi_5_and_kms_blank_screen_how_to_fix/
  # This won't work for displays connected to the RP1 (DPI/composite/MIPI DSI), since I don't have one to test.
  services.xserver.extraConfig = ''
    Section "OutputClass"
      Identifier "vc4"
      MatchDriver "vc4"
      Driver "modesetting"
      Option "PrimaryGPU" "true"
    EndSection
  '';
}