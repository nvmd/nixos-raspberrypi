# Overlay output attrset and canonical RPi overlay list.
let
  outputOverlays = {
    bootloader = import ./bootloader.nix;

    pkgs = import ./pkgs.nix;
    vendor-pkgs = import ./vendor-pkgs.nix;
    jemalloc-page-size-16k = import ./jemalloc-page-size-16k.nix;

    vendor-firmware = import ./vendor-firmware.nix;
    vendor-kernel = import ./vendor-kernel.nix;

    kernel-and-firmware = import ./linux-and-firmware.nix;

    libpisp-default-config-path = import ./libpisp-default-config-path.nix;

    cross-fixes = import ./cross-fixes.nix;
  };

  # Ordered list of overlays applied to RPi package sets.
  # Order matters — dependency chain:
  #   cross-fixes: must be first (fixes cross-compilation issues for all subsequent overlays)
  #   pkgs: ffmpeg/kodi/vlc/libcamera overrides (no kernel deps)
  #   bootloader: bootloader config (no kernel deps)
  #   vendor-kernel: defines linux_rpiN_vX_Y_Z kernels
  #   vendor-firmware: defines raspberrypifw_YYYYMMDD firmware versions
  #   kernel-and-firmware: bundles kernels + firmware (depends on vendor-kernel + vendor-firmware)
  #   vendor-pkgs: packages that may depend on kernel/firmware selections
  rpiOverlaysList = with outputOverlays; [
    cross-fixes
    pkgs
    bootloader
    vendor-kernel
    vendor-firmware
    kernel-and-firmware
    vendor-pkgs
  ];

in
{
  inherit outputOverlays rpiOverlaysList;
}
