{ lib, pkgs, self }:

let
  testSupport = import ./lib/rpi-otp-derived-key-test-support.nix {
    inherit lib pkgs;
  };
  inherit (testSupport) testPkgs;

  saltFile = testPkgs.writeText "rpi-otp-derived-key-luks-salt" "initrd-luks-test-salt";
in
testPkgs.testers.runNixOSTest {
  name = "rpi-otp-derived-key-initrd-luks";

  nodes.machine = {
    imports = [
      self.nixosModules.bootloader
      self.nixosModules.rpi-otp-derived-key
      ../modules/configtxt.nix
      ../modules/configtxt-config.nix
    ];

    virtualisation.emptyDiskImages = [ 128 ];

    system.stateVersion = "25.11";

    boot.initrd.systemd.enable = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.loader.supportsInitrdSecrets = lib.mkOverride 0 true;
    boot.loader.raspberry-pi.enable = true;
    boot.loader.raspberry-pi.bootloader = "kernel";
    boot.loader.raspberry-pi.variant = "4";
    boot.initrd.systemd.initrdBin = [ testPkgs.cryptsetup ];

    environment.systemPackages = [
      testPkgs.cryptsetup
    ];

    boot.initrd.luks.devices = lib.mkOverride 5 {
      cryptd = {
        device = "/dev/vdb";
        keyFile = "/run/secrets/luks.key";
        crypttabExtraOpts = [ "x-initrd.attach" ];
      };
    };

    boot.initrd.systemd.contents."/.initrd-secrets/run/rpi-otp-derived-key/salt/luks".source = saltFile;

    boot.initrd.systemd.services.format-test-luks-disk = {
      description = "Format test LUKS disk with OTP-derived initrd key";
      wantedBy = [ "cryptsetup.target" ];
      before = [ "cryptsetup-pre.target" ];
      after = [
        "dev-vdb.device"
        "rpi-otp-derived-key-luks.service"
      ];
      requires = [
        "dev-vdb.device"
        "rpi-otp-derived-key-luks.service"
      ];
      wants = [ "cryptsetup-pre.target" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if ! cryptsetup isLuks /dev/vdb >/dev/null 2>&1; then
          cryptsetup -q luksFormat /dev/vdb --iter-time=1 --key-file /run/secrets/luks.key
        fi
      '';
    };

    services.rpiOtpDerivedKey = {
      enable = true;
      secrets.luks = {
        format = "hex";
        path = "/run/secrets/luks.key";
        neededForBoot = true;
        before = [ "cryptsetup-pre.target" ];
      };
    };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")
    machine.succeed("cryptsetup status cryptd")
    machine.succeed("grep -Eq '^[0-9a-f]{64}$' /run/secrets/luks.key")
  '';
}
