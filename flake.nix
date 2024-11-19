{
  description = "Flake for RaspberryPi support on NixOS";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    connect-timeout = 5;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    argononed = {
      # url = "git+file:../argononed?shallow=1";
      # url = "git+https://gitlab.com/DarkElvenAngel/argononed.git";
      url = "github:nvmd/argononed";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, argononed, ... }@inputs: let
    rpiSystems = [ "aarch64-linux" "armv7l-linux" "armv6l-linux" ];
    allSystems = nixpkgs.lib.systems.flakeExposed;
    forSystems = systems: f: nixpkgs.lib.genAttrs systems (system: f system);
    mkRpiPkgs = nixpkgs: system: import nixpkgs {
        inherit system; overlays = [
          self.overlays.bootloader

          self.overlays.pkgs

          self.overlays.vendor-pkgs

          self.overlays.vendor-firmware
          self.overlays.vendor-kernel

          self.overlays.kernel-and-firmware
        ];
      };
    mkLegacyPackagesFor = nixpkgs: forSystems rpiSystems (mkRpiPkgs nixpkgs);
  in {

    devShells = forSystems allSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        name = "nixos-raspberrypi";
        nativeBuildInputs = with pkgs; [
          nil # lsp language server for nix
          nixpkgs-fmt
          nix-output-monitor
          bash-language-server
          shellcheck
          (pkgs.callPackage ./devshells/nix-build-to-cachix.nix {})
        ];
      };
    });

    lib = import ./lib ({
      inherit (nixpkgs) lib;
    } // inputs);

    nixosModules = {
      bootloader = import ./modules/system/boot/loader/raspberrypi;
      default = import ./modules/raspberrypi.nix;

      sd-image = import ./modules/installer/sd-card/sd-image-raspberrypi.nix;
      sd-image-installer = import ./modules/installer/sd-card/sd-image-raspberrypi-installer.nix;

      pisugar-3 = import ./modules/pisugar-3.nix;

      raspberry-pi-5 = {
        base = import ./modules/raspberry-pi-5;
        display-vc4 = import ./modules/display-vc4.nix;
        display-rp1 = import ./modules/raspberry-pi-5/display-rp1.nix;
        bluetooth = import ./modules/bluetooth.nix;

      };

      raspberry-pi-4 = {
        base = import ./modules/raspberry-pi-4.nix;
        display-vc4 = import ./modules/display-vc4.nix;
        case-argonone = import ./modules/case-argononev2.nix { inherit argononed; };
        bluetooth = import ./modules/bluetooth.nix;
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

      vendor-firmware = import ./overlays/vendor-firmware.nix;
      vendor-kernel = import ./overlays/vendor-kernel.nix;
      vendor-kernel-nixpkgs = import ./overlays/vendor-kernel-nixpkgs.nix;

      kernel-and-firmware = import ./overlays/linux-and-firmware.nix;
    };

    # "RPi world": nixpkgs with all overlays applied "globally", i.e.
    # all packages here depend on rpi's/optimized versions of the dependencies
    # * used inside the modules, where a choice of "sane defaults" about the 
    #   nixpkgs channel had to be made
    # * binary cache is generated from this package set
    legacyPackages = mkLegacyPackagesFor nixpkgs;

    packages = forSystems rpiSystems (system: let
      pkgs = self.legacyPackages.${system};
    in {
      ffmpeg_4 = pkgs.ffmpeg_4;
      ffmpeg_5 = pkgs.ffmpeg_5;
      ffmpeg_6 = pkgs.ffmpeg_6;
      ffmpeg_6-headless = pkgs.ffmpeg_6-headless;
      ffmpeg_7 = pkgs.ffmpeg_7;

      kodi = pkgs.kodi;
      kodi-gbm = pkgs.kodi-gbm;
      kodi-wayland = pkgs.kodi-wayland;

      libcamera = pkgs.libcamera;
      libpisp = pkgs.libpisp;
      libraspberrypi = pkgs.libraspberrypi;

      raspberrypi-utils = pkgs.raspberrypi-utils;
      raspberrypi-udev-rules = (pkgs.callPackage ./pkgs/raspberrypi/udev-rules.nix {});
      rpicam-apps = pkgs.rpicam-apps;

      SDL2 = pkgs.SDL2;

      vlc = pkgs.vlc;

      # see legacyPackages.<system>.linuxAndFirmware for other versions of 
      # the bundle
      inherit (pkgs.linuxAndFirmware.latest)
        linux_rpi5 linux_rpi4 linux_rpi02
        linuxPackages_rpi5 linuxPackages_rpi4 linuxPackages_rpi02
        raspberrypifw raspberrypiWirelessFirmware;

      argononed = pkgs.callPackage "${inputs.argononed}/OS/nixos/pkg.nix" {};

      pisugar3-kmod = let
        targetKernel = pkgs.linux_rpi02;
      in (pkgs.linuxPackagesFor targetKernel).callPackage ./pkgs/pisugar3-kmod.nix {};

      pisugar-power-manager-rs = pkgs.callPackage ./pkgs/pisugar-power-manager-rs.nix {};

    });

  };
}
