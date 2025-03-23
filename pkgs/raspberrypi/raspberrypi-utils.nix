# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/libraspberrypi/default.nix#L28
# because libraspberrypi is outdated and deprecated
{ lib, stdenv
, fetchFromGitHub
, cmake
, dtc
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "raspberrypi-utils";
  version = "unstable-2025-03-18";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "92900c5c733c8b91a67b1772d4f0a25104f2b05d";
    hash = "sha256-ItknnAWicXK1pfAVbSgSBj1SAx7oxnhsAZsRyaqfCDM=";
  };

  buildInputs = [
    dtc # dtmerge depends on libfdt
  ];

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "A collection of scripts and simple applications for Raspberry Pi hardware";
    homepage = "https://github.com/raspberrypi/utils";
    license = licenses.bsd3;
    platforms = [ "armv6l-linux" "armv7l-linux" "aarch64-linux" ];
    maintainers = with maintainers; [ kazenyuk ];
  };
})