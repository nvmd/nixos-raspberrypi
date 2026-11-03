# Checks run by `nix flake check`
{ self, pkgs }:

let
  inherit (pkgs) lib;

  # base module of each board, and a device tree file the vendor firmware
  # has to provide for it
  boards = with self.nixosModules; {
    rpi02 = {
      base = raspberry-pi-02.base;
      dtb = "bcm2710-rpi-zero-2-w.dtb";
    };
    rpi3 = {
      base = raspberry-pi-3.base;
      dtb = "bcm2710-rpi-3-b.dtb";
    };
    rpi4 = {
      base = raspberry-pi-4.base;
      dtb = "bcm2711-rpi-4-b.dtb";
    };
    rpi5 = {
      base = raspberry-pi-5.base;
      dtb = "bcm2712-rpi-5-b.dtb";
    };
  };

  bootloaders = [
    "kernel"
    "kernelboot"
    "uboot"
  ];

  # smallest configuration that evaluates, made the way users make theirs
  mkConfig =
    modules:
    self.lib.nixosSystem {
      modules = modules ++ [
        (
          { lib, ... }:
          {
            fileSystems."/" = {
              device = "/dev/disk/by-label/NIXOS_SD";
              fsType = "ext4";
            };
            fileSystems."/boot/firmware" = {
              device = "/dev/disk/by-label/FIRMWARE";
              fsType = "vfat";
            };
            system.stateVersion = lib.trivial.release;
          }
        )
      ];
    };

  # every board with every bootloader
  bootloaderConfigs = lib.listToAttrs (
    lib.concatMap (
      board:
      map (
        bootloader:
        lib.nameValuePair "${board}-${bootloader}" {
          inherit board;
          nixos = mkConfig [
            boards.${board}.base
            { boot.loader.raspberry-pi.bootloader = bootloader; }
          ];
        }
      ) bootloaders
    ) (lib.attrNames boards)
  );

  # optional hardware modules, with the board's default bootloader
  # (pisugar-3 is left out: it doesn't evaluate, `pisugar3-kmod` is undefined)
  extraConfigs = lib.mapAttrs (name: mkConfig) (
    with self.nixosModules;
    {
      rpi02-extras = [
        raspberry-pi-02.base
        raspberry-pi-02.display-vc4
        raspberry-pi-02.bluetooth
        usb-gadget-ethernet
      ];
      rpi4-extras = [
        raspberry-pi-4.base
        raspberry-pi-4.display-vc4
        raspberry-pi-4.bluetooth
        usb-gadget-ethernet
      ];
      rpi5-extras = [
        raspberry-pi-5.base
        raspberry-pi-5.display-vc4
        raspberry-pi-5.bluetooth
        raspberry-pi-5.page-size-16k
        usb-gadget-ethernet
      ];
      # display-rp1 is an alternative to display-vc4
      rpi5-display-rp1 = [
        raspberry-pi-5.base
        raspberry-pi-5.display-rp1
      ];
    }
  );

  # evaluates the whole system without building any of it
  evalCheck =
    name: nixos:
    pkgs.writeText "eval-${name}" (
      builtins.unsafeDiscardStringContext nixos.config.system.build.toplevel.drvPath
    );

  bootloaderCheck =
    name:
    { board, nixos }:
    import ./bootloader.nix {
      inherit pkgs name nixos;
      inherit (boards.${board}) dtb;
    };
in
lib.mapAttrs' (name: c: lib.nameValuePair "eval-${name}" (evalCheck name c.nixos)) bootloaderConfigs
// lib.mapAttrs' (name: nixos: lib.nameValuePair "eval-${name}" (evalCheck name nixos)) extraConfigs
# bootloader installers are built for, and have to run on, aarch64
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isAarch64 (
  lib.mapAttrs' (
    name: c: lib.nameValuePair "bootloader-${name}" (bootloaderCheck name c)
  ) bootloaderConfigs
)
