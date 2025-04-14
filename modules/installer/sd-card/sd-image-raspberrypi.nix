# version of "modulesPath + /installer/sd-card/sd-image-aarch64.nix"
{ config, pkgs, lib, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/installer/sd-card/sd-image.nix")
  ];
  # people say this module (imported by "sd-card/sd-image" above)
  # causes problems with linux-rpi
  disabledModules = [ (modulesPath + "profiles/all-hardware.nix") ];

  # boot.* stuff for rpi is already configured in rpi{4,5}.nix
  # and `bootloader-config`

  # with default options set by sdImage it won't be mounted at all
  fileSystems."/boot/firmware".options = lib.mkForce [
    "noatime"
    "noauto"
    "x-systemd.automount"
    "x-systemd.idle-timeout=1min"
  ];
  fileSystems."/".options = [ "noatime" ];

  sdImage = {
    imageBaseName = let
      cfg = config.boot.loader.raspberryPi;
    in "nixos-sd-image-rpi${cfg.variant}-${cfg.bootloader}";

    # this needs to be big enough to accomodate all kernels and initrds of previous generations
    firmwareSize = 1024;
    firmwarePartitionID = "0x2175794e";
    populateFirmwareCommands = ''
      ${config.boot.loader.raspberryPi.firmwarePopulateCmd} -c ${config.system.build.toplevel} -f ./firmware
    '';
    populateRootCommands = ''
      # create with a mount point for FIRMWARE
      mkdir -p ./files/boot/firmware
      ${config.boot.loader.raspberryPi.bootPopulateCmd} -c ${config.system.build.toplevel} -b ./files/boot
    '';
  };
}