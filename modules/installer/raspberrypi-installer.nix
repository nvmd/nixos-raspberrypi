{ config, pkgs, modulesPath, lib, ... }:
{
  # nixos' standard installer configuration as seen in
  # /installer/sd-card/sd-image-aarch64-installer.nix
  # but with fixes for Raspberry Pi
  imports = [
    (modulesPath + "/profiles/installation-device.nix")
  ];

  # disable swraid – it breaks the boot on raspberry:
  # - rootfs image is not initramfs (write error): looks like initrd
  # - /initrd.image: incomplete write (-28 != 25571065)
  # with the subsequent boot failure
  boot.swraid.enable = lib.mkForce false;

  # the installation media is also the installation target,
  # so we don't want to provide the installation configuration.nix.
  installer.cloneConfig = false;

  environment.systemPackages = with pkgs; [
    raspberrypi-eeprom
  ];
}