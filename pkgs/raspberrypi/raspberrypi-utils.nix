# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/libraspberrypi/default.nix#L28
# because libraspberrypi is outdated and deprecated
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  dtc,
  ncurses,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "raspberrypi-utils";
  version = "0-unstable-2026-11-05";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "8c49aa29fa476271da4aa47c7e5c07c0ada6767f";
    hash = "sha256-eHrBZEP9TSc3Jke/1we0ubYnxTtSuke56p77zxK1RHU=";
  };

  buildInputs = [
    dtc # dtmerge depends on libfdt
    ncurses
  ];

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "A collection of scripts and simple applications for Raspberry Pi hardware";
    homepage = "https://github.com/raspberrypi/utils";
    license = licenses.bsd3;
    platforms = [
      "armv6l-linux"
      "armv7l-linux"
      "aarch64-linux"
    ];
    maintainers = with maintainers; [ kazenyuk ];
  };
})
