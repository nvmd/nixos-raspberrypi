{ lib, nixpkgs, pkgs, self }:

let
  evalConfig =
    modules:
    nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules =
        [
          self.lib.inject-overlays
          self.nixosModules.bootloader
          self.nixosModules.rpi-otp-derived-key
          ../modules/configtxt.nix
          ../modules/configtxt-config.nix
          {
            system.stateVersion = "25.11";
          }
        ]
        ++ modules;
    };

  expectFailure =
    name: modules:
    let
      result = builtins.tryEval (
        builtins.deepSeq
          (evalConfig modules).config.system.build.toplevel
          true
      );
    in
    assert !result.success;
    name;

  raspberryPiBootloaderConfig = {
    boot.loader.supportsInitrdSecrets = true;
    boot.loader.raspberry-pi.enable = true;
    boot.loader.raspberry-pi.bootloader = "kernel";
    boot.loader.raspberry-pi.variant = "4";
  };

  cases = [
    (expectFailure "enabled-with-no-secrets" [
      {
        services.rpiOtpDerivedKey.enable = true;
      }
    ])
    (expectFailure "needed-for-boot-without-systemd-initrd" [
      raspberryPiBootloaderConfig
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            format = "hex";
            path = "/run/bad-key";
            neededForBoot = true;
          };
        };
      }
    ])
    (expectFailure "needed-for-boot-non-run-path" [
      raspberryPiBootloaderConfig
      {
        boot.initrd.systemd.enable = true;

        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            format = "hex";
            path = "/var/lib/bad-key";
            neededForBoot = true;
          };
        };
      }
    ])
    (expectFailure "needed-for-boot-non-root-owner" [
      raspberryPiBootloaderConfig
      {
        boot.initrd.systemd.enable = true;

        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            format = "hex";
            path = "/run/bad-key";
            owner = "alice";
            neededForBoot = true;
          };
        };
      }
    ])
    (expectFailure "needed-for-boot-non-root-group" [
      raspberryPiBootloaderConfig
      {
        boot.initrd.systemd.enable = true;

        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            format = "hex";
            path = "/run/bad-key";
            group = "keys";
            neededForBoot = true;
          };
        };
      }
    ])
  ];
in
pkgs.writeText "rpi-otp-derived-key-invalid-configs" ''
  ${lib.concatStringsSep "\n" cases}
''
