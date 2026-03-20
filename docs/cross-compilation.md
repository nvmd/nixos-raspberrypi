# Cross-Compilation Guide

Build Raspberry Pi packages and installer images from x86_64 (AMD64) workstations using native cross-compilers.

## Table of Contents

- [Introduction](#introduction)
- [Why Cross-Compilation?](#why-cross-compilation)
- [Quick Start](#quick-start)
- [Building Packages](#building-packages)
  - [Package Structure](#package-structure)
  - [Target Systems](#target-systems)
  - [Examples](#package-examples)
- [Building Installer Images](#building-installer-images)
  - [Cross-Compiled Images](#cross-compiled-images)
  - [Native Images](#native-images)
- [Building NixOS Configurations](#building-nixos-configurations)
- [How It Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Conclusion](#conclusion)

## Introduction

This flake supports true cross-compilation, allowing you to build Raspberry Pi packages and NixOS images directly on your x86_64 (AMD64) workstation without requiring:

- A physical Raspberry Pi for building
- QEMU binfmt_misc emulation (which is extremely slow)
- Remote build machines

Cross-compilation uses your workstation's native CPU to run cross-compiler toolchains (e.g., `aarch64-unknown-linux-gnu-gcc`) that produce ARM binaries directly.

## Why Cross-Compilation?

### The Problem with binfmt Emulation

When Nix builds for a different architecture without proper cross-compilation setup, it falls back to **binfmt_misc emulation**. This means every single build command runs under QEMU user-mode emulation, which is:

- **Extremely slow**: 10-100x slower than native compilation
- **Resource intensive**: High CPU usage for emulation overhead
- **Unreliable**: Some packages fail tests or builds under emulation

### The Cross-Compilation Solution

True cross-compilation tells Nix:
- **localSystem**: Where we BUILD (your x86_64 workstation)
- **crossSystem**: Where binaries RUN (the Raspberry Pi)

This uses native x86_64 cross-compiler toolchains to produce ARM binaries directly - no emulation during the build process.

### Performance Comparison

| Method | Kernel Build Time | Notes |
|--------|-------------------|-------|
| Native (on Pi 5) | ~45 minutes | Limited by Pi's CPU |
| binfmt emulation | Several hours | Every command emulated |
| Cross-compilation | ~10-15 minutes | Uses full x86_64 power |

## Quick Start

```bash
# Cross-compile the RPi 5 kernel from your x86_64 workstation:
nix build .#packages.x86_64-linux.linux_rpi5

# Cross-compile an RPi 5 installer image:
nix build .#installerImagesCross.x86_64-linux.rpi5
```

## Building Packages

### Package Structure

Packages are organized by **build system** (where you compile):

```
packages.<buildSystem>.<package>                          # Flat, aarch64-linux target (default)
legacyPackages.<buildSystem>.<targetSystem>.<package>     # Explicit target architecture
```

### Target Systems

| Target System | Raspberry Pi Models |
|---------------|---------------------|
| `aarch64-linux` | Pi 4, Pi 5, Pi 400, CM4 (64-bit) |
| `armv7l-linux` | Pi 2, Pi 3 (32-bit mode) |
| `armv6l-linux` | Pi Zero, Pi 1, Pi Zero W |

### Package Examples

**Cross-compile from x86_64 for aarch64 (most common):**

```bash
# Targeting aarch64-linux (RPi 4/5) — the default target:
nix build .#packages.x86_64-linux.linux_rpi5
```

**Build for different target architectures (via legacyPackages):**

```bash
# For 32-bit Pi 2/3:
nix build .#legacyPackages.x86_64-linux.armv7l-linux.linux_rpi3

# For Pi Zero/1:
nix build .#legacyPackages.x86_64-linux.armv6l-linux.linux_rpi02
```

**Native build (on aarch64 machine or Pi itself):**

```bash
nix build .#packages.aarch64-linux.linux_rpi5
```

**Available packages** (in `packages.<buildSystem>.*`):

```bash
# Kernels and firmware (default = stable channel)
linux_rpi5 linux_rpi4 linux_rpi3 linux_rpi02
raspberrypifw raspberrypiWirelessFirmware

# Stable channel kernels (= default)
linux_rpi5_stable linux_rpi4_stable linux_rpi3_stable linux_rpi02_stable

# Latest channel kernels
linux_rpi5_latest linux_rpi4_latest linux_rpi3_latest linux_rpi02_latest

# Media
ffmpeg_7 ffmpeg_8 ffmpeg_8-headless
kodi kodi-gbm kodi-wayland
vlc

# Camera/Graphics
libcamera libpisp rpicam-apps

# Utilities
libraspberrypi raspberrypi-utils raspberrypi-udev-rules

# Other
argononed pisugar-power-manager-rs pisugar2-kmod pisugar3-kmod
```

Additionally, `legacyPackages` includes `linuxPackages_rpi{5,4,3,02}` (attrsets, not individual derivations) and provides explicit target architecture selection.

## Building Installer Images

### Cross-Compiled Images

Use `installerImagesCross` to build SD card images from any supported build system:

```bash
# From x86_64 workstation:
nix build .#installerImagesCross.x86_64-linux.rpi5
nix build .#installerImagesCross.x86_64-linux.rpi4
nix build .#installerImagesCross.x86_64-linux.rpi3
nix build .#installerImagesCross.x86_64-linux.rpi02

# From aarch64 machine (native):
nix build .#installerImagesCross.aarch64-linux.rpi5
```

The resulting image will be in `./result/sd-image/`.

### Native Images

The original `installerImages` output still exists for backwards compatibility:

```bash
# Requires aarch64 machine OR binfmt emulation configured:
nix build .#installerImages.rpi5
```

## Building NixOS Configurations

When creating your own NixOS configurations, you can enable cross-compilation by passing `buildPlatform`:

```nix
# In your flake.nix:
nixosConfigurations.my-rpi5 = nixos-raspberrypi.lib.nixosSystem {
  # Enable cross-compilation from x86_64:
  buildPlatform = "x86_64-linux";

  specialArgs = { inherit inputs; nixos-raspberrypi = inputs.nixos-raspberrypi; };
  modules = [
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    # ... your other modules
  ];
};
```

This works with all the library functions:
- `nixos-raspberrypi.lib.nixosSystem`
- `nixos-raspberrypi.lib.nixosSystemFull`
- `nixos-raspberrypi.lib.nixosInstaller`

Then build from your x86_64 workstation:

```bash
nix build .#nixosConfigurations.my-rpi5.config.system.build.toplevel
```

## How It Works

### Under the Hood

When you run `nix build .#packages.x86_64-linux.linux_rpi5`:

1. **Detection**: The flake detects `buildSystem = "x86_64-linux"` and `targetSystem = "aarch64-linux"`

2. **Cross-compilation setup**: Since they differ, Nix is configured with:
   ```nix
   import nixpkgs {
     localSystem = "x86_64-linux";   # Your workstation
     crossSystem = "aarch64-linux";  # Target Pi
     overlays = [ ... ];
   }
   ```

3. **Toolchain selection**: Nix uses the cross-compiler toolchain:
   - `aarch64-unknown-linux-gnu-gcc` for C/C++
   - `aarch64-unknown-linux-gnu-ld` for linking
   - etc.

4. **Native execution**: All build commands run natively on x86_64 - only the *output* is for aarch64

### Key Nix Concepts

| Parameter | Meaning |
|-----------|---------|
| `localSystem` | The system where compilation happens (your workstation) |
| `crossSystem` | The system where binaries will run (the Pi) |
| `system` | Shorthand when localSystem == crossSystem (native build) |

## Troubleshooting

### Build Failures

Some packages may have issues with cross-compilation. Common solutions:

1. **Check the binary cache first**: Many packages are pre-built
   ```bash
   nix build .#packages.x86_64-linux.linux_rpi5 --print-build-logs
   ```

2. **Disable problematic tests**: Some test suites don't work during cross-compilation. The flake already disables tests for known problematic packages.

3. **Use native build as fallback**: If a specific package fails, you can build it on the Pi itself or use binfmt.

### Missing Cross-Compiler

If you see errors about missing cross-compilers, ensure your nixpkgs has cross-compilation support (it should by default in recent versions).

### Memory Issues

Cross-compiling large packages (like the kernel) can use significant memory. Ensure you have adequate RAM or swap:

```bash
# Check available memory
free -h

# For kernel builds, recommend 8GB+ RAM
```

## Conclusion

Cross-compilation enables efficient Raspberry Pi development from powerful x86_64 workstations. Key benefits:

- **Speed**: Build times reduced from hours to minutes
- **Convenience**: No need for physical Pi during development
- **Reliability**: Native compilation is more stable than emulation
- **Flexibility**: Build for any Pi variant from one machine

### Summary of Commands

| Task | Command |
|------|---------|
| Cross-compile kernel | `nix build .#packages.x86_64-linux.linux_rpi5` |
| Cross-compile installer | `nix build .#installerImagesCross.x86_64-linux.rpi5` |
| List available packages | `nix eval .#packages.x86_64-linux --apply builtins.attrNames` |
| Build with logs | `nix build .#packages.x86_64-linux.linux_rpi5 --print-build-logs` |

For questions or issues, please open an issue on the repository.
