{ config, lib, pkgs, ... }:

{
  # ensure these groups used by udev rules exist
  # as of raspberrypi-udev-rules-20250423
  users.extraGroups = {
    gpio = {};
    i2c = {};
    input = {};
    plugdev = {};
    spi = {};
    video = {};
  };

  services.udev.packages = [
    pkgs.raspberrypi-udev-rules
  ];

  systemd.tmpfiles.packages = [
    pkgs.raspberrypi-udev-rules
  ];
}