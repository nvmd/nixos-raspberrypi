# Package set constructors and package extraction.
{
  lib,
  nixpkgs,
  inputs,
  rpiOverlays,
  systems,
}:

let
  inherit (systems) rpiSystems buildSystems;

  # =========================================================================
  # Memoized nixpkgs instances
  # =========================================================================
  # Each `import nixpkgs { ... }` is expensive (~2-3s). Nix does NOT
  # memoize function applications, so calling `mkRpiPkgs "aarch64-linux"`
  # from two different sites creates two independent evaluations.
  #
  # We solve this by computing each unique (build, target) pair exactly
  # once in a lazy attrset cache. All consumers share the same thunks.

  # Native: buildSystem == targetSystem (building ON the RPi)
  nativePkgsCache = lib.genAttrs rpiSystems (
    system:
    import nixpkgs {
      inherit system;
      overlays = rpiOverlays;
    }
  );

  # Cross: buildSystem != targetSystem (cross-compiling FROM workstation)
  crossPkgsCache = lib.genAttrs buildSystems (
    buildSystem:
    lib.genAttrs (lib.filter (t: t != buildSystem) rpiSystems) (
      targetSystem:
      import nixpkgs {
        localSystem = buildSystem;
        crossSystem = targetSystem;
        overlays = rpiOverlays;
      }
    )
  );

  # Smart lookup: returns the cached pkgs for any (build, target) pair
  pkgsFor =
    { buildSystem, targetSystem }:
    if buildSystem == targetSystem then
      nativePkgsCache.${targetSystem}
    else
      crossPkgsCache.${buildSystem}.${targetSystem};

  # Public aliases (preserving the existing API)
  mkRpiPkgs = system: nativePkgsCache.${system};
  mkCrossRpiPkgs =
    { buildSystem, targetSystem }:
    crossPkgsCache.${buildSystem}.${targetSystem};
  mkRpiPkgsSmart = pkgsFor;

  # Legacy: native-only package sets (for backwards compatibility)
  mkLegacyPackagesFor = nativePkgsCache;

  # Extract the standard set of packages from a pkgs instance
  extractRpiPackages =
    pkgs:
    let
      mkPisugarKmod =
        version:
        (pkgs.linuxPackagesFor pkgs.linux_rpi02).callPackage ../pkgs/pisugar-kmod.nix {
          pisugarVersion = version;
        };
    in
    {
      ffmpeg_7 = pkgs.ffmpeg_7;
      ffmpeg_8 = pkgs.ffmpeg_8;
      ffmpeg_8-headless = pkgs.ffmpeg_8-headless;

      kodi = pkgs.kodi;
      kodi-gbm = pkgs.kodi-gbm;
      kodi-wayland = pkgs.kodi-wayland;

      libcamera = pkgs.libcamera;
      libpisp = pkgs.libpisp;
      libraspberrypi = pkgs.libraspberrypi;

      raspberrypi-utils = pkgs.raspberrypi-utils;
      raspberrypi-udev-rules = pkgs.callPackage ../pkgs/raspberrypi/udev-rules.nix { };
      rpicam-apps = pkgs.rpicam-apps;

      vlc = pkgs.vlc;

      inherit (pkgs.linuxAndFirmware.default)
        linux_rpi5
        linuxPackages_rpi5
        linux_rpi4
        linuxPackages_rpi4
        linux_rpi3
        linuxPackages_rpi3
        linux_rpi02
        linuxPackages_rpi02
        raspberrypifw
        raspberrypiWirelessFirmware
        ;

    }
    // lib.listToAttrs (
      lib.concatMap
        (
          model:
          lib.mapAttrsToList
            (suffix: channel: {
              name = "linux_${model}_${suffix}";
              value = pkgs.linuxAndFirmware.${channel}."linux_${model}";
            })
            {
              stable = "stable";
              latest = "latest";
            }
        )
        [
          "rpi5"
          "rpi4"
          "rpi3"
          "rpi02"
        ]
    )
    // {

      argononed = pkgs.callPackage "${inputs.argononed}/OS/nixos/pkg.nix" { };

      pisugar2-kmod = mkPisugarKmod "2";
      pisugar3-kmod = mkPisugarKmod "3";

      pisugar-power-manager-rs = pkgs.callPackage ../pkgs/pisugar-power-manager-rs.nix { };
    };

in
{
  inherit
    mkRpiPkgs
    mkCrossRpiPkgs
    mkRpiPkgsSmart
    mkLegacyPackagesFor
    extractRpiPackages
    ;
}
