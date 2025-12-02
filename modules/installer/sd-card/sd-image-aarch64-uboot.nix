{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/installer/sd-card/sd-image.nix")
  ];

  # boot stuff is already configured with `boot.loader.raspberryPi` and
  # `hardware.raspberry-pi.config`

  # with default options set by sdImage it won't be mounted at all
  fileSystems."/boot/firmware".options = lib.mkForce [
    "noatime"
    "noauto"
    "x-systemd.automount"
    "x-systemd.idle-timeout=1min"
  ];
  fileSystems."/".options = [ "noatime" ];

  image.baseName = let
    cfg = config.boot.loader.raspberryPi;
  in "nixos-image-rpi${cfg.variant}-${cfg.bootloader}";

  sdImage = {
    firmwareSize = 128;
    populateFirmwareCommands = let
      uboot = config.boot.loader.raspberryPi.ubootPackage;
      raspberrypifw = config.boot.loader.raspberryPi.firmwarePackage;
      configTxt = config.hardware.raspberry-pi.config-output;
      rpifwdir = "${raspberrypifw}/share/raspberrypi/boot";
      populateFirmware = pkgs.writeShellApplication {
        name = "raspberry-pi-firmware";
        text = builtins.readFile ../../system/boot/loader/raspberrypi/firmware.sh;
      };
    in ''
      # Add bootloader-independent firmware files: config.txt, bootcode, DTBs
      ${populateFirmware}/bin/raspberry-pi-firmware ${configTxt} ${rpifwdir} ${rpifwdir} firmware/

      # Add U-Boot
      cp ${uboot}/u-boot.bin firmware/u-boot-rpi-arm64.bin
    '';
    populateRootCommands = ''
      # create with a mount point for FIRMWARE
      mkdir -p ./files/boot/firmware
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
