# FFmpeg for Raspberry Pi

## Overview

This flake provides **Raspberry Pi-optimized builds of FFmpeg**, built from the [official RPi FFmpeg fork](https://github.com/jc-kynesim/rpi-ffmpeg) maintained by John Cox (jc-kynesim). These are **not** the same as upstream FFmpeg from nixpkgs — the source code itself contains RPi-specific patches for hardware-accelerated video processing.

## Available Versions

| Package | Version | Source |
|---------|---------|--------|
| `ffmpeg_8` | 8.0 | [jc-kynesim/rpi-ffmpeg `n8.0`](https://github.com/jc-kynesim/rpi-ffmpeg/releases/tag/n8.0) |
| `ffmpeg_7` | 7.1.2 | [jc-kynesim/rpi-ffmpeg `test/7.1.2/main`](https://github.com/jc-kynesim/rpi-ffmpeg/tree/test/7.1.2/main) |

Each version is available in three variants:
- `ffmpeg_8` — default (small) build
- `ffmpeg_8-headless` — no display/GUI dependencies
- `ffmpeg_8-full` — all optional features enabled

## RPi-Specific Features

These builds enable hardware acceleration features specific to the Raspberry Pi's VideoCore GPU and V4L2 subsystem:

| Flag | Purpose |
|------|---------|
| `--enable-sand` | RPi's proprietary "sand" pixel format for zero-copy video pipelines with the VideoCore GPU |
| `--enable-vout-drm` | RPi-specific DRM video output path |
| `--enable-v4l2-request` | V4L2 stateless (request) API for hardware-accelerated video decode |
| `--enable-neon` | ARM NEON SIMD optimizations |
| `--enable-libudev` | Required by V4L2 request API |

Disabled features (not applicable to RPi hardware):
- `--disable-mmal` — legacy Broadcom MMAL API, superseded by V4L2
- `--disable-vaapi` — no VA-API support on RPi hardware

## Adding RPi FFmpeg to Your Raspberry Pi Image

There are several ways to get the RPi-optimized FFmpeg onto your Raspberry Pi, depending on how much of your system you want it to affect.

### Option 1: Use `nixosSystemFull` (recommended for most users)

If you build your NixOS configuration with `nixos-raspberrypi.lib.nixosSystemFull`, the RPi FFmpeg overlay is **already applied globally** — `ffmpeg` throughout your entire system is the RPi-optimized version. Everything that depends on FFmpeg (pipewire, vlc, etc.) will be rebuilt against it.

```nix
# In your flake.nix:
nixosConfigurations.my-rpi5 = nixos-raspberrypi.lib.nixosSystemFull {
  specialArgs = { nixos-raspberrypi = inputs.nixos-raspberrypi; };
  modules = [
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    # ... your other modules
    # ffmpeg is already the RPi fork everywhere — no extra config needed
  ];
};
```

Many of the rebuilt packages are available from the [binary cache](https://nixos-raspberrypi.cachix.org), so in practice you won't need to compile them locally.

### Option 2: Add it alongside system FFmpeg (no global replacement)

If you use `nixos-raspberrypi.lib.nixosSystem` (without `Full`), the system FFmpeg is left untouched. You can install the RPi version as an additional package:

```nix
nixosConfigurations.my-rpi5 = nixos-raspberrypi.lib.nixosSystem {
  specialArgs = { nixos-raspberrypi = inputs.nixos-raspberrypi; };
  modules = [
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base

    ({ pkgs, ... }: {
      # Install RPi ffmpeg alongside the system default
      environment.systemPackages = [
        inputs.nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.ffmpeg_8
      ];
    })
  ];
};
```

This gives you the `ffmpeg` command from the RPi fork in your PATH, but other packages (pipewire, etc.) still use upstream FFmpeg. Useful when you only need hardware-accelerated transcoding from the command line.

### Option 3: Apply the overlay selectively

If you want fine-grained control, apply the `pkgs` overlay to your NixOS configuration manually. This replaces `ffmpeg` globally (same as `nixosSystemFull`) but lets you choose exactly which overlays to include:

```nix
# In a NixOS module:
{
  imports = [
    nixos-raspberrypi.lib.inject-overlays-global
  ];
}
```

### Option 4: Build standalone (without a NixOS config)

```bash
# Cross-compile from x86_64:
nix build .#packages.x86_64-linux.ffmpeg_8

# Native build on aarch64:
nix build .#packages.aarch64-linux.ffmpeg_8
```

The resulting binary is in `./result/bin/ffmpeg` and can be copied to any aarch64-linux system.

### Which option should I pick?

| Approach | Global replacement? | Rebuilds? | Best for |
|----------|-------------------|-----------|----------|
| `nixosSystemFull` | Yes | Yes (cached) | Full media systems (Kodi, VLC, etc.) |
| Standalone package | No | No | CLI transcoding only |
| Manual overlay | Yes | Yes (cached) | Custom overlay composition |
| `nix build` | N/A | N/A | Testing, one-off builds |

## Upstream vs RPi Fork

| | Upstream (nixpkgs) | RPi fork (this flake) |
|---|---|---|
| **Source** | [FFmpeg/FFmpeg](https://github.com/FFmpeg/FFmpeg) | [jc-kynesim/rpi-ffmpeg](https://github.com/jc-kynesim/rpi-ffmpeg) |
| **Hardware accel** | Generic (VA-API, VDPAU, NVENC) | RPi VideoCore (sand, V4L2 request, DRM output) |
| **Target** | All Linux platforms | Raspberry Pi (aarch64/armv7l) |
| **Zero-copy decode** | No | Yes (via sand pixel format) |
