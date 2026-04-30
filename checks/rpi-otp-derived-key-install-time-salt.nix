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
  name = "rpi-otp-derived-key-install-time-salt";

  nodes.machine = { ... }: {
    imports = [
      self.nixosModules.bootloader
      self.nixosModules.rpi-otp-derived-key
      ../modules/configtxt.nix
      ../modules/configtxt-config.nix
    ];

    system.stateVersion = "25.11";
    system.switch.enable = true;

    boot.initrd.systemd.enable = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.loader.supportsInitrdSecrets = lib.mkOverride 0 true;
    boot.loader.raspberry-pi.enable = true;
    boot.loader.raspberry-pi.bootloader = "kernel";
    boot.loader.raspberry-pi.variant = "4";
    boot.loader.raspberry-pi.firmwarePath = "/var/lib/rpi-boot";

    systemd.tmpfiles.rules = [
      "d /var/lib/rpi-boot 0755 root root - -"
    ];

    services.rpiOtpDerivedKey = {
      enable = true;

      secrets.age = {
        format = "age";
        path = "/run/age-keys.txt";
        neededForBoot = true;
      };

      secrets."${unsafeSecretName}" = {
        format = "hex";
        path = "/run/secondary-key.txt";
        neededForBoot = true;
      };
    };
  };

  testScript = ''
    start_all()

    machine.fail("test -e /var/lib/rpi-otp-derived-key/salt/age")
    machine.fail("test -e ${unsafeSaltPath}")
    machine.succeed("/run/current-system/bin/switch-to-configuration boot")

    machine.succeed("find /var/lib/rpi-otp-derived-key/salt -maxdepth 1 -type f | wc -l | grep -qx '2'")
    machine.succeed("stat -c '%a %U %G' /var/lib/rpi-otp-derived-key/salt/age | grep -qx '400 root root'")
    machine.succeed("stat -c '%a %U %G' ${unsafeSaltPath} | grep -qx '400 root root'")
    machine.succeed("! cmp -s /var/lib/rpi-otp-derived-key/salt/age ${unsafeSaltPath}")
    machine.succeed("test -f /var/lib/rpi-boot/nixos/default/initrd")

    machine.succeed("cp /run/current-system/initrd /tmp/expected-initrd")
    machine.succeed("/run/current-system/append-initrd-secrets /tmp/expected-initrd")
    machine.succeed("cmp /tmp/expected-initrd /var/lib/rpi-boot/nixos/default/initrd")
  '';
}
