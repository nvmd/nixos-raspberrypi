{
  config,
  lib,
  pkgs,
  ...
}:

{
  # PrimaryGPU config, needed for Xorg to start
  # RaspberryOS adds this "OutputClass" section by default for all RPis
  # unless:
  # * it is RPi5 with a display connected to the RP1 chip (DPI/composite/MIPI DSI)
  #   import self.nixosModules.raspberry-pi-5.display-rp1 to enable it,
  #   instead of this module

  # Background info:
  # https://forum.manjaro.org/t/switch-install-from-rpi4-to-rpi5/150632/56
  # https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/5/default.nix#L20
  # https://www.reddit.com/r/voidlinux/comments/19fdtyd/pi_5_and_kms_blank_screen_how_to_fix/

  # https://github.com/raspberrypi-ui/gldriver-test/blob/master/usr/lib/systemd/scripts/rp1_test.sh)
  services.xserver.extraConfig = ''
    Section "OutputClass"
      Identifier "vc4"
      MatchDriver "vc4"
      Driver "modesetting"
      Option "PrimaryGPU" "true"
    EndSection
  '';
}
