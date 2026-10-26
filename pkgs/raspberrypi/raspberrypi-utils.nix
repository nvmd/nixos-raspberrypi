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
  version = "0-unstable-2026-10-24";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "496be8f704651f74662a2ab07c4cc89ac5bd9b8a";
    hash = "sha256-SO8qtrn2mKfCX136d0wvpsyuMgcpoKGeqDq7bFh09LU=";
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
