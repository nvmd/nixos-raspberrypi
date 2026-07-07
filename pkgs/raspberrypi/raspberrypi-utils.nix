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
  version = "0-unstable-2026-06-23";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "a30e7c7b227d9a5e6dbedc1d343077be7ad92959";
    hash = "sha256-ayGsH9noSrmZQ99sQ1U/wYS6l7N5LWlr2xSvuoIw/qk=";
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
