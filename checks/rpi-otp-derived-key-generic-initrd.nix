{ lib, nixpkgs, pkgs, self }:

let
  testSupport = import ./lib/rpi-otp-derived-key-test-support.nix {
    inherit lib pkgs;
  };
  inherit (testSupport) testPkgs;

  evaluated = nixpkgs.lib.nixosSystem {
    system = pkgs.stdenv.hostPlatform.system;
    modules = [
      self.nixosModules.rpi-otp-derived-key
      {
        nixpkgs.pkgs = testPkgs;

        system.stateVersion = "25.11";

        boot.initrd.systemd.enable = true;
        boot.loader.supportsInitrdSecrets = true;

        services.rpiOtpDerivedKey = {
          enable = true;
          secrets.generic = {
            format = "hex";
            path = "/run/generic.key";
            neededForBoot = true;
            before = [ "generic-consumer.service" ];
          };
        };
      }
    ];
  };

  cfg = evaluated.config;
  unit = cfg.boot.initrd.systemd.services.rpi-otp-derived-key-generic;
in
assert unit.wantedBy == [ "initrd.target" ];
assert builtins.elem "initrd.target" unit.before;
assert builtins.elem "generic-consumer.service" unit.before;
assert builtins.elem "initrd-nixos-copy-secrets.service" unit.after;
assert builtins.elem "initrd-nixos-copy-secrets.service" unit.requires;
assert cfg.system.preSwitchChecks ? rpi-otp-derived-key-initrd-salts;
assert !(cfg.system.build ? rpiOtpDerivedKeyInstallHooks);
pkgs.writeText "rpi-otp-derived-key-generic-initrd" ''
  ok
''
