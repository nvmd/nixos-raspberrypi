# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/libraspberrypi/default.nix#L28
# because libraspberrypi is outdated and deprecated
{ lib, stdenv
, fetchFromGitHub
, cmake
, dtc
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "raspberrypi-utils";
  version = "unstable-2025-06-11";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "b7651d86d71a172b2208c67b2e360cbcb4f9d98f";
    hash = "sha256-Nt6MgJoh4VuefhQwj5NgiFOB7jQMEskY2cYzZ3KpFB8=";
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