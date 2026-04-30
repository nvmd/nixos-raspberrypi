{ lib, pkgs, self }:

let
  testSupport = import ./lib/rpi-otp-derived-key-test-support.nix {
    inherit lib pkgs;
  };
  inherit (testSupport) testPkgs;

  rootMountPoint = "/mnt";
  stagedSaltDir = "/run/rpi-otp-derived-key/disko-install/salt";
  stagedSalt = "${stagedSaltDir}/luks-key";
  stagedKeyDir = "/run/secrets";
  stagedKey = "${stagedKeyDir}/luks.key";
  installedSalt = "${rootMountPoint}/var/lib/rpi-otp-derived-key/salt/luks-key";
  luksPartition = "/dev/disk/by-partlabel/disk-test-luks";

  disko = import "${testPkgs.disko}/share/disko" {
    inherit lib rootMountPoint;
  };

  diskoConfig = {
    disko.devices = {
      disk.test = {
        type = "disk";
        device = "/dev/vdb";
        content = {
          type = "gpt";
          partitions.luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings.keyFile = stagedKey;
              extraFormatArgs = [ "--iter-time=1" ];

              preCreateHook = ''
                if ${testPkgs.cryptsetup}/bin/cryptsetup isLuks "$device" >/dev/null 2>&1; then
                  echo "Refusing to reuse existing LUKS device $device for OTP-derived install key." >&2
                  exit 1
                fi

                ${lib.getExe testPkgs.rpi-otp-derived-key-provision} stage \
                  --format hex \
                  --salt-file "${stagedSalt}" \
                  --out "${stagedKey}"
              '';

              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };

      lvm_vg.pool = {
        type = "lvm_vg";
        lvs.rootfs = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";

            postMountHook = ''
              ${lib.getExe testPkgs.rpi-otp-derived-key-provision} install-salt \
                --salt-file "${stagedSalt}" \
                --target-file "${installedSalt}" \
                --cleanup "${stagedSalt}" \
                --cleanup "${stagedKey}"
            '';
          };
        };
      };
    };
  };

  diskoScript = disko._cliFormatMount diskoConfig testPkgs;
in
testPkgs.testers.runNixOSTest {
  name = "rpi-otp-derived-key-disko-hooks";

  nodes.machine = {
    virtualisation.emptyDiskImages = [ 1024 ];

    environment.systemPackages = [
      testPkgs.cryptsetup
      testPkgs.lvm2
      testPkgs.rpi-otp-derived-key
      testPkgs.rpi-otp-derived-key-provision
    ];

    system.stateVersion = "25.11";
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")
    machine.succeed("${diskoScript}/bin/disko-format-mount")

    machine.succeed("cryptsetup isLuks ${luksPartition}")
    machine.succeed("test -e ${installedSalt}")
    machine.succeed("stat -c '%a %U %G' ${installedSalt} | grep -qx '400 root root'")
    machine.fail("test -e ${stagedSalt}")
    machine.fail("test -e ${stagedKey}")

    machine.succeed("${lib.getExe testPkgs.rpi-otp-derived-key} --format hex --salt-file ${installedSalt} > /tmp/derived-luks.key")
    machine.succeed("grep -Eq '^[0-9a-f]{64}$' /tmp/derived-luks.key")
    machine.succeed("cryptsetup open --test-passphrase --key-file /tmp/derived-luks.key ${luksPartition}")
  '';
}
