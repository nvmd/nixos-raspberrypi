{ pkgs, ... }:

let
  # Patches

  # are drm-rp1-depends-on-instead-of-select-MFD_RP1 and
  # iommu-bcm2712-don-t-allow-building-as-module relevant only for RPi3?
  # see https://github.com/NixOS/nixpkgs/commit/bb51848e23465846f5823d1bacbed808a4469fcd
  drm-rp1-depends-on-instead-of-select-MFD_RP1 = {
    # Fix "WARNING: unmet direct dependencies detected for MFD_RP1", and
    # subsequent build failure.
    # https://github.com/NixOS/nixpkgs/pull/268280#issuecomment-1911839809
    # https://github.com/raspberrypi/linux/pull/5900
    name = "drm-rp1-depends-on-instead-of-select-MFD_RP1.patch";
    patch = pkgs.fetchpatch {
      url = "https://github.com/peat-psuwit/rpi-linux/commit/6de0bb51929cd3ad4fa27b2a421a2af12e6468f5.patch";
      hash = "sha256-9pHcbgWTiztu48SBaLPVroUnxnXMKeCGt5vEo9V8WGw=";
    };
  };
  iommu-bcm2712-don-t-allow-building-as-module = {
    # Fix `ERROR: modpost: missing MODULE_LICENSE() in <...>/bcm2712-iommu.o`
    # by preventing such code from being built as module.
    # https://github.com/NixOS/nixpkgs/pull/284035#issuecomment-1913015802
    # https://github.com/raspberrypi/linux/pull/5910
    name = "iommu-bcm2712-don-t-allow-building-as-module.patch";
    patch = pkgs.fetchpatch {
      url = "https://github.com/peat-psuwit/rpi-linux/commit/693a5e69bddbcbe1d1b796ebc7581c3597685b1b.patch";
      hash = "sha256-8BYYQDM5By8cTk48ASYKJhGVQnZBIK4PXtV70UtfS+A=";
    };
  };

  gpio-pwm_-_pwm_apply_might_sleep = {
    name = "gpio-pwm_-_pwm_apply_might_sleep.patch";
    patch = pkgs.fetchpatch {
      url = "https://github.com/peat-psuwit/rpi-linux/commit/879f34b88c60dd59765caa30576cb5bfb8e73c56.patch";
      hash = "sha256-HlOkM9EFmlzOebCGoj7lNV5hc0wMjhaBFFZvaRCI0lI=";
    };
  };
  ir-rx51_-_pwm_apply_might_sleep = {
    name = "ir-rx51_-_pwm_apply_might_sleep.patch";
    patch = pkgs.fetchpatch {
      url = "https://github.com/peat-psuwit/rpi-linux/commit/23431052d2dce8084b72e399fce82b05d86b847f.patch";
      hash = "sha256-UDX/BJCJG0WVndP/6PbPK+AZsfU3vVxDCrpn1kb1kqE=";
    };
  };

  # Linux

  linux_v6_12_25_argsOverride = {
    # version of 2025-04-30 seems to be released everywhere else
    # https://github.com/raspberrypi/linux/commit/9e9f366168e12f6edd2fda183b668a84f4a4c8a4
    modDirVersion = "6.12.25";
    tag = "2025-04-30";
    # kernel will be fetched by the rev when it's specified
    rev = "9e9f366168e12f6edd2fda183b668a84f4a4c8a4";
    srcHash = "sha256-qqI2OEYFtovsuCNG+LA3EiaM/7oycZjxA8J0PTyjJEg=";
  };

  linux_v6_6_74_argsOverride = {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20250127
    modDirVersion = "6.6.74";
    tag = "stable_20250127";
    srcHash = "sha256-17PrkPUGBKU+nO40OP+O9dzZeCfRPlKnnk/PJOGamU8=";
  };
  linux_v6_6_51_argsOverride = {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20240529
    modDirVersion = "6.6.51";
    tag = "stable_20241008";
    srcHash = "sha256-phCxkuO+jUGZkfzSrBq6yErQeO2Td+inIGHxctXbD5U=";
  };
  linux_v6_6_31_argsOverride = {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20240529
    modDirVersion = "6.6.31";
    tag = "stable_20240529";
    srcHash = "sha256-UWUTeCpEN7dlFSQjog6S3HyEWCCnaqiUqV5KxCjYink=";
    structuredExtraConfig = with pkgs.lib.kernel; {
      # Workaround https://github.com/raspberrypi/linux/issues/6198
      # Needed because NixOS 24.05+ sets DRM_SIMPLEDRM=y which pulls in
      # DRM_KMS_HELPER=y.
      BACKLIGHT_CLASS_DEVICE = yes;
    };
    kernelPatches = [
      # Fix compilation errors due to incomplete patch backport.
      # https://github.com/raspberrypi/linux/pull/6223
      gpio-pwm_-_pwm_apply_might_sleep
      ir-rx51_-_pwm_apply_might_sleep
    ];
  };
  linux_v6_6_28_argsOverride = {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20240423
    modDirVersion = "6.6.28";
    tag = "stable_20240423";
    srcHash = "sha256-mlsDuVczu0e57BlD/iq7IEEluOIgqbZ+W4Ju30E/zhw=";
    structuredExtraConfig = with pkgs.lib.kernel; {
      GPIO_PWM = no;
    };
  };
  linux_v6_1_73_argsOverride = {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20240124
    modDirVersion = "6.1.73";
    tag = "stable_20240124";
    srcHash = "sha256-P4ExzxWqZj+9FZr9U2tmh7rfs/3+iHEv0m74PCoXVuM=";
    kernelPatches = [
      drm-rp1-depends-on-instead-of-select-MFD_RP1
      iommu-bcm2712-don-t-allow-building-as-module
    ];
  };
  linux_v6_1_63_argsOverride = {
    # https://github.com/raspberrypi/linux/releases/tag/stable_20231123
    modDirVersion = "6.1.63";
    tag = "stable_20231123";
    srcHash = "sha256-4Rc57y70LmRFwDnOD4rHoHGmfxD9zYEAwYm9Wvyb3no=";
    kernelPatches = [
      drm-rp1-depends-on-instead-of-select-MFD_RP1
      iommu-bcm2712-don-t-allow-building-as-module
    ];
  };
in {
  "6_12_25" = linux_v6_12_25_argsOverride;
  "6_6_74" = linux_v6_6_74_argsOverride;
  "6_6_51" = linux_v6_6_51_argsOverride;
  "6_6_31" = linux_v6_6_31_argsOverride;
  "6_6_28" = linux_v6_6_28_argsOverride;
  "6_1_73" = linux_v6_1_73_argsOverride;
  "6_1_63" = linux_v6_1_63_argsOverride;
}