{ pkgs, ... }:

{
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
}
