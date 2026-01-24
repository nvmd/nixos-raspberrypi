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

  # Use generation bootloader for RPi5 by default for all sd-images
  # TODO: Remove when it is default for all RPi5 installations
  boot.loader.raspberry-pi.bootloader = lib.mkIf
    (config.boot.loader.raspberry-pi.variant == "5") "kernel";

  image.baseName = let
    cfg = config.boot.loader.raspberry-pi;
  in "nixos-image-rpi${cfg.variant}-${cfg.bootloader}";

  sdImage = {
    # this needs to be big enough to accomodate all kernels and initrds of previous generations
    firmwareSize = 1024;
    firmwarePartitionID = "0x2175794e";
    populateFirmwareCommands = ''
      ${config.boot.loader.raspberry-pi.firmwarePopulateCmd} -c ${config.system.build.toplevel} -f ./firmware
    '';
    populateRootCommands = ''
      # create with a mount point for FIRMWARE
      mkdir -p ./files/boot/firmware
      ${config.boot.loader.raspberry-pi.bootPopulateCmd} -c ${config.system.build.toplevel} -b ./files/boot
    '';
  };
}