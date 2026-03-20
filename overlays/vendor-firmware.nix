let
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/firmware/raspberrypi/default.nix
  # https://github.com/raspberrypi/firmware/commits/stable/
  # See `extra/git_hash` for a matching hash of the `raspberrypi/linux`

  firmwareVersions = {
    "20250915" = {
      version = "1.20250915";
      rev = "676efed1194de38975889a34276091da1f5aadd3";
      hash = "sha256-DqVgsPhppxCsZ+H6S7XY5bBoRhOgPipKibDwikqBk08=";
    };
    "20250829" = {
      version = "unstable_20250829";
      rev = "73065c21a0337eac9de13521fc1254cdadd3bd0a";
      hash = "sha256-cprLY/xtYuE2LjgbQGuPlHBlIYLS5YSp/URvgCLMB14=";
    };
    "20250702" = {
      version = "1.20250702";
      rev = "7022a895240b2f853d9035ab61616b646caf7b3a";
      hash = "sha256-VpjzwVzjgwBRXIfeGblnPzgjYyw7Nr1GqyjKtGnuduk=";
    };
    "20250430" = {
      version = "1.20250430";
      rev = "1.20250430";
      hash = "sha256-U41EgEDny1R+JFktSC/3CE+2Qi7GJludj929ft49Nm0=";
    };
    "20250127" = {
      version = "1.20250127";
      rev = "1.20250127";
      hash = "sha256-gdZt9xS3X1Prh+TU0DLy6treFoJjiUUUiZ3IoDbopzI=";
    };
    "20241008" = {
      version = "1.20241008";
      rev = "1.20241008";
      hash = "sha256-4gnK0KbqFnjBmWia9Jt2gveVWftmHrprpwBqYVqE/k0=";
    };
    "20240529" = {
      version = "1.20240529";
      rev = "1.20240529";
      hash = "sha256-KsCo7ZG6vKstxRyFljZtbQvnDSqiAPdUza32xTY/tlA=";
    };
    "20240424" = {
      version = "1.20240424";
      rev = "1.20240424";
      hash = "sha256-X5OinkLh/+mx34DM8mCk4tqOGuJdYxkvygv3gA77NJI=";
    };
    "20240124" = {
      version = "stable_20240124";
      rev = "4649b6d52005b52b1d23f553b5e466941bc862dc";
      hash = "sha256-K+5QBjsic3c2OTi8ROot3BVDnIrXDjZ4C6k3WKWogxI=";
    };
    "20231123" = {
      version = "stable_20231123";
      rev = "524247ac6d8b1f4ddd53730e978a70c76a320bd6";
      hash = "sha256-rESwkR7pc5MTwIZ8PaMUPXuzxfv+jVpdRp8ijvxHGcg=";
    };
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/firmware/raspberrypi-wireless/default.nix
  wirelessFirmwareVersions = {
    "20251008" = {
      version = "2025-10-02";
      bluez = {
        rev = "cdf61dc691a49ff01a124752bd04194907f0f9cd";
        hash = "sha256-35pnbQV/zcikz9Vic+2a1QAS72riruKklV8JHboL9NY=";
      };
      nonfree = {
        rev = "e90d6888e745eb9ee1aab098fff001edc31b95b7";
        hash = "sha256-+MO0VOwttfTT9hX5lMmMRAaDzmWh2dFxsH/FRDTFzjs";
      };
    };
    "20250408" = {
      version = "2025-04-08";
      bluez = {
        rev = "78d6a07730e2d20c035899521ab67726dc028e1c";
        hash = "sha256-KakKnOBeWxh0exu44beZ7cbr5ni4RA9vkWYb9sGMb8Q=";
      };
      nonfree = {
        rev = "c9d3ae6584ab79d19a4f94ccf701e888f9f87a53";
        hash = "sha256-5ywIPs3lpmqVOVP3B75H577fYkkucDqB7htY2U1DW8U=";
      };
    };
    "20241223" = {
      version = "2024-12-23";
      bluez = {
        rev = "78d6a07730e2d20c035899521ab67726dc028e1c";
        hash = "sha256-KakKnOBeWxh0exu44beZ7cbr5ni4RA9vkWYb9sGMb8Q=";
      };
      nonfree = {
        rev = "a6ed59a078d52ad72f0f2b99e68f324e7411afa1";
        hash = "sha256-Yu9hoy4lWQlkjq9LTTmXaLpUKzaEkJaMz9oYmOfbDos=";
      };
    };
    "20240226" = {
      version = "2024-02-26";
      bluez = {
        rev = "78d6a07730e2d20c035899521ab67726dc028e1c";
        hash = "sha256-KakKnOBeWxh0exu44beZ7cbr5ni4RA9vkWYb9sGMb8Q=";
      };
      nonfree = {
        rev = "4b356e134e8333d073bd3802d767a825adec3807";
        hash = "sha256-T7eTKXqY9cxEMdab8Snda4CEOrEihy5uOhA6Fy+Mhnw=";
      };
    };
    "20240117" = {
      version = "2024-01-17";
      bluez = {
        rev = "d9d4741caba7314d6500f588b1eaa5ab387a4ff5";
        hash = "sha256-CjbZ3t3TW/iJ3+t9QKEtM9NdQU7SwcUCDYuTmFEwvhU=";
      };
      nonfree = {
        rev = "3db4164cfd89e6d9afb7ebc87607b792651512df";
        hash = "sha256-Qu96GKezjF39bBlYsWhEv6CoIpap1jtHTvcrszZOzzE=";
      };
    };
    "20231115" = {
      version = "unstable-2023-11-15";
      bluez = {
        rev = "d9d4741caba7314d6500f588b1eaa5ab387a4ff5";
        hash = "sha256-CjbZ3t3TW/iJ3+t9QKEtM9NdQU7SwcUCDYuTmFEwvhU=";
      };
      nonfree = {
        rev = "88aa085bfa1a4650e1ccd88896f8343c22a24055";
        hash = "sha256-Yynww79LPPkau4YDSLI6IMOjH64nMpHUdGjnCfIR2+M=";
      };
    };
  };

  mkFirmware =
    prev: date: spec:
    prev.raspberrypifw.overrideAttrs {
      inherit (spec) version;
      src = prev.fetchFromGitHub {
        owner = "raspberrypi";
        repo = "firmware";
        inherit (spec) rev hash;
      };
    };

  # __intentionallyOverridingVersion silences the nixpkgs warning about
  # overriding the version attribute on a package with a different version
  # string format than the original.
  mkWirelessFirmware =
    prev: date: spec:
    prev.raspberrypiWirelessFirmware.overrideAttrs {
      inherit (spec) version;
      srcs = [
        (prev.fetchFromGitHub {
          name = "bluez-firmware";
          owner = "RPi-Distro";
          repo = "bluez-firmware";
          inherit (spec.bluez) rev hash;
        })
        (prev.fetchFromGitHub {
          name = "firmware-nonfree";
          owner = "RPi-Distro";
          repo = "firmware-nonfree";
          inherit (spec.nonfree) rev hash;
        })
      ];
      __intentionallyOverridingVersion = true;
    };

in
final: prev:
prev.lib.mapAttrs' (
  date: spec: prev.lib.nameValuePair "raspberrypifw_${date}" (mkFirmware prev date spec)
) firmwareVersions
// prev.lib.mapAttrs' (
  date: spec:
  prev.lib.nameValuePair "raspberrypiWirelessFirmware_${date}" (mkWirelessFirmware prev date spec)
) wirelessFirmwareVersions
