# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/libraspberrypi/default.nix#L28
# because libraspberrypi is outdated and deprecated
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  dtc,
  gnutls,
  ncurses,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "raspberrypi-utils";
  version = "0-unstable-2026-10-02";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "e0484c848f9c9d1aecc7bd0738930db97bcf18df";
    hash = "sha256-0HQmgwTKeHdv3+h4+yqPbJ4sNUnCek5fZFkg1dgcfWQ=";
  };

  buildInputs = [
    dtc # dtmerge depends on libfdt
    gnutls # rpifwcrypto depends on GnuTLS
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
