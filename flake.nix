{
  description = "Flake for RaspberryPi support on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # for `config.txt` generation
    raspberry-pi-nix.url = "github:nvmd/raspberry-pi-nix";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }: let
    rpiSystems = [ "aarch64-linux" "armv7l-linux" "armv6l-linux" ];
    allSystems = nixpkgs.lib.systems.flakeExposed;
    forSystems = systems: f: nixpkgs.lib.genAttrs systems (system: f system);
  in {

    devShells = forSystems allSystems (system: let
      pkgs = nixpkgs-unstable.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        name = "nixos-raspberrypi";
        nativeBuildInputs = with pkgs; [
          nil # lsp language server for nix
          nixpkgs-fmt
          nix-output-monitor
          bash-language-server
          shellcheck
        ];
      };
    });

    nixosModules = {
      default = import ./modules/raspberrypi.nix;
      bootloader = import ./modules/system/boot/loader/raspberrypi;
      rpi5 = {
        sd-image = import ./modules/installer/sd-card/sd-image-raspberrypi5.nix;
        sd-image-installer = import ./modules/installer/sd-card/sd-image-raspberrypi5-installer.nix;
      };
    };

    overlays = {
      bootloader = import ./overlays/bootloader.nix;

      pkgs-global = import ./overlays/pkgs-global.nix;
      pkgs = import ./overlays/pkgs.nix;
      vendor-pkgs = import ./overlays/vendor-pkgs.nix;

      vendor-firmware = import ./overlays/vendor-firmware.nix;
      vendor-kernel = import ./overlays/vendor-kernel.nix;
      vendor-kernel-nixpkgs = import ./overlays/vendor-kernel-nixpkgs.nix;

      kernel-and-firmware = import ./overlays/linux-and-firmware.nix;
    };

    packages = forSystems rpiSystems (system: let
      pkgs = import nixpkgs {
        inherit system; overlays = [
          self.overlays.pkgs
          self.overlays.vendor-pkgs

          self.overlays.vendor-firmware
          self.overlays.vendor-kernel

          self.overlays.kernel-and-firmware
        ];
      };
    in {
      ffmpeg_4 = pkgs.ffmpeg_4-rpi;
      ffmpeg_5 = pkgs.ffmpeg_5-rpi;
      ffmpeg_6 = pkgs.ffmpeg_6-rpi;

      kodi = pkgs.kodi-rpi;
      kodi-gbm = pkgs.kodi-rpi-gbm;
      kodi-wayland = pkgs.kodi-rpi-wayland;

      libcamera = pkgs.libcamera-rpi;
      libpisp = pkgs.libpisp;
      libraspberrypi = pkgs.libraspberrypi;

      raspberrypi-utils = pkgs.raspberrypi-utils;
      rpicam-apps = pkgs.rpicam-apps;

      SDL2 = pkgs.SDL2-rpi;

      vlc = pkgs.vlc-rpi;

      # unfortunately nested package sets aren't allowed in flakes
      # `nix flake show` will fail here
      linuxAndFirmware = pkgs.linuxAndFirmware;
    });

  };
}
