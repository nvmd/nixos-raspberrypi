#! @bash@/bin/sh -e

# shellcheck disable=SC3037,SC3043,SC3044

shopt -s nullglob

export PATH=/empty:@path@

copyForced() {
    local src="$1"
    local dst="$2"

    local dstTmp="$dst.tmp.$$"

    cp "$src" "$dstTmp"
    mv "$dstTmp" "$dst"
}

# Copy generation's kernel, initrd, cmdline to `genDir`.
addEntry() {
    local generationPath="$1"
    local generationName="$2"
    local genDir="$3"

    if ! { [ -e "$generationPath/kernel" ] && [ -e "$generationPath/initrd" ]; }; then
        return
    fi

    echo -n "kernel..."

    local kernel="$(readlink -f "$generationPath/kernel")"
    local initrd="$(readlink -f "$generationPath/initrd")"

    readlink -f "$generationPath" > "$genDir/system-link"
    echo "$kernel" > "$genDir/kernel-link"

    copyForced "$kernel" "$genDir/kernel.img"
    copyForced "$initrd" "$genDir/initrd"
    echo "$(cat "$generationPath/kernel-params") init=$generationPath/init" > "$genDir/cmdline.txt"

    echo -n "device tree..."

    @installDeviceTree@ -c "$generationPath" -d "$genDir"

    echo
}

usage() {
    echo "usage: $0 -c <path-to-configuration> -n <configuration-name> -d <installation-directory>" >&2
    exit 1
}

generationPath=         # Path to nixos configuration/generation
generationName=         # Name of the generation
target=/boot/firmware   # Target directory

echo "$0: $@"
while getopts "c:n:d:" opt; do
    case "$opt" in
        c) generationPath="$OPTARG" ;;
        n) generationName="$OPTARG" ;;
        d) target="$OPTARG" ;;
        \?) usage ;;
    esac
done

addEntry "$generationPath" "$generationName" "$target"
echo "kernel boot files installed for nixos generation '$generationName'"
