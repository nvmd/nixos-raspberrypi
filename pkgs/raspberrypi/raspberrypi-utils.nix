# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/libraspberrypi/default.nix#L28
# because libraspberrypi is outdated and deprecated
{ lib, stdenv
, fetchFromGitHub
, cmake
, dtc
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "raspberrypi-utils";
  version = "unstable-2024-07-22";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "a1d522f0f1b50858a44fac80523a2bd80098e789";
    hash = "sha256-1w8fEz4A5HyMVWh08xcMYWxElnYvfbKnpNbGaWW9R0U=";
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