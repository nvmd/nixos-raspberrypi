#! @bash@/bin/sh -e

# shellcheck disable=SC3030,SC3043,SC3044,SC3054

shopt -s nullglob

export PATH=/empty:@path@

usage() {
    echo "usage: $0 -c <path-to-configuration> [-d <firmware-dir>]" >&2
    exit 1
}

generationPath=         # Path to nixos configuration/generation
target=/boot/firmware   # Firmware target directory

while getopts "c:d:" opt; do
    case "$opt" in
        c) generationPath="$OPTARG" ;;
        d) target="$OPTARG" ;;
        \?) usage ;;
    esac
done

# Copy a file from the Nix store to $target.
declare -A filesCopied

copyForced() {
    local src="$1"
    local dst="$2"

    local dstTmp="$dst.tmp.$$"

    cp "$src" "$dstTmp"
    mv "$dstTmp" "$dst"
}

# Add the firmware files
# fwdir=@firmware@/share/raspberrypi/boot/
SRC_FIRMWARE_DIR=@firmware@/share/raspberrypi/boot

echo "copying raspberry pi firmware..."

# Boot code

STARTFILES=("$SRC_FIRMWARE_DIR"/start*.elf)
BOOTCODE="$SRC_FIRMWARE_DIR/bootcode.bin"
FIXUPS=("$SRC_FIRMWARE_DIR"/fixup*.dat)
for SRC in "${STARTFILES[@]}" "$BOOTCODE" "${FIXUPS[@]}"; do
    dst="$target/$(basename "$SRC")"
    copyForced "$SRC" "$dst"
    filesCopied[$dst]=1
done

# remove obsolete firmware files
for fn in $target/start*.elf $target/fixup*.dat; do
    if ! test "${filesCopied[$fn]}" = 1; then
        rm -vf -- "$fn"
    fi
done

echo "copying config.txt..."
# Add the config.txt
copyForced @configTxt@ "$target/config.txt"

echo "raspberry pi firmware installed"
