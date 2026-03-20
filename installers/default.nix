# Installer builders, shared config, and all installer outputs.
{
  lib,
  self,
  inputs,
  nixos-images,
  systems,
}:

let
  inherit (systems) buildSystems;

  # =========================================================================
  # NixOS installer helpers
  # =========================================================================

  # TIP: To create "regular" nixosConfigurations look for
  # `nixosSystem` and `nixosSystemFull` helpers in `lib/`
  #
  # Cross-compilation: Use mkNixOSRPiInstallerCross with buildPlatform
  # to build installer images on a different architecture (e.g., x86_64).
  #
  mkNixOSRPiInstallerWith =
    { buildPlatform }:
    modules:
    self.lib.nixosInstaller {
      inherit buildPlatform;
      specialArgs = inputs // {
        nixos-raspberrypi = self;
      };
      modules = [
        nixos-images.nixosModules.sdimage-installer
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
            # Produce raw .img so it can be flashed directly with dd
            sdImage.compressImage = false;
          }
        )
      ]
      ++ modules;
    };

  # Shared image-extraction helper
  mkImage = nixosConfig: nixosConfig.config.system.build.sdImage;

  # Wrap a raw image derivation with zstd compression
  mkCompressedImage =
    nixosConfig:
    let
      rawImage = mkImage nixosConfig;
      buildPkgs = nixosConfig.pkgs.buildPackages;
    in
    buildPkgs.runCommand "${rawImage.name}-zstd"
      {
        nativeBuildInputs = [ buildPkgs.zstd ];
      }
      ''
        mkdir -p $out/sd-image
        for img in ${rawImage}/sd-image/*.img; do
          zstd -T$NIX_BUILD_CORES "$img" -o "$out/sd-image/$(basename "$img").zst"
        done
      '';

  # Native build (no cross-compilation)
  mkNixOSRPiInstaller = mkNixOSRPiInstallerWith { buildPlatform = null; };

  # Cross-compilation variant: specify buildPlatform to cross-compile
  mkNixOSRPiInstallerCross = buildPlatform: mkNixOSRPiInstallerWith { inherit buildPlatform; };

  # Shared user configuration for installer images
  sshKeys = [
    # YOUR SSH PUB KEY HERE #
  ];

  custom-user-config =
    {
      config,
      pkgs,
      lib,
      nixos-raspberrypi,
      ...
    }:
    {
      imports = [ ../modules/sysctl.nix ];
      users.users.nixos.openssh.authorizedKeys.keys = sshKeys;
      users.users.root.openssh.authorizedKeys.keys = sshKeys;

      environment.systemPackages = with pkgs; [
        # Add extra packages for installer images here, e.g.:
        # tree
        # vim
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
    };

  # =========================================================================
  # Per-RPi model module lists (defined ONCE, used by both native and cross)
  # =========================================================================

  # Helper: build installer module list from a function that selects nixosModules
  mkInstallerModule = getImports: [
    (
      { nixos-raspberrypi, ... }:
      {
        imports = getImports nixos-raspberrypi.nixosModules;
      }
    )
    custom-user-config
  ];

  installerModules = {
    rpi02 = mkInstallerModule (m: [
      m.raspberry-pi-02.base
      m.usb-gadget-ethernet
    ]);
    rpi3 = mkInstallerModule (m: [ m.raspberry-pi-3.base ]);
    rpi4 = mkInstallerModule (m: [ m.raspberry-pi-4.base ]);
    rpi5 = mkInstallerModule (m: [
      m.raspberry-pi-5.base
      m.raspberry-pi-5.page-size-16k
    ]);
  };

  # =========================================================================
  # Build NixOS configs once, reuse for raw + compressed outputs
  # =========================================================================

  nativeConfigs = lib.mapAttrs (_: mkNixOSRPiInstaller) installerModules;

  crossConfigs = lib.genAttrs buildSystems (
    buildSystem: lib.mapAttrs (_: mkNixOSRPiInstallerCross buildSystem) installerModules
  );

in
{
  # =========================================================================
  # NixOS configurations (native build)
  # =========================================================================

  nixosConfigurations = lib.mapAttrs' (
    name: cfg: lib.nameValuePair "${name}-installer" cfg
  ) nativeConfigs;

  # =========================================================================
  # Installer images (native build - requires aarch64 or binfmt)
  # =========================================================================
  installerImages = lib.mapAttrs (_: mkImage) nativeConfigs;

  # Compressed installer images (native build)
  installerImagesZstd = lib.mapAttrs (_: mkCompressedImage) nativeConfigs;

  # =========================================================================
  # Cross-compiled installer images (build from x86_64 without binfmt)
  # =========================================================================
  #
  # Usage from x86_64 workstation:
  #   nix build .#installerImagesCross.x86_64-linux.rpi5
  #
  # This uses true cross-compilation (native x86_64 cross-compiler toolchain)
  # which is significantly faster than binfmt emulation.
  #
  installerImagesCross = lib.mapAttrs (_: lib.mapAttrs (_: mkImage)) crossConfigs;

  # Compressed cross-compiled installer images
  installerImagesCrossZstd = lib.mapAttrs (_: lib.mapAttrs (_: mkCompressedImage)) crossConfigs;
}
