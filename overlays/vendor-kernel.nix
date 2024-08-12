let
  # are drm-rp1-depends-on-instead-of-select-MFD_RP1 and
  # iommu-bcm2712-don-t-allow-building-as-module relevant only for RPi3?
  # see https://github.com/NixOS/nixpkgs/commit/bb51848e23465846f5823d1bacbed808a4469fcd
  drm-rp1-depends-on-instead-of-select-MFD_RP1 = super: {
    # Fix "WARNING: unmet direct dependencies detected for MFD_RP1", and
    # subsequent build failure.
    # https://github.com/NixOS/nixpkgs/pull/268280#issuecomment-1911839809
    # https://github.com/raspberrypi/linux/pull/5900
    name = "drm-rp1-depends-on-instead-of-select-MFD_RP1.patch";
    patch = super.lib.fetchpatch {
      url = "https://github.com/peat-psuwit/rpi-linux/commit/6de0bb51929cd3ad4fa27b2a421a2af12e6468f5.patch";
      hash = "sha256-9pHcbgWTiztu48SBaLPVroUnxnXMKeCGt5vEo9V8WGw=";
    };
  };
  iommu-bcm2712-don-t-allow-building-as-module = super: {
    # Fix `ERROR: modpost: missing MODULE_LICENSE() in <...>/bcm2712-iommu.o`
    # by preventing such code from being built as module.
    # https://github.com/NixOS/nixpkgs/pull/284035#issuecomment-1913015802
    # https://github.com/raspberrypi/linux/pull/5910
    name = "iommu-bcm2712-don-t-allow-building-as-module.patch";
    patch = super.lib.fetchpatch {
      url = "https://github.com/peat-psuwit/rpi-linux/commit/693a5e69bddbcbe1d1b796ebc7581c3597685b1b.patch";
      hash = "sha256-8BYYQDM5By8cTk48ASYKJhGVQnZBIK4PXtV70UtfS+A=";
    };
  };

  gpio-pwm_-_pwm_apply_might_sleep = super: {
    name = "gpio-pwm_-_pwm_apply_might_sleep.patch";
    patch = super.fetchpatch {
      url = "https://github.com/peat-psuwit/rpi-linux/commit/879f34b88c60dd59765caa30576cb5bfb8e73c56.patch";
      hash = "sha256-HlOkM9EFmlzOebCGoj7lNV5hc0wMjhaBFFZvaRCI0lI=";
    };
  };
  ir-rx51_-_pwm_apply_might_sleep = super: {
    name = "ir-rx51_-_pwm_apply_might_sleep.patch";
    patch = super.fetchpatch {
      url = "https://github.com/peat-psuwit/rpi-linux/commit/23431052d2dce8084b72e399fce82b05d86b847f.patch";
      hash = "sha256-UDX/BJCJG0WVndP/6PbPK+AZsfU3vVxDCrpn1kb1kqE=";
    };
  };

  linux_argsOverride = { modDirVersion,tag,srcHash
                       , structuredExtraConfig ? {}, kernelPatches ? [] }: super: rec {
    inherit modDirVersion tag structuredExtraConfig kernelPatches;

    version = "${modDirVersion}-${tag}";
    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "linux";
      rev = tag;
      hash = srcHash;
    };
  };
  linux_v6_6_31_argsOverride = super: linux_argsOverride {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20240529
    modDirVersion = "6.6.31";
    tag = "stable_20240529";
    srcHash = "sha256-UWUTeCpEN7dlFSQjog6S3HyEWCCnaqiUqV5KxCjYink=";
    structuredExtraConfig = with super.lib.kernel; {
      # Workaround https://github.com/raspberrypi/linux/issues/6198
      # Needed because NixOS 24.05+ sets DRM_SIMPLEDRM=y which pulls in
      # DRM_KMS_HELPER=y.
      BACKLIGHT_CLASS_DEVICE = yes;
    };
    kernelPatches = builtins.map (p: p super) [
      # Fix compilation errors due to incomplete patch backport.
      # https://github.com/raspberrypi/linux/pull/6223
      gpio-pwm_-_pwm_apply_might_sleep
      ir-rx51_-_pwm_apply_might_sleep
    ];
  } super;
  linux_v6_6_28_argsOverride = super: linux_argsOverride {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20240423
    modDirVersion = "6.6.28";
    tag = "stable_20240423";
    srcHash = "sha256-mlsDuVczu0e57BlD/iq7IEEluOIgqbZ+W4Ju30E/zhw=";
    structuredExtraConfig = with super.lib.kernel; {
      GPIO_PWM = no;
    };
  } super;
  linux_v6_1_73_argsOverride = super: linux_argsOverride {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20240124
    modDirVersion = "6.1.73";
    tag = "stable_20240124";
    srcHash = "sha256-P4ExzxWqZj+9FZr9U2tmh7rfs/3+iHEv0m74PCoXVuM=";
    kernelPatches = builtins.map (p: p super) [
      drm-rp1-depends-on-instead-of-select-MFD_RP1
      iommu-bcm2712-don-t-allow-building-as-module
    ];
  } super;
  linux_v6_1_63_argsOverride = super: linux_argsOverride {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20231123
    modDirVersion = "6.1.63";
    tag = "stable_20231123";
    srcHash = "sha256-4Rc57y70LmRFwDnOD4rHoHGmfxD9zYEAwYm9Wvyb3no=";
    kernelPatches = builtins.map (p: p super) [
      drm-rp1-depends-on-instead-of-select-MFD_RP1
      iommu-bcm2712-don-t-allow-building-as-module
    ];
  } super;

  linux_v6_6_31_fw = self: {
    linux_rpi4 = self.linux_rpi4_v6_6_31;
    linux_rpi5 = self.linux_rpi5_v6_6_31;
    raspberrypifw = self.raspberrypifw_20240529;
    raspberrypiWirelessFirmware = self.raspberrypiWirelessFirmware_20240226;
  };
  linux_v6_6_28_fw = self: {
    linux_rpi4 = self.linux_rpi4_v6_6_28;
    linux_rpi5 = self.linux_rpi5_v6_6_28;
    raspberrypifw = self.raspberrypifw_20240424;
    raspberrypiWirelessFirmware = self.raspberrypiWirelessFirmware_20240226;
  };
  linux_v6_1_73_fw = self: {
    linux_rpi4 = self.linux_rpi4_v6_1_73;
    linux_rpi5 = self.linux_rpi5_v6_1_73;
    raspberrypifw = self.raspberrypifw_20240124;
    # raspberrypiWirelessFirmware = self.raspberrypiWirelessFirmware_20240117;
    # as seen in https://github.com/NixOS/nixpkgs/pull/292880:
    raspberrypiWirelessFirmware = self.raspberrypiWirelessFirmware_20240226;
  };
  linux_v6_1_63_fw = self: {
    linux_rpi4 = self.linux_rpi4_v6_1_63;
    linux_rpi5 = self.linux_rpi5_v6_1_63;
    raspberrypifw = self.raspberrypifw_20231123;
    raspberrypiWirelessFirmware = self.raspberrypiWirelessFirmware_20231115;
  };
  bundleOverlay = bundle: {
    inherit (bundle) linux_rpi4 linux_rpi5
      raspberrypifw raspberrypiWirelessFirmware;
  };
  # defaultBundle = linux_v6_1_63_fw;
  # defaultBundle = linux_v6_1_73_fw;
  defaultBundle = linux_v6_6_31_fw;
