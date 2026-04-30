# OTP-derived LUKS installs with disko

For a fresh encrypted install, the key file must exist before disko formats the
LUKS device. This can be done with existing disko hooks: stage the salt and key
in the LUKS node's `preCreateHook`, then install the salt into the target root
from the root filesystem's `postMountHook`.

This example matches an LVM-on-LUKS root layout where the OTP-derived secret is
named `luks-key` and the LUKS key file is `/run/secrets/luks.key`.
The hook pattern is covered by
`.#checks.x86_64-linux.rpi-otp-derived-key-disko-hooks`.

```nix
{ config, disko, lib, pkgs, nixos-raspberrypi, ... }:
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
    nixos-raspberrypi.nixosModules.rpi-otp-derived-key
  ];

  boot.initrd.systemd.enable = true;

  services.rpiOtpDerivedKey = {
    enable = true;
    secrets.luks-key = {
      format = "hex";
      path = stagedKey;
      neededForBoot = true;
      # LUKS is the consumer, so it owns the cryptsetup-specific ordering.
      before = [ "cryptsetup-pre.target" ];
    };
  };

  disko.devices.disk.nvme0-luks.content.partitions.luks.content = {
    type = "luks";
    name = "crypted";
    settings.keyFile = stagedKey;

    preCreateHook = ''
      if ${pkgs.cryptsetup}/bin/cryptsetup isLuks "$device" >/dev/null 2>&1; then
        echo "Refusing to reuse existing LUKS device $device for OTP-derived install key." >&2
        exit 1
      fi

      ${lib.getExe rpiOtpProvision} stage \
        --format hex \
        --salt-file "${stagedSalt}" \
        --out "${stagedKey}"
    '';
  };

  disko.devices.lvm_vg.pool.lvs.rootfs.content.postMountHook = ''
    ${lib.getExe rpiOtpProvision} install-salt \
      --salt-file "${stagedSalt}" \
      --target-file "${installedSalt}" \
      --cleanup "${stagedSalt}" \
      --cleanup "${stagedKey}"
  '';
}
```

Then run plain `disko-install`:

```shell
sudo disko-install --flake .#rpi5 --disk nvme0-luks /dev/nvme0n1
```

This hook pattern is for fresh formatting only. Existing LUKS devices need
manual key enrollment or `disko-install --mode mount`. If installation fails
after LUKS formatting but before the root filesystem hook copies the salt,
reformat and reinstall; the matching salt may only exist in `/run`.

`rpi-otp-derived-key-provision` checks that the OTP private key is programmed,
creates the salt and derived key atomically, installs them as `0400 root:root`,
and removes the staged files after the salt is copied. Keep a recovery
passphrase or recovery key enrolled before relying on unattended unlock. For
other disko layouts, attach the same two hooks to the LUKS node and the mounted
root filesystem node.
