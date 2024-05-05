self: super: { # final: prev:

  # see also https://github.com/NixOS/nixos-hardware/pull/927
  linux_rpi4 = super.linux_rpi4.override {
    argsOverride = rec {
      # https://github.com/raspberrypi/linux/releases/tag/stable_20240423
      modDirVersion = "6.6.28";
      tag = "stable_20240423";

      version = "${modDirVersion}-${tag}";
      src = super.fetchFromGitHub {
        owner = "raspberrypi";
        repo = "linux";
        rev = tag;
        hash = super.fakeHash;
      };
    };
  };

  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/linux-rpi.nix
  linux_rpi5 = self.linux_rpi4.override {
    rpiVersion = 5;
    argsOverride.defconfig = "bcm2712_defconfig";
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/firmware/raspberrypi/default.nix
  # pkgs/os-specific/linux/firmware/raspberrypi/default.nix
  raspberrypifw = super.overrideAttrs (old: {
    # they seem to got back to releases
    # https://github.com/raspberrypi/firmware/releases/tag/1.20240424
    version = "1.20240424";
    # release tarball contains only the files we need
    src = super.fetchurl {
      url = "https://github.com/raspberrypi/firmware/releases/download/1.20240424/raspi-firmware_1.20240424.orig.tar.xz";
      hash = super.fakeHash;
    };
    # src = super.fetchFromGitHub {
    #   owner = "raspberrypi";
    #   repo = "firmware";
    #   rev = "969420b4121b522ab33c5001074cc4c2547dafaf";
    #   hash = super.fakeHash;
    # };
  });

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/firmware/raspberrypi-wireless/default.nix
  # pkgs/os-specific/linux/firmware/raspberrypi-wireless/default.nix
  raspberrypiWirelessFirmware = super.overrideAttrs (old: {
    version = "2024-02-26";
    srcs = [
      # https://github.com/RPi-Distro/bluez-firmware/tree/78d6a07730e2d20c035899521ab67726dc028e1c
      (super.fetchFromGitHub {
        name = "bluez-firmware";
        owner = "RPi-Distro";
        repo = "bluez-firmware";
        rev = "78d6a07730e2d20c035899521ab67726dc028e1c";
        hash = super.fakeHash;
      })
      # https://github.com/RPi-Distro/firmware-nonfree/tree/223ccf3a3ddb11b3ea829749fbbba4d65b380897
      (super.fetchFromGitHub {
        name = "firmware-nonfree";
        owner = "RPi-Distro";
        repo = "firmware-nonfree";
        rev = "223ccf3a3ddb11b3ea829749fbbba4d65b380897";
        hash = super.fakeHash;
      })
    ];
  });

}