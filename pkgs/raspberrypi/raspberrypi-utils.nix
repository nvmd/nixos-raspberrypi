# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/libraspberrypi/default.nix#L28
# because libraspberrypi is outdated and deprecated
{ lib, stdenv
, fetchFromGitHub
, cmake
, dtc
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "raspberrypi-utils";
  version = "unstable-2024-07-18";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "88867f61b0aab512b8ee9ec9ee67751820ac43e5";
    hash = "sha256-IGOujoS5CzZSpN6DrQzWK3Rr0zmwGfldH+rIWpDirjE=";
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