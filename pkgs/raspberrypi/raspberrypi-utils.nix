# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/libraspberrypi/default.nix#L28
# because libraspberrypi is outdated and deprecated
{ lib, stdenv
, fetchFromGitHub
, cmake
, dtc
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "raspberrypi-utils";
  version = "unstable-2024-10-14";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "30c8c789291e5aeebae9f3b0f5336a1e492841f4";
    hash = "sha256-rnJZbhuoQaKJ9UHDWn/Kye06qIMpow8eEkAdLFx/Zdw=";
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