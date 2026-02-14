let
  allFirmware = import ./firmware-sources.nix;

  firmwareVersion = pkgs: attrsFor: let
    # Gets date of the release from the `version` which is always on the
    # last position in the list of strings splitted by version separators
    cleanVersion = let
      noDots = builtins.replaceStrings ["." "-"] ["_" "_"] attrsFor.version;
      splittedVersion = (pkgs.lib.splitString "_" noDots);
    in builtins.elemAt splittedVersion ((builtins.length splittedVersion) - 1);
  in {
    "raspberrypifw_${cleanVersion}" = pkgs.raspberrypifw.overrideAttrs (old: {
      inherit (attrsFor) version;
      src = pkgs.fetchFromGitHub {
        owner = "raspberrypi";
        repo = "firmware";

        # rev can be used both for rev hash and the tag
        rev = if (attrsFor ? rev) then attrsFor.rev else attrsFor.tag;
        hash = attrsFor.srcHash;
      };
    });
  };

in self: super:
  super.lib.mergeAttrsList (map (firmwareVersion super) allFirmware) // {

  raspberrypiWirelessFirmware_20251008 = super.raspberrypiWirelessFirmware.overrideAttrs (old: {
    version = "2025-10-02";
    srcs = [
      # https://github.com/RPi-Distro/bluez-firmware/commits/pios/trixie
      # 1.2-13+rpt2 release – 20251002
      (super.fetchFromGitHub {
        name = "bluez-firmware";
        owner = "RPi-Distro";
        repo = "bluez-firmware";
        rev = "cdf61dc691a49ff01a124752bd04194907f0f9cd";
        hash = "sha256-35pnbQV/zcikz9Vic+2a1QAS72riruKklV8JHboL9NY=";
      })
      # https://github.com/RPi-Distro/firmware-nonfree/commits/trixie
      # 20241210-1+rpt3 - 20250930
      (super.fetchFromGitHub {
        name = "firmware-nonfree";
        owner = "RPi-Distro";
        repo = "firmware-nonfree";
        rev = "e90d6888e745eb9ee1aab098fff001edc31b95b7";
        hash = "sha256-+MO0VOwttfTT9hX5lMmMRAaDzmWh2dFxsH/FRDTFzjs";
      })
    ];
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
    __intentionallyOverridingVersion = true;
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
    __intentionallyOverridingVersion = true;
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
    __intentionallyOverridingVersion = true;
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
    __intentionallyOverridingVersion = true;
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
    __intentionallyOverridingVersion = true;
  });

}