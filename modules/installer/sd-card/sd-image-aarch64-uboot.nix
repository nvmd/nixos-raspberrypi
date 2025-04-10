{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/installer/sd-card/sd-image.nix")
  ];

  # boot stuff is already configured with `boot.loader.raspberryPi` and
  # `hardware.raspberry-pi.config`

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
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
