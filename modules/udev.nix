{ config, lib, pkgs, ... }:

{
  # ensure these groups used by udev rules exist
  # as of raspberrypi-udev-rules-20240911
  users.extraGroups = {
    gpio = {};
    i2c = {};
    input = {};
    plugdev = {};
    spi = {};
    video = {};
  };

  services.udev.packages = [
    (pkgs.callPackage ../pkgs/raspberrypi/udev-rules.nix {})
  ];
}