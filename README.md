# nixos-raspberrypi

Unopinionated Nix flake for infrastructure, vendor packages, kernel, and some optimized third-party packages for [NixOS](https://nixos.org/) running on Raspberry Pi devices.

It will let you deploy [NixOS](https://nixos.org/) fully declaratively in one step with tools like [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/) (note: `kexec` is, unfortunately, not supported)

## Provides bootloader infrastructure

Manages Raspberry Pi firmware partition `/boot/firmware` (the path is configurable with `boot.loader.raspberryPi.firmwarePath`).

Partition provisioning is integrated with bootloader activation scripts, happening on NixOS generation switch, enabling to use deployment tools like `nixos-anywhere` without any interactive intervention.

Supported boot methods (configurable with `boot.loader.raspberryPi.bootloader`):
- `kernelboot` (legacy), default for RPi5
- `uboot`, default bootloader for all other boards
- `kernel`, new generation of `kernelboot`, supporting multiple NixOS generations (see #60), default for RPi5 sd-image/installer images, _recommended_ for new installations.


## Provides vendor kernel packages with matched firmware

`pkgs.linuxAndFirmware.default` contains compatible:
```nix
linuxPackages_rpi<board model>  # Linux kernel
raspberrypifw                   # Raspberry firmware, device trees (DTBs), device overlays
raspberrypiWirelessFirmware     # wireless firmware
```

Latest stable version compatible with the board is selected in the flake module by default.

## Provides 3rd-party optimised packages

overlays, containing vendor, and optimized packages, like `libcamera`, `ffmpeg`, etc.

# Usage

## Adding flake input

```nix
inputs = {
  # follow `main` branch of this repository, considered being stable
  nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
};

# Optional: Binary cache for the flake
nixConfig = {
  extra-substituters = [
    "https://nixos-raspberrypi.cachix.org"
  ];
  extra-trusted-public-keys = [
    "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
  ];
};
```

## Using the flake to create NixOS configuration

There're helper functions intended to be used as a drop-in replacement for
`nixpkgs.lib.nixosSystem`:

- `nixos-raspberrypi.lib.nixosSystem`
- `nixos-raspberrypi.lib.nixosSystemFull` - same as above, but with RPi-optimized overlays applied globally, this may lead to more rebuilds
- `nixos-raspberrypi.lib.nixosInstaller` - same as `nixosSystemFull` but with additional installer-specific modules

All of them take the following additional optional arguments:

- `nixpkgs` – default = nixpkgs of the `nixos-raspberrypi` will be used
- `trustCaches` – default=true, trust binary caches of `nixos-raspberrypi`

```nix
nixosConfigurations.rpi5-demo = nixos-raspberrypi.lib.nixosSystem {
  specialArgs = inputs;
  modules = [
    {
      # Hardware specific configuration, see section below for a more complete 
      # list of modules
      imports = with nixos-raspberrypi.nixosModules; [
        raspberry-pi-5.base
        raspberry-pi-5.display-vc4
        raspberry-pi-5.bluetooth
      ];
    }

    ({ config, pkgs, lib, ... }: {
      networking.hostName = "rpi5-demo";

      system.nixos.tags = let
        cfg = config.boot.loader.raspberryPi;
      in [
        "raspberry-pi-${cfg.variant}"
        cfg.bootloader
        config.boot.kernelPackages.kernel.version
      ];
    })

    # ...

  ];
};
```

See also: <https://github.com/nvmd/nixos-raspberrypi-demo>, [Installers and examples](#installer-configurations-and-configuration-examples).

## Choosing modules corresponding to your hardware

See `flake.nix`, `nixosModules` for a full list of configuration modules for your hardware.
Here is the list of the most important:

```nix
imports = with nixos-raspberrypi.nixosModules; [
  # Base board support modules
  raspberry-pi-02.base
  raspberry-pi-3.base
  raspberry-pi-4.base
  raspberry-pi-5.base

  # (Potentially) All boards
  usb-gadget-ethernet # Configures USB Gadget/Ethernet - Ethernet emulation over USB

  # RPi4:
  # import this if you have the display, on rpi4 this is the only display configuration option
  raspberry-pi-4.display-vc4

  # RPi5:
  # use one of following for the "PrimaryGPU" configuration:
  raspberry-pi-5.display-vc4  # "regular" display connected
  raspberry-pi-5.display-rp1  # for RP1-connected (DPI/composite/MIPI DSI) display
];
```

## Configure the bootloader and firmware (`config.txt`)

Sane default configuration is provided by the base module for a corresponding Raspberry board, but further configuration is, of course, possible:

Configuration options for the bootloader are in `boot.loader.raspberryPi` (defined in `modules/system/boot/loader/raspberrypi/default.nix`).

Raspberry's `config.txt` can be configured with `hardware.raspberry-pi.config` options, see `modules/configtxt.nix` as an example (this is the default configuration as provided by RaspberryPi OS, but translated to nix format).

## Options for advanced usage

Options for a more fine-grained control:

- see implementation details in `lib/default.nix`, `lib/internal.nix`
- Use `nixos-raspberrypi.lib.int.nixosSystemRPi` instead of `nixos-raspberrypi.lib.nixosSystem`
- Use regular `nixpkgs.lib.nixosSystem` importing the modules manually, see
below

```nix
imports = with nixos-raspberrypi.nixosModules; [

  # Required: Add necessary overlays with kernel, firmware, vendor packages
  nixos-raspberrypi.lib.inject-overlays

  # Binary cache with prebuilt packages for the currently locked `nixpkgs`,
  # see `devshells/nix-build-to-cachix.nix` for a list
  trusted-nix-caches

  # Optional: All RPi and RPi-optimised packages to be available in `pkgs.rpi`
  nixpkgs-rpi

  # Optonal: add overlays with optimised packages into the global scope
  # provides: ffmpeg_{4,6,7}, kodi, libcamera, vlc, etc.
  # This overlay may cause lots of rebuilds (however many 
  #  packages should be available from the binary cache)
  nixos-raspberrypi.lib.inject-overlays-global
];
```

# Installer configurations

The flake provides installation SD card images for Raspberry Pi Zero2, 3, 4, and 5, based on <https://github.com/nix-community/nixos-images>. They have several advantages over the "standard" ones, making the installation more user-friendly: mDNS enabled, `iwd` for easier wlan configuration, etc.

Note: these images are mutable, i.e. they're suitable to be used both as an installation media, and as a ready to use system on the sd-card. The partition table will be expanded to use all the available space during the first boot.
This can helpful for boards with a single storage device option, like RPi Zero/Zero 2.

> [!TIP]
> installer images use new generational bootloader for RPi5 by default (see #60),
> to keep that in your configuration, set `boot.loader.raspberryPi.bootloader = "kernel"`.
> This is _recommended_ for new installations.

See `nixosConfigurations.rpi{02,4,5}-installer` in `flake.nix`.

SD image can be built with:

```
nix build .#installerImages.rpi02
nix build .#installerImages.rpi3
nix build .#installerImages.rpi4
nix build .#installerImages.rpi5
```

Randomly generated connection credentials will be displayed on the screen, once the system is booted.

Network access to Raspberry Pi Zero2 (RPi02) boards is also possible via USB Gadget/Ethernet functionality.

> [!TIP]
> You can optionally replace `# YOUR SSH PUB KEY HERE #` in `custom-user-config`
> with your SSH public key to generate the image with your SSH key already baked in

`.#nixosConfigurations.rpi{02,4,5}-installer.config.system.build.toplevel` are included in the binary cache.

# NixOS configuration examples

Sophisticated demo configurations are available in <https://github.com/nvmd/nixos-raspberrypi-demo>.

Installer configurations can also double as the configuration examples.

# Deployment

for example, with `nixos-anywhere` to the system running installer image (will use [disko](https://github.com/nix-community/disko/) to set the disks up):

```shell
nixos-anywhere --flake .#<system> root@<hostname>"
```

or, to an already running system (to change configuration of it):

```shell
nixos-rebuild switch --flake .#<system> --target-host root@<hostname>
```

# Alternative ways to get individual packages

An alternative ways to consume individual packages without overlays are:

- to get it directly from the flake, it will based on stable `nixpkgs` _without_ any of other optimisations transitively applied (i.e. only this particular package is optimised):

```nix
  environment.systemPackages = [
    nixos-raspberrypi.packages.aarch64-linux.vlc
  ];
```

- to get it from `nixos-raspberrypi.legacyPackages.<system>`. Here all overlays are applied.

# Design goals

This is basically [`boot.loader.raspberryPi` options](https://search.nixos.org/options?channel=unstable&show=boot.loader.raspberryPi), which are deprecated in nixpkgs, but updated and improved upon.

Design objectives:

- individually consumable modules and overlays for specific functions
- reuse of the existing nixos/nixpkgs infrastructure and idiomatic approaches to the maximum extent possible
- integration with the existing nixos system activation

## Historical background

This project grew naturally out of the need to configure and extend rather great [tstat's raspberry pi support repository](https://github.com/tstat/raspberry-pi-nix), which we used for some time.

Unfortunately it was virtually possible to work with without reengineering the whole thing, so this Flake was born. Inability to use it non-interactively with `nixos-anywhere` was the biggest concern.

We found [`boot.loader.raspberryPi` options](https://search.nixos.org/options?channel=unstable&show=boot.loader.raspberryPi) to be much more idiomatic, easier to extend, and maintain.

This flake strives to keep and improve those properties by keeping it as unopinionated as possible and modular (see [above](#design-goals))

We're still using some ot the modules provided by an adapted fork of tstat/raspberry-pi-nix, namely `config.txt` generation module.
