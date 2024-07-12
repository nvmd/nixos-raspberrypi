{}:

{
  mkRaspberrypiBootloader = variant: bootloader: ({ config, pkgs, ... }: {
    imports = [ ../modules/raspberrypi.nix ];
    boot.loader.raspberryPi = {
      inherit variant bootloader;
    };
  });
}