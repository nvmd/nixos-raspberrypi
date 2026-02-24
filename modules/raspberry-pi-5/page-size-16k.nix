{ nixos-raspberrypi, lib, ... }:
{
  # Optimizations or fixes for systems running
  # rpi5 (bcm2712-configured) Linux kernel 
  # See also: https://github.com/nvmd/nixos-raspberrypi/issues/64
  
  nixpkgs.overlays = lib.mkBefore [
    nixos-raspberrypi.overlays.jemalloc-page-size-16k
  ];
}