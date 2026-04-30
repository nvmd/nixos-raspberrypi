{ lib, pkgs, self }:

let
  testSupport = import ./lib/rpi-otp-derived-key-test-support.nix {
    inherit lib pkgs;
  };
  inherit (testSupport) testPkgs;
in
testPkgs.testers.runNixOSTest {
  name = "rpi-otp-derived-key-before";

  nodes.machine = {
    imports = [
      self.nixosModules.rpi-otp-derived-key
    ];

    system.stateVersion = "25.11";

    services.rpiOtpDerivedKey = {
      enable = true;
      secrets.age = {
        format = "age";
        path = "/run/age-keys.txt";
        before = [ "otp-consumer.service" ];
      };
    };

    systemd.services.otp-consumer = {
      wantedBy = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail

        grep -q '^AGE-SECRET-KEY-' /run/age-keys.txt
      '';
    };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("otp-consumer.service")
    machine.wait_for_unit("rpi-otp-derived-key-age.service")
    machine.wait_for_unit("sysinit.target")

    machine.succeed("systemctl show -P After otp-consumer.service | tr ' ' '\\n' | grep -qx 'rpi-otp-derived-key-age.service'")
    machine.succeed("grep -q '^AGE-SECRET-KEY-' /run/age-keys.txt")
  '';
}
