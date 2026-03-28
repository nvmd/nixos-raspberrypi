final: prev: {
  # see also
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/misc/uboot/default.nix#L494
  # https://source.denx.de/u-boot/u-boot
  # https://github.com/u-boot/u-boot/
  ubootRaspberryPi_64bit = prev.buildUBoot rec {
    defconfig = "rpi_arm64_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    filesToInstall = [ "u-boot.bin" ];
    # version = "2024.04";
    # src = prev.fetchFromGitHub {
    #   owner = "u-boot";
    #   repo = "u-boot";
    #   rev = "v${version}";
    #   hash = prev.fakeHash;
    # };
  };

  uefi_rpi3 = prev.fetchzip {
    url = "https://github.com/pftf/RPi3/releases/download/v1.50/RPi3_UEFI_Firmware_v1.50.zip";
    hash = "sha256-R+hQn/Rgpg4ItSMOr0DiwOqgaQWz6m+WmPmdiid1yPE=";
    stripRoot = false;
  };
  uefi_rpi4 = prev.fetchzip {
    url = "https://github.com/pftf/RPi4/releases/download/v1.50/RPi4_UEFI_Firmware_v1.50.zip";
    hash = "sha256-g8046/Ox0hZgvU6u3ZfC6HMqoTME0Y7NsZD6NvUsp7w=";
    stripRoot = false;
  };
  # https://github.com/worproject/rpi5-uefi/
  uefi_rpi5 = prev.fetchzip {
    url = "https://github.com/worproject/rpi5-uefi/releases/download/v0.3/RPi5_UEFI_Release_v0.3.zip";
    hash = "sha256-bjEvq7KlEFANnFVL0LyexXEeoXj7rHGnwQpq09PhIb0=";
    stripRoot = false;
  };
}