in self: super: (bundleOverlay (defaultBundle self)) // { # final: prev:

  linuxPackages_rpi5 = self.linuxPackagesFor self.linux_rpi5;
  linuxPackages_rpi4 = self.linuxPackagesFor self.linux_rpi4;

  # in nixpkgs this is also in pkgs.linuxKernel.packages.<...>
  # see also https://github.com/NixOS/nixos-hardware/pull/927
  # linux_rpi4_v6_6_28 = super.linux_rpi4.override {
  #   argsOverride = linux_v6_6_28_argsOverride super;
  # };

  # as in https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/linux-kernels.nix#L91

  linux_rpi4_v6_6_31 = super.callPackage ../pkgs/linux-rpi.nix {
    argsOverride = linux_v6_6_31_argsOverride super;
    kernelPatches = with super.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    rpiVersion = 4;
  };
  linux_rpi5_v6_6_31 = super.callPackage ../pkgs/linux-rpi.nix {
    argsOverride = linux_v6_6_31_argsOverride super;
    kernelPatches = with super.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    rpiVersion = 5;
  };

  linux_rpi4_v6_6_28 = super.callPackage ../pkgs/linux-rpi.nix {
    argsOverride = linux_v6_6_28_argsOverride super;
    kernelPatches = with super.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    rpiVersion = 4;
  };
  linux_rpi5_v6_6_28 = super.callPackage ../pkgs/linux-rpi.nix {
    argsOverride = linux_v6_6_28_argsOverride super;
    kernelPatches = with super.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    rpiVersion = 5;
  };

  linux_rpi4_v6_1_73 = super.callPackage ../pkgs/linux-rpi.nix {
    argsOverride = linux_v6_1_73_argsOverride super;
    kernelPatches = with super.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    rpiVersion = 4;
  };
  linux_rpi5_v6_1_73 = super.callPackage ../pkgs/linux-rpi.nix {
    argsOverride = linux_v6_1_73_argsOverride super;
    kernelPatches = with super.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    rpiVersion = 5;
  };

  linux_rpi4_v6_1_63 = super.callPackage ../pkgs/linux-rpi.nix {
    argsOverride = linux_v6_1_63_argsOverride super;
    kernelPatches = with super.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    rpiVersion = 4;
  };
  linux_rpi5_v6_1_63 = super.callPackage ../pkgs/linux-rpi.nix {
    argsOverride = linux_v6_1_63_argsOverride super;
    kernelPatches = with super.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    rpiVersion = 5;
  };

  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/linux-rpi.nix
  # overriding other override like this doesn't work
  # linux_rpi5 = self.linux_rpi4.override {
  #   rpiVersion = 5;
  #   argsOverride.defconfig = "bcm2712_defconfig";
  # };
  # linux_rpi5_v6_6_28 = self.linux_rpi4_v6_6_28.override {
  #   rpiVersion = 5;
  #   argsOverride = (linux_v6_6_28_argsOverride super) // {
  #     defconfig = "bcm2712_defconfig";
  #   };
  # };

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/firmware/raspberrypi/default.nix
  # pkgs/os-specific/linux/firmware/raspberrypi/default.nix
  # https://github.com/raspberrypi/firmware/commits/stable/

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
      # https://github.com/RPi-Distro/firmware-nonfree/tree/223ccf3a3ddb11b3ea829749fbbba4d65b380897
      # 1:20230625-2+rpt2 release – 20240226
      # earlier same date: 1:20230625-2+rpt1 release, 1:20230210-5+rpt4 release
      (super.fetchFromGitHub {
        name = "firmware-nonfree";
        owner = "RPi-Distro";
        repo = "firmware-nonfree";
        rev = "223ccf3a3ddb11b3ea829749fbbba4d65b380897";
        hash = "sha256-BGq0+cr+xBRwQM/LqiQuRWuZpQsKM5jfcrNCqWMuVzM=";
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