{
  sources ? import ./npins,
  nixpkgs ? sources.nixpkgs,
  argononed ? sources.argononed,
  nixos-images ? sources.nixos-images,
  ...
}:
let
  lib' = (import nixpkgs { }).lib;

  # Taken from the nixos-images flake
  sdimage-installer = (
    {
      pkgs,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/sd-card/sd-image-aarch64-installer.nix")
        "${nixos-images}/nix/image-installer/module.nix"
      ];
    }
    // (
      if lib.versionAtLeast lib.version "25.03pre" then
        {
          image.baseName = lib.mkForce "nixos-installer-${pkgs.system}";
        }
      else
        {
          sdImage.imageName = lib.mkForce "nixos-installer-${pkgs.system}.img";
        }
    )
  );

  rpiSystems = [
    "aarch64-linux"
    "armv7l-linux"
    "armv6l-linux"
  ];
  forSystems = systems: f: lib'.genAttrs systems (system: f system);
  mkRpiPkgs =
    nixpkgs: system:
    import nixpkgs {
      inherit system;
      overlays = [
        nixos-raspberrypi.overlays.pkgs

        nixos-raspberrypi.overlays.bootloader
        nixos-raspberrypi.overlays.vendor-kernel
        nixos-raspberrypi.overlays.vendor-firmware
        nixos-raspberrypi.overlays.kernel-and-firmware

        nixos-raspberrypi.overlays.vendor-pkgs
      ];
    };
  mkLegacyPackagesFor = nixpkgs: forSystems rpiSystems (mkRpiPkgs nixpkgs);

  nixos-raspberrypi = rec {
    inputs = {
      inherit
        argononed
        nixos-images
        nixpkgs
        ;
    };

    lib = import ./lib {
      lib = lib';
      self = nixos-raspberrypi;
    };

    nixosModules = {
      trusted-nix-caches = import ./modules/trusted-nix-caches.nix;
      nixpkgs-rpi = import ./modules/nixpkgs-rpi.nix;

      bootloader = import ./modules/system/boot/loader/raspberrypi;
      default = import ./modules/raspberrypi.nix;

      sd-image = import ./modules/installer/sd-card/sd-image-raspberrypi.nix;

      pisugar-3 = import ./modules/pisugar-3.nix;

      usb-gadget-ethernet = import ./modules/usb-gadget-ethernet.nix;

      raspberry-pi-5 = {
        base = import ./modules/raspberry-pi-5;
        display-vc4 = import ./modules/display-vc4.nix;
        display-rp1 = import ./modules/raspberry-pi-5/display-rp1.nix;
        bluetooth = import ./modules/bluetooth.nix;
        page-size-16k = import ./modules/raspberry-pi-5/page-size-16k.nix;
      };

      raspberry-pi-4 = {
        base = import ./modules/raspberry-pi-4.nix;
        display-vc4 = import ./modules/display-vc4.nix;
        bluetooth = import ./modules/bluetooth.nix;
        # work-in-progress, untested
        case-argonone = import ./modules/case-argononev2.nix { inherit argononed; };
      };

      raspberry-pi-3 = {
        base = import ./modules/raspberry-pi-3.nix;
      };

      raspberry-pi-02 = {
        base = import ./modules/raspberry-pi-02.nix;
        display-vc4 = import ./modules/display-vc4.nix;
        bluetooth = import ./modules/bluetooth.nix;
      };
    };

    overlays = {
      bootloader = import ./overlays/bootloader.nix;

      pkgs = import ./overlays/pkgs.nix;
      vendor-pkgs = import ./overlays/vendor-pkgs.nix;
      jemalloc-page-size-16k = import ./overlays/jemalloc-page-size-16k.nix;

      vendor-firmware = import ./overlays/vendor-firmware.nix;
      vendor-kernel = import ./overlays/vendor-kernel.nix;

      kernel-and-firmware = import ./overlays/linux-and-firmware.nix;

      libpisp-default-config-path = import ./overlays/libpisp-default-config-path.nix;
    };

    # "RPi world": nixpkgs with all overlays applied "globally", i.e.
    # all packages here depend on rpi's/optimized versions of the dependencies
    # * used inside the modules, where a choice of "sane defaults" about the
    #   nixpkgs channel had to be made
    # * binary cache is generated from this package set
    legacyPackages = mkLegacyPackagesFor nixpkgs;

    packages = forSystems rpiSystems (
      system:
      let
        pkgs = nixos-raspberrypi.legacyPackages.${system};
      in
      {
        ffmpeg_4 = pkgs.ffmpeg_4;
        ffmpeg_6 = pkgs.ffmpeg_6;
        ffmpeg_7 = pkgs.ffmpeg_7;
        ffmpeg_7-headless = pkgs.ffmpeg_7-headless;
        ffmpeg_8 = pkgs.ffmpeg_8;
        ffmpeg_8-headless = pkgs.ffmpeg_8-headless;

        kodi = pkgs.kodi;
        kodi-gbm = pkgs.kodi-gbm;
        kodi-wayland = pkgs.kodi-wayland;

        libcamera = pkgs.libcamera;
        libpisp = pkgs.libpisp;
        libraspberrypi = pkgs.libraspberrypi;

        raspberrypi-utils = pkgs.raspberrypi-utils;
        raspberrypi-udev-rules = (pkgs.callPackage ./pkgs/raspberrypi/udev-rules.nix { });
        rpicam-apps = pkgs.rpicam-apps;

        vlc = pkgs.vlc;

        # see legacyPackages.<system>.linuxAndFirmware for other versions of
        # the bundle
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

        argononed = pkgs.callPackage "${argononed}/OS/nixos/pkg.nix" { };

        pisugar3-kmod =
          let
            targetKernel = pkgs.linux_rpi02;
          in
          (pkgs.linuxPackagesFor targetKernel).callPackage ./pkgs/pisugar-kmod.nix {
            pisugarVersion = "3";
          };
        pisugar2-kmod =
          let
            targetKernel = pkgs.linux_rpi02;
          in
          (pkgs.linuxPackagesFor targetKernel).callPackage ./pkgs/pisugar-kmod.nix {
            pisugarVersion = "2";
          };

        pisugar-power-manager-rs = pkgs.callPackage ./pkgs/pisugar-power-manager-rs.nix { };

      }
    );

    nixosConfigurations =
      let

        # TIP: To create "regular" nixosConfigurations look for
        # `nixosSystem` and `nixosSystemFull` helpers in `lib/`
        mkNixOSRPiInstaller =
          modules:
          nixos-raspberrypi.lib.nixosInstaller {
            specialArgs = {
              inherit
                nixos-raspberrypi
                nixpkgs
                argononed
                ;
            };
            modules = [
              sdimage-installer
              (
                {
                  config,
                  lib,
                  modulesPath,
                  ...
                }:
                {
                  disabledModules = [
                    # disable the sd-image module that nixos-images uses
                    (modulesPath + "/installer/sd-card/sd-image-aarch64-installer.nix")
                  ];
                  # nixos-images sets this with `mkForce`, thus `mkOverride 40`
                  image.baseName =
                    let
                      cfg = config.boot.loader.raspberry-pi;
                    in
                    lib.mkOverride 40 "nixos-installer-rpi${cfg.variant}-${cfg.bootloader}";
                }
              )
            ]
            ++ modules;
          };

        custom-user-config = (
          {
            config,
            pkgs,
            lib,
            nixos-raspberrypi,
            ...
          }:
          {

            users.users.nixos.openssh.authorizedKeys.keys = [
              # YOUR SSH PUB KEY HERE #

            ];
            users.users.root.openssh.authorizedKeys.keys = [
              # YOUR SSH PUB KEY HERE #

            ];

            environment.systemPackages = with pkgs; [
              tree
            ];

            system.nixos.tags =
              let
                cfg = config.boot.loader.raspberry-pi;
              in
              [
                "raspberry-pi-${cfg.variant}"
                cfg.bootloader
                config.boot.kernelPackages.kernel.version
              ];
          }
        );

      in
      {

        rpi02-installer = mkNixOSRPiInstaller [
          (
            {
              config,
              pkgs,
              lib,
              nixos-raspberrypi,
              ...
            }:
            {
              imports = with nixos-raspberrypi.nixosModules; [
                # Hardware configuration
                raspberry-pi-02.base
                usb-gadget-ethernet
              ];
            }
          )
          custom-user-config
        ];

        rpi3-installer = mkNixOSRPiInstaller [
          (
            {
              config,
              pkgs,
              lib,
              nixos-raspberrypi,
              ...
            }:
            {
              imports = with nixos-raspberrypi.nixosModules; [
                # Hardware configuration
                raspberry-pi-3.base
              ];
            }
          )
          custom-user-config
        ];

        rpi4-installer = mkNixOSRPiInstaller [
          (
            {
              config,
              pkgs,
              lib,
              nixos-raspberrypi,
              ...
            }:
            {
              imports = with nixos-raspberrypi.nixosModules; [
                # Hardware configuration
                raspberry-pi-4.base
              ];
            }
          )
          custom-user-config
        ];

        rpi5-installer = mkNixOSRPiInstaller [
          (
            {
              config,
              pkgs,
              lib,
              nixos-raspberrypi,
              ...
            }:
            {
              imports = with nixos-raspberrypi.nixosModules; [
                # Hardware configuration
                raspberry-pi-5.base
                raspberry-pi-5.page-size-16k
              ];
            }
          )
          custom-user-config
        ];

      };

    installerImages =
      let
        nixos = nixosConfigurations;
        mkImage = nixosConfig: nixosConfig.config.system.build.sdImage;
      in
      {
        rpi02 = mkImage nixos.rpi02-installer;
        rpi3 = mkImage nixos.rpi3-installer;
        rpi4 = mkImage nixos.rpi4-installer;
        rpi5 = mkImage nixos.rpi5-installer;
      };
  };
in
nixos-raspberrypi
