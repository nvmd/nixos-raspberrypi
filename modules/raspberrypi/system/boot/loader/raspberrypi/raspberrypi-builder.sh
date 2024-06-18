#! @bash@/bin/sh

# This can end up being called disregarding the shebang.
set -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

usage() {
    echo "usage: $0 -c <path-to-default-configuration> [-d <boot-dir>]" >&2
    exit 1
}

default=                # Default configuration
target=/boot            # Target directory

# fwdir=@firmware@/share/raspberrypi/boot/
SRC_FIRMWARE_DIR=@firmware@/share/raspberrypi/boot

while getopts "c:d:" opt; do
    case "$opt" in
        c) default="$OPTARG" ;;
        d) target="$OPTARG" ;;
        \?) usage ;;
    esac
done

echo "updating the boot generations directory..."

mkdir -p $target/old

# Convert a path to a file in the Nix store such as
# /nix/store/<hash>-<name>/file to <hash>-<name>-<file>.
cleanName() {
    local path="$1"
    echo "$path" | sed 's|^/nix/store/||' | sed 's|/|-|g'
}

# Copy a file from the Nix store to $target/kernels.
declare -A filesCopied

copyToKernelsDir() {
    local src="$1"
    local dst="$target/old/$(cleanName $src)"
    # Don't copy the file if $dst already exists.  This means that we
    # have to create $dst atomically to prevent partially copied
    # kernels or initrd if this script is ever interrupted.
    if ! test -e $dst; then
        local dstTmp=$dst.tmp.$$
        cp $src $dstTmp
        mv $dstTmp $dst
    fi
    filesCopied[$dst]=1
    result=$dst
}

copyForced() {
    local src="$1"
    local dst="$2"
    cp $src $dst.tmp
    mv $dst.tmp $dst
}

outdir=$target/old
mkdir -p $outdir || true

# Copy its kernel and initrd to $target/old.
addEntry() {
    local path="$1"
    local generation="$2"

    if ! test -e $path/kernel -a -e $path/initrd; then
        return
    fi

    local kernel=$(readlink -f $path/kernel)
    local initrd=$(readlink -f $path/initrd)
    # local dtb_path=$(readlink -f $path/dtbs)
    local dtb_path=$SRC_FIRMWARE_DIR

    if test -n "@copyKernels@"; then
        copyToKernelsDir $kernel; kernel=$result
        copyToKernelsDir $initrd; initrd=$result
    fi

    echo $(readlink -f $path) > $outdir/$generation-system
    echo $(readlink -f $path/init) > $outdir/$generation-init
    cp $path/kernel-params $outdir/$generation-cmdline.txt
    echo $initrd > $outdir/$generation-initrd
    echo $kernel > $outdir/$generation-kernel

    if test "$generation" = "default"; then
      copyForced $kernel $target/kernel.img
      copyForced $initrd $target/initrd

      DTBS=("$dtb_path"/*.dtb)
      for dtb in "${DTBS[@]}"; do
          dst="$target/$(basename $dtb)"
          copyForced $dtb "$dst"
          filesCopied[$dst]=1
      done

      SRC_OVERLAYS_DIR="$dtb_path/overlays"
      SRC_OVERLAYS=("$SRC_OVERLAYS_DIR"/*)
      mkdir -p $target/overlays
      for ovr in "${SRC_OVERLAYS[@]}"; do
      # for ovr in $dtb_path/overlays/*; do
          dst="$target/overlays/$(basename $ovr)"
          copyForced $ovr "$dst"
          filesCopied[$dst]=1
      done

      cp "$(readlink -f "$path/init")" $target/nixos-init
      echo "`cat $path/kernel-params` init=$path/init" >$target/cmdline.txt
    fi
}

addEntry $default default

# Add all generations of the system profile to the menu, in reverse
# (most recent to least recent) order.
for generation in $(
    (cd /nix/var/nix/profiles && ls -d system-*-link) \
    | sed 's/system-\([0-9]\+\)-link/\1/' \
    | sort -n -r); do
    link=/nix/var/nix/profiles/system-$generation-link
    addEntry $link $generation
done

# Add the firmware files
# # fwdir=@firmware@/share/raspberrypi/boot/
# SRC_FIRMWARE_DIR=@firmware@/share/raspberrypi/boot
STARTFILES=("$SRC_FIRMWARE_DIR"/start*.elf)
BOOTCODE="$SRC_FIRMWARE_DIR/bootcode.bin"
FIXUPS=("$SRC_FIRMWARE_DIR"/fixup*.dat)
for SRC in "${STARTFILES[@]}" "$BOOTCODE" "${FIXUPS[@]}"; do
    dst="$target/$(basename $SRC)"
    copyForced "$SRC" "$dst"
done

# Add the config.txt
copyForced @configTxt@ $target/config.txt

# Remove obsolete files from $target and $target/old.
for fn in $target/old/*linux* $target/old/*initrd-initrd* $target/*.dtb $target/overlays/*; do
    if ! test "${filesCopied[$fn]}" = 1; then
        rm -vf -- "$fn"
    fi
done
