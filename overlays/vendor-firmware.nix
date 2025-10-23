self: super: { # final: prev:

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/firmware/raspberrypi/default.nix
  # pkgs/os-specific/linux/firmware/raspberrypi/default.nix
  # https://github.com/raspberrypi/firmware/commits/stable/

  # see `extra/git_hash` for a matching hash of the `raspberrypi/linux`

  raspberrypifw_20250915 = super.raspberrypifw.overrideAttrs (old: {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20250915
    version = "1.20250915";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "676efed1194de38975889a34276091da1f5aadd3";
      hash = "sha256-00rLY/xtYuE2L00bQGuPlHBlIYLS5YSp/URvgCLMB14=";
    };
  });

  raspberrypifw_20250829 = super.raspberrypifw.overrideAttrs (old: {
    # this release is untagged in the upstream for linux 6.12.44
    version = "unstable_20250829";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "73065c21a0337eac9de13521fc1254cdadd3bd0a";
      hash = "sha256-cprLY/xtYuE2LjgbQGuPlHBlIYLS5YSp/URvgCLMB14=";
    };
  });

  raspberrypifw_20250702 = super.raspberrypifw.overrideAttrs (old: {
    # this release is untagged in the upstream
    # this the the version of the matching stable kernel from `raspberrypi/linux`
    version = "1.20250702";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "7022a895240b2f853d9035ab61616b646caf7b3a";
      hash = "sha256-VpjzwVzjgwBRXIfeGblnPzgjYyw7Nr1GqyjKtGnuduk=";
    };
  });

  raspberrypifw_20250430 = super.raspberrypifw.overrideAttrs (old: rec {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20250430
    version = "1.20250430";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "${version}";
      hash = "sha256-U41EgEDny1R+JFktSC/3CE+2Qi7GJludj929ft49Nm0=";
    };
  });

  raspberrypifw_20250127 = super.raspberrypifw.overrideAttrs (old: rec {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20250127
    version = "1.20250127";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "${version}";
      hash = "sha256-gdZt9xS3X1Prh+TU0DLy6treFoJjiUUUiZ3IoDbopzI=";
    };
  });

  raspberrypifw_20241008 = super.raspberrypifw.overrideAttrs (old: rec {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20241008
    version = "1.20241008";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "${version}";
      hash = "sha256-4gnK0KbqFnjBmWia9Jt2gveVWftmHrprpwBqYVqE/k0=";
    };
  });

  raspberrypifw_20240529 = super.raspberrypifw.overrideAttrs (old: rec {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20240529
    version = "1.20240529";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "${version}";
      hash = "sha256-KsCo7ZG6vKstxRyFljZtbQvnDSqiAPdUza32xTY/tlA=";
    };
  });

  raspberrypifw_20240424 = super.raspberrypifw.overrideAttrs (old: rec {
    # they seem to got back to releases
    # https://github.com/raspberrypi/firmware/releases/tag/1.20240424
    version = "1.20240424";
    # release tarball contains only the files we need
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "${version}";
      hash = "sha256-X5OinkLh/+mx34DM8mCk4tqOGuJdYxkvygv3gA77NJI=";
    };
  });

  raspberrypifw_20240124 = super.raspberrypifw.overrideAttrs (old: {
    version = "stable_20240124";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "4649b6d52005b52b1d23f553b5e466941bc862dc";
      hash = "sha256-K+5QBjsic3c2OTi8ROot3BVDnIrXDjZ4C6k3WKWogxI=";
    };
  });

  # as in nixpkgs-unstable
  raspberrypifw_20231123 = super.raspberrypifw.overrideAttrs (old: {
    version = "stable_20231123";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "524247ac6d8b1f4ddd53730e978a70c76a320bd6";
      hash = "sha256-rESwkR7pc5MTwIZ8PaMUPXuzxfv+jVpdRp8ijvxHGcg=";
    };
  });

  raspberrypiWirelessFirmware_20250408 = super.raspberrypiWirelessFirmware.overrideAttrs (old: {
    version = "2025-04-08";
    srcs = [
      # https://github.com/RPi-Distro/bluez-firmware/commits/bookworm
      # 1.2-9+rpt3 release – 20240226
      (super.fetchFromGitHub {
        name = "bluez-firmware";
        owner = "RPi-Distro";
        repo = "bluez-firmware";
        rev = "78d6a07730e2d20c035899521ab67726dc028e1c";
        hash = "sha256-KakKnOBeWxh0exu44beZ7cbr5ni4RA9vkWYb9sGMb8Q=";
      })
      # https://github.com/RPi-Distro/firmware-nonfree/commits/bookworm/
      (super.fetchFromGitHub {
        name = "firmware-nonfree";
        owner = "RPi-Distro";
        repo = "firmware-nonfree";
        rev = "c9d3ae6584ab79d19a4f94ccf701e888f9f87a53";
        hash = "sha256-5ywIPs3lpmqVOVP3B75H577fYkkucDqB7htY2U1DW8U=";
      })
    ];
  });

  raspberrypiWirelessFirmware_20241223 = super.raspberrypiWirelessFirmware.overrideAttrs (old: {
    version = "2024-12-23";
    srcs = [
      # https://github.com/RPi-Distro/bluez-firmware/commits/bookworm
      # 1.2-9+rpt3 release – 20240226
      (super.fetchFromGitHub {
        name = "bluez-firmware";
        owner = "RPi-Distro";
        repo = "bluez-firmware";
        rev = "78d6a07730e2d20c035899521ab67726dc028e1c";
        hash = "sha256-KakKnOBeWxh0exu44beZ7cbr5ni4RA9vkWYb9sGMb8Q=";
      })
      # https://github.com/RPi-Distro/firmware-nonfree/commits/bookworm/
      (super.fetchFromGitHub {
        name = "firmware-nonfree";
        owner = "RPi-Distro";
        repo = "firmware-nonfree";
        rev = "a6ed59a078d52ad72f0f2b99e68f324e7411afa1";
        hash = "sha256-Yu9hoy4lWQlkjq9LTTmXaLpUKzaEkJaMz9oYmOfbDos=";
      })
    ];
  });

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/firmware/raspberrypi-wireless/default.nix
  # pkgs/os-specific/linux/firmware/raspberrypi-wireless/default.nix
  raspberrypiWirelessFirmware_20240226 = super.raspberrypiWirelessFirmware.overrideAttrs (old: {
    version = "2024-02-26";
    srcs = [
      # https://github.com/RPi-Distro/bluez-firmware/commits/bookworm
      # https://github.com/RPi-Distro/bluez-firmware/tree/78d6a07730e2d20c035899521ab67726dc028e1c
      # 1.2-9+rpt3 release – 20240226
      (super.fetchFromGitHub {
        name = "bluez-firmware";
        owner = "RPi-Distro";
        repo = "bluez-firmware";
        rev = "78d6a07730e2d20c035899521ab67726dc028e1c";
        hash = "sha256-KakKnOBeWxh0exu44beZ7cbr5ni4RA9vkWYb9sGMb8Q=";
      })
      # https://github.com/RPi-Distro/firmware-nonfree/commits/bookworm/
      # https://github.com/RPi-Distro/firmware-nonfree/commit/4b356e134e8333d073bd3802d767a825adec3807
      # 20230625-2+rpt3 release – 20240826
      (super.fetchFromGitHub {
        name = "firmware-nonfree";
        owner = "RPi-Distro";
        repo = "firmware-nonfree";
        rev = "4b356e134e8333d073bd3802d767a825adec3807";
        hash = "sha256-T7eTKXqY9cxEMdab8Snda4CEOrEihy5uOhA6Fy+Mhnw=";
      })
    ];
  });

  raspberrypiWirelessFirmware_20240117 = super.raspberrypiWirelessFirmware.overrideAttrs (old: {
    version = "2024-01-17";
    srcs = [
      # as in nixpkgs-unstable
      # https://github.com/RPi-Distro/bluez-firmware/commits/bookworm
      # 1.2-9+rpt2 release – 20231024
      (super.fetchFromGitHub {
        name = "bluez-firmware";
        owner = "RPi-Distro";
        repo = "bluez-firmware";
        rev = "d9d4741caba7314d6500f588b1eaa5ab387a4ff5";
        hash = "sha256-CjbZ3t3TW/iJ3+t9QKEtM9NdQU7SwcUCDYuTmFEwvhU=";
      })
      # https://github.com/RPi-Distro/firmware-nonfree/commits/bookworm/
      # https://github.com/RPi-Distro/firmware-nonfree/tree/3db4164cfd89e6d9afb7ebc87607b792651512df
      # 1:20230210-5+rpt3 release – 20240117
      (super.fetchFromGitHub {
        name = "firmware-nonfree";
        owner = "RPi-Distro";
        repo = "firmware-nonfree";
        rev = "3db4164cfd89e6d9afb7ebc87607b792651512df";
        hash = "sha256-Qu96GKezjF39bBlYsWhEv6CoIpap1jtHTvcrszZOzzE=";
      })
    ];
  });

  # as in nixpkgs-unstable
  raspberrypiWirelessFirmware_20231115 = super.raspberrypiWirelessFirmware.overrideAttrs (old: {
    version = "unstable-2023-11-15";
    srcs = [
      (super.fetchFromGitHub {  # 1.2-9+rpt2 release – 20231024
        name = "bluez-firmware";
        owner = "RPi-Distro";
        repo = "bluez-firmware";
        rev = "d9d4741caba7314d6500f588b1eaa5ab387a4ff5";
        hash = "sha256-CjbZ3t3TW/iJ3+t9QKEtM9NdQU7SwcUCDYuTmFEwvhU=";
      })
      (super.fetchFromGitHub {  # 1:20230210-5+rpt2 release - 20231115
        name = "firmware-nonfree";
        owner = "RPi-Distro";
        repo = "firmware-nonfree";
        rev = "88aa085bfa1a4650e1ccd88896f8343c22a24055";
        hash = "sha256-Yynww79LPPkau4YDSLI6IMOjH64nMpHUdGjnCfIR2+M=";
      })
    ];
  });

}