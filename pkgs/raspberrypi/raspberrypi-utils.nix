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
  version = "0-unstable-2026-09-14";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "ebc4a56bac3a896d5c14e56fe27dcd6cb36dd373";
    hash = "sha256-Q8tP7x0H0++W7J5XpEiO4ACOz2XooYZdVmlMRIaiIBQ=";
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
