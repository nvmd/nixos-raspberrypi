{ lib, pkgs, self }:

let
  testSupport = import ./lib/rpi-otp-derived-key-test-support.nix {
    inherit lib pkgs;
    mockOtpHex = "0000000000000000000000000000000000000000000000000000000000000000";
  };
  inherit (testSupport) testPkgs;
in
testPkgs.testers.runNixOSTest {
  name = "rpi-otp-derived-key-install-time-otp-check";

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
    };
  };

  testScript = ''
    start_all()

    machine.fail("/run/current-system/bin/switch-to-configuration boot >/tmp/install.out 2>/tmp/install.err")
    machine.succeed("grep -Fqx 'services.rpiOtpDerivedKey: Raspberry Pi OTP private key is not programmed.' /tmp/install.err")
    machine.succeed("grep -Fqx '  rpi-otp-private-key -w \"$(cat d.hex)\"' /tmp/install.err")
    machine.succeed("grep -Fqx 'Run `rpi-otp-private-key -h` for details and warnings. Aborting bootloader install.' /tmp/install.err")
    machine.fail("test -e /var/lib/rpi-boot/nixos/default/initrd")
  '';
}
