#! @bash@/bin/sh -e

# shellcheck disable=SC3030,SC3043,SC3044,SC3054

shopt -s nullglob

export PATH=/empty:@path@

usage() {
    echo "usage: $0 -c <path-to-configuration> [-d <destination-dir>] [-r]" >&2
    exit 1
}

generationPath=         # Path to nixos configuration/generation
target=/boot/firmware   # Device tree files target directory

while getopts "c:d:r" opt; do
    case "$opt" in
        c) generationPath="$OPTARG" ;;
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

    local dstTmp="$dst.tmp.$$"

    cp "$src" "$dstTmp"
    mv "$dstTmp" "$dst"
}

echo "$0: $@"
echo -n "installing device tree files: "

# Device Tree

if [ -n "$useVendorDeviceTree" ]; then
    echo -n "vendor firmware "
    dtb_path=@firmware@/share/raspberrypi/boot
else
    echo -n "generation's kernel's "
    dtb_path=$(readlink -f "$generationPath/dtbs")
fi
echo "$dtb_path"

# firmware package has dtbs in its root,
# dtbs built with kernel are in broadcom/
DTBS=("$dtb_path"/*.dtb "$dtb_path"/broadcom/*.dtb)
for dtb in "${DTBS[@]}"; do
    dst="$target/$(basename "$dtb")"
    copyForced "$dtb" "$dst"
    filesCopied[$dst]=1
done

SRC_OVERLAYS=("$dtb_path/overlays"/*)
mkdir -p "$target/overlays"
for ovr in "${SRC_OVERLAYS[@]}"; do
    dst="$target/overlays/$(basename "$ovr")"
    copyForced "$ovr" "$dst"
    filesCopied[$dst]=1
done

# remove obsolete device tree files
for fn in $target/*.dtb $target/overlays/*; do
    if ! test "${filesCopied[$fn]}" = 1; then
        rm -vf -- "$fn"
    fi
done
