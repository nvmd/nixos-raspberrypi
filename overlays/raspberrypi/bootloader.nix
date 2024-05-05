self: super: {
  # see also
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/misc/uboot/default.nix#L494
  # https://source.denx.de/u-boot/u-boot
  # https://github.com/u-boot/u-boot/
  ubootRaspberryPi_64bit = super.unstable.buildUBoot rec {
    defconfig = "rpi_arm64_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    filesToInstall = [ "u-boot.bin" ];
    # version = "2024.04";
    # src = super.fetchFromGitHub {
    #   owner = "u-boot";
    #   repo = "u-boot";
    #   rev = "v${version}";
    #   hash = super.fakeHash;
    # };
  };

  uefi_rpi4 = super.fetchzip {
    url = "https://github.com/pftf/RPi4/releases/download/v1.36/RPi4_UEFI_Firmware_v1.36.zip";
    hash = "sha256-XWwutTPp7znO5w1XDEUikBNsRK74h0llxnIWIwaxhZc=";
    stripRoot = false;
  };
  # https://github.com/worproject/rpi5-uefi/
  uefi_rpi5 = super.fetchzip {
    url = "https://github.com/worproject/rpi5-uefi/releases/download/v0.3/RPi5_UEFI_Release_v0.3.zip";
    hash = "sha256-bjEvq7KlEFANnFVL0LyexXEeoXj7rHGnwQpq09PhIb0=";
    stripRoot = false;
  };
}