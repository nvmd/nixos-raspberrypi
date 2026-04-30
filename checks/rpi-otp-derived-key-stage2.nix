{ lib, pkgs, self }:

let
  testSupport = import ./lib/rpi-otp-derived-key-test-support.nix {
    inherit lib pkgs;
  };
  inherit (testSupport) testPkgs;
in
testPkgs.testers.runNixOSTest {
  name = "rpi-otp-derived-key-stage2";

  nodes.machine = {
    imports = [
      self.nixosModules.rpi-otp-derived-key
    ];

    system.stateVersion = "25.11";

    services.rpiOtpDerivedKey = {
      enable = true;
      secrets.stable = {
        format = "hex";
        path = "/run/stable.key";
      };
    };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("rpi-otp-derived-key-stable.service")
    machine.wait_for_unit("sysinit.target")

    machine.succeed("grep -Eq '^[0-9a-f]{64}$' /run/stable.key")
    machine.succeed("stat -c '%a %U %G' /var/lib/rpi-otp-derived-key/salt/stable | grep -qx '400 root root'")
    machine.succeed("cp /var/lib/rpi-otp-derived-key/salt/stable /tmp/stable.salt")
    machine.succeed("cp /run/stable.key /tmp/stable.key")
    machine.succeed("systemctl restart rpi-otp-derived-key-salt-stable.service || true")
    machine.succeed("systemctl restart rpi-otp-derived-key-stable.service")
    machine.succeed("cmp /tmp/stable.salt /var/lib/rpi-otp-derived-key/salt/stable")
    machine.succeed("cmp /tmp/stable.key /run/stable.key")
  '';
}
