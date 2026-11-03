# Populates firmware and boot partitions with the configuration's bootloader
# the way `sd-image-raspberrypi.nix` does, but for a fake system generation, so
# that no kernel has to be built, then checks what ended up on them.
# The result is the populated partitions, handy to inspect when changing the
# bootloader:
#   nix build .#checks.aarch64-linux.bootloader-rpi5-kernel && tree result
{
  pkgs,
  name,
  nixos,
  # device tree file the vendor firmware provides for the board
  dtb,
}:

let
  inherit (pkgs) lib;
  inherit (nixos) config;
  cfg = config.boot.loader.raspberry-pi;

  fw = "${cfg.firmwarePackage}/share/raspberrypi/boot";
  kernelParams = toString config.boot.kernelParams;

  # only the parts of `system.build.toplevel` the installers read
  generation = pkgs.runCommand "fake-generation-${name}" { } ''
    mkdir -p $out/dtbs/broadcom $out/dtbs/overlays
    echo kernel > $out/kernel
    echo initrd > $out/initrd
    echo init > $out/init
    echo -n ${lib.escapeShellArg kernelParams} > $out/kernel-params
    echo -n ${lib.escapeShellArg config.system.nixos.label} > $out/nixos-version
    echo dtb > $out/dtbs/broadcom/${dtb}
    echo overlay > $out/dtbs/overlays/test.dtbo
  '';

  cmdline = lib.escapeShellArg "${kernelParams} init=${generation}/init";

  # what each bootloader is expected to install
  expected = {
    kernel = ''
      hasLine $out/firmware/config.txt "os_prefix=${cfg.nixosGenerationsDir}/default/"
      hasLine $out/firmware/config.txt "kernel=kernel.img"
      hasLine $out/firmware/config.txt "initramfs initrd followkernel"

      gen=$out/firmware/${cfg.nixosGenerationsDir}/default
      sameFile ${generation}/kernel $gen/kernel.img
      sameFile ${generation}/initrd $gen/initrd
      hasLine $gen/cmdline.txt ${cmdline}
      # device tree of the generation's kernel
      sameFile ${generation}/dtbs/broadcom/${dtb} $gen/${dtb}
      sameFile ${generation}/dtbs/overlays/test.dtbo $gen/overlays/test.dtbo
    '';

    kernelboot = ''
      hasLine $out/firmware/config.txt "kernel=kernel.img"
      hasLine $out/firmware/config.txt "initramfs initrd followkernel"

      sameFile ${generation}/kernel $out/firmware/kernel.img
      sameFile ${generation}/initrd $out/firmware/initrd
      hasLine $out/firmware/cmdline.txt ${cmdline}
      # device tree of the vendor firmware
      sameFile ${fw}/${dtb} $out/firmware/${dtb}
      hasOverlays $out/firmware/overlays
    '';

    uboot = ''
      hasLine $out/firmware/config.txt "kernel=u-boot-rpi-arm64.bin"

      sameFile ${cfg.ubootPackage}/u-boot.bin $out/firmware/u-boot-rpi-arm64.bin
      # device tree of the vendor firmware
      sameFile ${fw}/${dtb} $out/firmware/${dtb}
      hasOverlays $out/firmware/overlays
      grep -qF "init=${generation}/init" $out/boot/extlinux/extlinux.conf \
        || fail "extlinux.conf doesn't boot the generation"
    '';
  };
in
pkgs.runCommand "bootloader-${name}" { } ''
  fail() { echo "FAIL: $*" >&2; exit 1; }
  sameFile() { cmp -s "$1" "$2" || fail "$2 isn't a copy of $1"; }
  hasLine() { grep -qxF -- "$2" "$1" || fail "$1 has no line '$2'"; }
  hasOverlays() { [ -n "$(ls -A "$1")" ] || fail "no device tree overlays in $1"; }

  mkdir -p $out/firmware $out/boot
  ${cfg.firmwarePopulateCmd} -c ${generation} -f $out/firmware
  ${cfg.bootPopulateCmd} -c ${generation} -b $out/boot

  # boot code and config.txt, whatever the bootloader
  sameFile ${cfg.configTxtPackage} $out/firmware/config.txt
  for f in ${fw}/bootcode.bin ${fw}/start*.elf ${fw}/fixup*.dat; do
    sameFile "$f" "$out/firmware/$(basename "$f")"
  done

  ${expected.${cfg.bootloader}}
''
