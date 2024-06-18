# version of
# "modulesPath + /installer/sd-card/sd-image-aarch64-installer.nix"
{ config, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/installation-device.nix")
    ./sd-image-raspberrypi5.nix
  ];

  # the installation media is also the installation target,
  # so we don't want to provide the installation configuration.nix.
  installer.cloneConfig = false;
}