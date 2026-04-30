{ config
, disko
, lib
, nixos-raspberrypi
, pkgs
, ...
}:

let
  stagedSaltDir = "/run/rpi-otp-derived-key/disko-install/salt";
  stagedSalt = "${stagedSaltDir}/luks-key";
  stagedKeyDir = "/run/secrets";
  stagedKey = "${stagedKeyDir}/luks.key";
  installedSalt = "${config.disko.rootMountPoint}/var/lib/rpi-otp-derived-key/salt/luks-key";
  rpiOtpProvision = pkgs.rpi-otp-derived-key-provision or
    nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.rpi-otp-derived-key-provision;
in
{
  imports = [
    disko.nixosModules.disko
  ];

  disko.devices = {
    disk.nvme0-luks = {
      type = "disk";
      device = lib.mkDefault "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            priority = 1;
            size = "1G";
            type = "0700";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/firmware";
              mountOptions = [
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
              ];
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings = {
                keyFile = stagedKey;
                allowDiscards = true;
              };
              # This is a disko-only hook.
              preCreateHook = ''
                if ${pkgs.cryptsetup}/bin/cryptsetup isLuks "$device" >/dev/null 2>&1; then
                  echo "Refusing to reuse existing LUKS device $device for OTP-derived install key." >&2
                  exit 1
                fi

                # Generate a random salt for our LUKS volume & derive a key from it.
                ${lib.getExe rpiOtpProvision} stage \
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
    };

    lvm_vg.pool = {
      type = "lvm_vg";
      lvs.rootfs = {
        size = "100%";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
          # This is a disko-only hook that runs when disko-install mounts this partition.
          postMountHook = ''
            ${lib.getExe rpiOtpProvision} install-salt \
              --salt-file "${stagedSalt}" \
              --target-file "${installedSalt}" \
              --cleanup "${stagedSalt}" \
              --cleanup "${stagedKey}"
          '';
        };
      };
    };
  };
}
