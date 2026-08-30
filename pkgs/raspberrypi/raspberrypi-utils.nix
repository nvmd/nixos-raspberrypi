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
  version = "0-unstable-2026-08-11";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "6609ecb54f233d372d76b00caa12b292a6a9dba1";
    hash = "sha256-4wtSgJXtpa+Jq7Cl2I8Rxq0EbN+pSuPnAHw/J/tfXjI=";
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
