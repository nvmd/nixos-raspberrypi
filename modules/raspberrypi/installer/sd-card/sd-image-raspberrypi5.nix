# version of "modulesPath + /installer/sd-card/sd-image-aarch64.nix"
{ config, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/installer/sd-card/sd-image.nix")
  ];
  # people say this module (imported by "sd-card/sd-image" above)
  # causes problems with linux-rpi
  disabledModules = [ "profiles/all-hardware.nix" ];

  # boot.* stuff for rpi is already configured in rpi{4,5}.nix
  # and `bootloader-config`

  sdImage = {
    imageBaseName = "nixos-sd-image-${config.configuration-revision.revision.short}";
    firmwareSize = 1024;
    firmwarePartitionID = "0x2175794e";
    populateFirmwareCommands = "${config.system.build.installBootLoader} ${config.system.build.toplevel} -d ./firmware";
    populateRootCommands = "";
  };
}