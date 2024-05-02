# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/libraspberrypi/default.nix#L28
# because libraspberrypi is outdated and deprecated
{ lib, stdenv
, fetchFromGitHub
, cmake
, dtc
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "raspberrypi-utils";
  version = "unstable-2024-04-24";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "utils";
    rev = "451b9881b72cb994c102724b5a7d9b93f97dc315";
    hash = "sha512-IOh9n0itAnnJwRkwHFSl3TbDctl4IjEVEBYBYzfW0Z90wT6Mbc7zwYw4BlW1aV+J3IZxYdSBgSqZ0GgKt2wzSA==";
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