{ config, lib, pkgs, ... }:

{
  # The following have been borrowed from:
  # https://github.com/nix-community/nixos-images/blob/b733f0680a42cc01d6ad53896fb5ca40a66d5e79/nix/image-installer/module.nix#L84

  console.earlySetup = true;
  # ter-u22n is probably too big
  console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u16n.psf.gz";

  # Make colored console output more readable
  # for example, `ip addr`s (blues are too dark by default)
  # Tango theme: https://yayachiken.net/en/posts/tango-colors-in-terminal/
  console.colors = lib.mkDefault [
    "000000"
    "CC0000"
    "4E9A06"
    "C4A000"
    "3465A4"
    "75507B"
    "06989A"
    "D3D7CF"
    "555753"
    "EF2929"
    "8AE234"
    "FCE94F"
    "739FCF"
    "AD7FA8"
    "34E2E2"
    "EEEEEC"
  ];
}