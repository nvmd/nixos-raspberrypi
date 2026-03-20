{ lib }:
{
  rpiSystems = [ "aarch64-linux" "armv7l-linux" "armv6l-linux" ];
  buildSystems = [ "x86_64-linux" "aarch64-linux" ];
  allSystems = lib.systems.flakeExposed;
}
