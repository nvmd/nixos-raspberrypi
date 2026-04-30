# RPi 5 NVMe LUKS Install Demo

This demo installs NixOS onto an RPi 5 NVMe drive at `/dev/nvme0n1` using an
SD-card installer image from the parent flake. The installed system uses a
FAT32 Raspberry Pi firmware partition at `/boot/firmware` and an
OTP-derived-key LUKS root filesystem.

The install is destructive to `/dev/nvme0n1`.

## One-Time Prep

1. Replace the placeholder in `ssh-keys.nix` with the demo operator's public
   SSH key.
2. Program the Pi's OTP private key privately, if it is not already programmed.
3. Confirm the installer can see the key once booted:

   ```shell
   rpi-otp-private-key -c
   ```

4. Confirm the RPi EEPROM boot order can boot NVMe after the SD card is
   removed.

## Build The Installer SD Image

From the repository root:

```shell
nix build .#installerImages.rpi5
```

Identify the SD card:

```shell
lsblk -dpno NAME,SIZE,MODEL,TRAN
```

Write the image after replacing `/dev/sdX` with the SD-card device:

```shell
zstdcat result/sd-image/*.img.zst | sudo dd of=/dev/sdX bs=16M status=progress conv=fsync
sync
```

## Boot The Installer

Boot the RPi 5 from the SD card with Ethernet attached. Get the displayed
credentials or IP address from the console, then verify the installer state:

```shell
ssh root@<installer-ip> 'grep VARIANT_ID=installer /etc/os-release'
ssh root@<installer-ip> 'test -b /dev/nvme0n1'
ssh root@<installer-ip> 'rpi-otp-private-key -c'
```

## Install To NVMe

From this directory on the host:

```shell
nix run github:nix-community/nixos-anywhere -- \
  --flake .#rpi5 \
  --target-host root@<installer-ip>
```

`nixos-anywhere` detects that the target is already running a NixOS installer,
so it uses that installer environment rather than kexecing a separate one.

## Boot And Verify

Power off, remove the SD card, and boot from NVMe. Then verify the installed
system:

```shell
findmnt / /boot/firmware
lsblk -o NAME,FSTYPE,TYPE,MOUNTPOINTS
cryptsetup status crypted
stat -c '%a %U %G' /var/lib/rpi-otp-derived-key/salt/luks-key
nixos-version
```

Expected results:

- `/boot/firmware` is mounted from the FAT32 firmware partition.
- `/` is mounted from the `pool/rootfs` LV.
- `crypted` is active.
- The installed salt is `400 root root`.

## Pre-Demo Checks

From the repository root:

```shell
nix build .#checks.x86_64-linux.rpi-otp-derived-key-disko-hooks
nix eval ./rpi5-luks-demo#nixosConfigurations.rpi5.config.system.build.toplevel.drvPath
```
