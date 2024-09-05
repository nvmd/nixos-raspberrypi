#! @bash@/bin/sh

# This can end up being called disregarding the shebang.
set -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

usage() {
    echo "usage: $0 -c <path-to-default-configuration> [-d <boot-dir>] [-r]" >&2
    exit 1
}

default=                # Default configuration
target=/boot/firmware   # Firmware target directory

while getopts "c:d:r" opt; do
    case "$opt" in
        c) default="$OPTARG" ;;
        d) target="$OPTARG" ;;
        r) useVendorDeviceTree=1 ;;
        \?) usage ;;
    esac
done

# Copy a file from the Nix store to $target.
declare -A filesCopied

copyForced() {
    local src="$1"
    local dst="$2"
    cp $src $dst.tmp
    mv $dst.tmp $dst
}

# Add the firmware files
# fwdir=@firmware@/share/raspberrypi/boot/
SRC_FIRMWARE_DIR=@firmware@/share/raspberrypi/boot
dtb_path=$SRC_FIRMWARE_DIR

echo "copying firmware..."

# Device Tree

if [ -n "$useVendorDeviceTree" ]; then
    echo -n "using vendor firmware from "
    dtb_path=$SRC_FIRMWARE_DIR
else
    echo -n "using default generation's kernel device tree binaries: "
    dtb_path=$(readlink -f $default/dtbs)
fi
echo $dtb_path

DTBS=("$dtb_path"/*.dtb)
for dtb in "${DTBS[@]}"; do
# for dtb in $dtb_path/broadcom/*.dtb; do
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

# remove obsolete device tree files
for fn in $target/*.dtb $target/overlays/*; do
    if ! test "${filesCopied[$fn]}" = 1; then
        rm -vf -- "$fn"
    fi
done


# Boot code

STARTFILES=("$SRC_FIRMWARE_DIR"/start*.elf)
BOOTCODE="$SRC_FIRMWARE_DIR/bootcode.bin"
FIXUPS=("$SRC_FIRMWARE_DIR"/fixup*.dat)
for SRC in "${STARTFILES[@]}" "$BOOTCODE" "${FIXUPS[@]}"; do
    dst="$target/$(basename $SRC)"
    copyForced "$SRC" "$dst"
done

echo "copying config.txt..."
# Add the config.txt
copyForced @configTxt@ $target/config.txt

echo "raspberry pi firmware installed"
