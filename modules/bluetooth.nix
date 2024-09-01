{ config, lib, pkgs, raspberry-pi-nix, ... }:

{
  imports = [
    # generate config.txt with raspberry-pi-nix' generator
    # config.txt is in `config.hardware.raspberry-pi.config-generated`
    raspberry-pi-nix.nixosModules.config-txt.generator
    raspberry-pi-nix.nixosModules.config-txt.default
  ];

  environment.systemPackages = with pkgs; [
    bluez bluez-tools
  ];

  hardware = {
    bluetooth.enable = true;
    raspberry-pi = {
      config = {
        all = {
          # Base DTB parameters
          # https://github.com/raspberrypi/linux/blob/a1d3defcca200077e1e382fe049ca613d16efd2b/arch/arm/boot/dts/overlays/README#L132
          base-dt-params = {
            # https://github.com/raspberrypi/linux/blob/a1d3defcca200077e1e382fe049ca613d16efd2b/arch/arm/boot/dts/overlays/README#L323
            # Set to "off" to disable autoprobing of Bluetooth
            # driver without need of hciattach/btattach
            # (default "on")
            krnbt = {
              enable = true;
              value = "on";
            };
          };
        };
      };
    };
  };
}