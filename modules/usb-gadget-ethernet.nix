{ config, pkgs, lib, ... }:

{
  hardware.raspberry-pi.config.all.dt-overlays = {
    dwc2 = {
      enable = true;
      params = {};
    };
  };

  boot.kernelModules = [ "dwc2" "g_ether" ];

  boot.kernel.sysctl = {
    # ignore linkdown routes in case they won't be removed when device isn't
    # a "gadget" anymore
    # https://github.com/charkster/rpi_gadget_mode
    # https://www.marcusfolkesson.se/til/ignore_routes_with_linkdown/
    "net.ipv4.conf.all.ignore_routes_with_linkdown" = 1;
  };

  networking.interfaces.usb0.ipv4.addresses = lib.mkDefault [ {
    address = "10.0.0.2";
    prefixLength = 24;
  } ];
}