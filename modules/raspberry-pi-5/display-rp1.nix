{ config, lib, pkgs, ... }:

{
  # For displays connected to the RP1 (DPI/composite/MIPI DSI) (RPi5 only!)
  # see `display-vc4` for more info
  
  # https://github.com/raspberrypi-ui/gldriver-test/blob/master/usr/lib/systemd/scripts/rp1_test.sh
  services.xserver.extraConfig = let
    identifier = "rp1";
    driver = "rp1-vec|rp1-dsi|rp1-dpi";
  in  ''
    Section "OutputClass"
      Identifier "${identifier}"
      MatchDriver "${driver}"
      Driver "modesetting"
      Option "PrimaryGPU" "true"
    EndSection
  '';
}