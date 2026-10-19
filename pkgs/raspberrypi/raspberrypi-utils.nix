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
  version = "0-unstable-2026-10-16";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "b57c48e97f7f43d95d86334798650cfda1ebc8a1";
    hash = "sha256-5L+83UVdIScYxmxGNdVh5nmdNiiojMHSZ0v/WpqwnUY=";
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
