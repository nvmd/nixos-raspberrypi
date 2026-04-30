{ lib, pkgs, self }:

let
  testSupport = import ./lib/rpi-otp-derived-key-test-support.nix {
    inherit lib pkgs;
  };
  inherit (testSupport) persistentSaltPathForName testPkgs;
  unsafeSecretName = "secondary/key";
  unsafeSaltPath = persistentSaltPathForName unsafeSecretName;
in
testPkgs.testers.runNixOSTest {
  name = "rpi-otp-derived-key-ensure-script";

  nodes.machine =
    { config, utils, ... }:
    let
      unsafeUnitSuffix = utils.escapeSystemdPath unsafeSecretName;
    in
    {
      imports = [
        self.nixosModules.rpi-otp-derived-key
      ];

      system.stateVersion = "25.11";

      services.rpiOtpDerivedKey = {
        enable = true;
        secrets.age = {
          format = "age";
          path = "/run/age-keys.txt";
        };
        secrets."${unsafeSecretName}" = {
          format = "hex";
          path = "/run/secondary-key.txt";
        };
      };

      systemd.services.otp-ensure-pre-systemd = {
        wantedBy = [ "sysinit.target" ];
        after = [ "local-fs.target" ];
        before = [
          "rpi-otp-derived-key-salt-age.service"
          "rpi-otp-derived-key-age.service"
          "rpi-otp-derived-key-salt-${unsafeUnitSuffix}.service"
          "rpi-otp-derived-key-${unsafeUnitSuffix}.service"
          "sysinit.target"
        ];
        unitConfig = {
          DefaultDependencies = "no";
          RequiresMountsFor = [
            "/run"
            "/var/lib/rpi-otp-derived-key/salt"
          ];
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          UMask = "0077";
        };
        script = ''
          set -euo pipefail

          test ! -e /var/lib/rpi-otp-derived-key/salt/age
          test ! -e ${unsafeSaltPath}

          ${config.system.build.rpiOtpDerivedKeyEnsureScripts.age}
          ${config.system.build.rpiOtpDerivedKeyEnsureScripts.age}
          ${config.system.build.rpiOtpDerivedKeyEnsureScripts."${unsafeSecretName}"}

          ${pkgs.gnugrep}/bin/grep -q '^AGE-SECRET-KEY-' /run/age-keys.txt
          ${pkgs.gnugrep}/bin/grep -Eq '^[0-9a-f]{64}$' /run/secondary-key.txt
          ${pkgs.coreutils}/bin/stat -c '%a %U %G' /var/lib/rpi-otp-derived-key/salt/age | ${pkgs.gnugrep}/bin/grep -qx '400 root root'
          ${pkgs.coreutils}/bin/stat -c '%a %U %G' ${unsafeSaltPath} | ${pkgs.gnugrep}/bin/grep -qx '400 root root'
          ${pkgs.coreutils}/bin/stat -c '%a %U %G' /run/age-keys.txt | ${pkgs.gnugrep}/bin/grep -qx '400 root root'
          ${pkgs.coreutils}/bin/stat -c '%a %U %G' /run/secondary-key.txt | ${pkgs.gnugrep}/bin/grep -qx '400 root root'
          ${pkgs.coreutils}/bin/touch /run/otp-ensure-pre-systemd-ran
        '';
      };
    };

  testScript = ''
    start_all()

    machine.wait_for_unit("otp-ensure-pre-systemd.service")
    machine.wait_for_unit("rpi-otp-derived-key-age.service")
    machine.wait_for_unit("sysinit.target")

    machine.succeed("test -e /run/otp-ensure-pre-systemd-ran")
    machine.succeed("grep -q '^AGE-SECRET-KEY-' /run/age-keys.txt")
    machine.succeed("grep -Eq '^[0-9a-f]{64}$' /run/secondary-key.txt")
    machine.succeed("stat -c '%a %U %G' /var/lib/rpi-otp-derived-key/salt/age | grep -qx '400 root root'")
    machine.succeed("stat -c '%a %U %G' ${unsafeSaltPath} | grep -qx '400 root root'")
    machine.succeed("stat -c '%a %U %G' /run/age-keys.txt | grep -qx '400 root root'")
    machine.succeed("stat -c '%a %U %G' /run/secondary-key.txt | grep -qx '400 root root'")
    machine.succeed("systemctl show -P Before otp-ensure-pre-systemd.service | tr ' ' '\\n' | grep -qx 'rpi-otp-derived-key-salt-age.service'")
    machine.succeed("systemctl show -P Before otp-ensure-pre-systemd.service | tr ' ' '\\n' | grep -qx 'rpi-otp-derived-key-age.service'")
  '';
}
