{
  lib,
  nixpkgs,
  pkgs,
  self,
}:

let
  otpDerivedKeyLib = import ../lib/rpi-otp-derived-key.nix { };

  evalConfig =
    modules:
    nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
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
      result = builtins.tryEval (builtins.deepSeq (evalConfig modules).config.system.build.toplevel true);
    in
    assert !result.success;
    name;

  expectValue =
    name: value:
    assert value;
    name;

  raspberryPiBootloaderConfigFor = variant: {
    boot.loader.supportsInitrdSecrets = true;
    boot.loader.raspberry-pi.enable = true;
    boot.loader.raspberry-pi.bootloader = "kernel";
    boot.loader.raspberry-pi.variant = variant;
  };
  raspberryPiBootloaderConfig = raspberryPiBootloaderConfigFor "4";
  unsafeSecretName = "../escape";
  unsafePathComponent = otpDerivedKeyLib.pathComponentForName unsafeSecretName;
  collidingSafeSecretName = unsafePathComponent;

  cases = [
    (expectValue "dot-components-are-not-safe" (
      !otpDerivedKeyLib.isSafePathComponent "."
      && !otpDerivedKeyLib.isSafePathComponent ".."
      && otpDerivedKeyLib.isSafePathComponent "normal-name"
    ))
    (expectValue "canonical-path-validation" (
      otpDerivedKeyLib.isCanonicalAbsolutePath "/run/secrets/key"
      && !otpDerivedKeyLib.isCanonicalAbsolutePath "/run/../etc/key"
      && !otpDerivedKeyLib.isCanonicalAbsolutePath "/run/./key"
      && !otpDerivedKeyLib.isCanonicalAbsolutePath "/run//key"
      && !otpDerivedKeyLib.isCanonicalAbsolutePath "/run/key/"
    ))
    (expectValue "unsafe-default-path-is-contained" (
      let
        evaluated = evalConfig [
          raspberryPiBootloaderConfig
          {
            services.rpiOtpDerivedKey = {
              enable = true;
              secrets."${unsafeSecretName}" = {
                scheme = "firmware-hmac-v1";
                format = "hex";
              };
            };
          }
        ];
      in
      evaluated.config.services.rpiOtpDerivedKey.secrets."${unsafeSecretName}".path
      == "/run/rpi-otp-derived-key/${unsafePathComponent}"
    ))
    (expectValue "firmware-scheme-locks-raw-otp-api" (
      let
        evaluated = evalConfig [
          raspberryPiBootloaderConfig
          {
            services.rpiOtpDerivedKey = {
              enable = true;
              secrets.key = {
                scheme = "firmware-hmac-v1";
                format = "hex";
                path = "/run/key";
              };
            };
          }
        ];
        lockOption = evaluated.config.hardware.raspberry-pi.config.all.options.lock_device_private_key;
      in
      lockOption.enable && lockOption.value == 1
    ))
    (expectValue "output-directory-permissions-are-creation-only" (
      let
        evaluated = evalConfig [
          raspberryPiBootloaderConfig
          {
            services.rpiOtpDerivedKey = {
              enable = true;
              secrets.key = {
                scheme = "firmware-hmac-v1";
                format = "hex";
                path = "/run/application-owned/key";
              };
            };
          }
        ];
        directoryRule =
          evaluated.config.systemd.tmpfiles.settings.rpi-otp-derived-key-output-dirs."/run/application-owned".d;
      in
      directoryRule.mode == ":0711" && directoryRule.user == ":root" && directoryRule.group == ":root"
    ))
    (expectValue "legacy-scheme-does-not-lock-raw-otp-api" (
      let
        evaluated = evalConfig [
          raspberryPiBootloaderConfig
          {
            services.rpiOtpDerivedKey = {
              enable = true;
              secrets.key = {
                scheme = "legacy-hkdf-v1";
                format = "hex";
                path = "/run/key";
              };
            };
          }
        ];
      in
      !(evaluated.config.hardware.raspberry-pi.config.all.options ? lock_device_private_key)
    ))
    (expectFailure "enabled-with-no-secrets" [
      raspberryPiBootloaderConfig
      {
        services.rpiOtpDerivedKey.enable = true;
      }
    ])
    (expectFailure "missing-required-scheme" [
      raspberryPiBootloaderConfig
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            format = "hex";
            path = "/run/bad-key";
          };
        };
      }
    ])
    (expectFailure "non-canonical-parent-component" [
      raspberryPiBootloaderConfig
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            scheme = "firmware-hmac-v1";
            format = "hex";
            path = "/run/../etc/bad-key";
          };
        };
      }
    ])
    (expectFailure "non-canonical-current-component" [
      raspberryPiBootloaderConfig
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            scheme = "firmware-hmac-v1";
            format = "hex";
            path = "/run/./bad-key";
          };
        };
      }
    ])
    (expectFailure "duplicate-output-path" [
      raspberryPiBootloaderConfig
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.first = {
            scheme = "firmware-hmac-v1";
            format = "hex";
            path = "/run/shared-key";
          };
          secrets.second = {
            scheme = "firmware-hmac-v1";
            format = "age";
            path = "/run/shared-key";
          };
        };
      }
    ])
    (expectFailure "nested-output-path" [
      raspberryPiBootloaderConfig
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.first = {
            scheme = "firmware-hmac-v1";
            format = "hex";
            path = "/run/shared-key";
          };
          secrets.second = {
            scheme = "firmware-hmac-v1";
            format = "age";
            path = "/run/shared-key/child";
          };
        };
      }
    ])
    (expectFailure "persistent-salt-path-collision" [
      raspberryPiBootloaderConfig
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets."${unsafeSecretName}" = {
            scheme = "firmware-hmac-v1";
            format = "hex";
            path = "/run/unsafe-name-key";
          };
          secrets."${collidingSafeSecretName}" = {
            scheme = "firmware-hmac-v1";
            format = "hex";
            path = "/run/colliding-safe-name-key";
          };
        };
      }
    ])
    (expectFailure "missing-raspberry-pi-variant" [
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            scheme = "firmware-hmac-v1";
            format = "hex";
            path = "/run/bad-key";
          };
        };
      }
    ])
    (expectFailure "unsupported-raspberry-pi-variant" [
      (raspberryPiBootloaderConfigFor "3")
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            scheme = "firmware-hmac-v1";
            format = "hex";
            path = "/run/bad-key";
          };
        };
      }
    ])
    (expectFailure "needed-for-boot-without-systemd-initrd" [
      raspberryPiBootloaderConfig
      {
        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.bad = {
            scheme = "firmware-hmac-v1";
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
            scheme = "firmware-hmac-v1";
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
            scheme = "firmware-hmac-v1";
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
            scheme = "firmware-hmac-v1";
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
