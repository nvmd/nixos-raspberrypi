#! @bash@/bin/sh -e

# shellcheck shell=bash disable=SC2012,SC2239

shopt -s nullglob

export PATH=/empty:@path@

usage() {
    echo "usage: $0 -f <firmware-dir> -b <boot-dir> -c <path-to-default-configuration>" >&2
    exit 1
}

default=               # Default configuration, needed for extlinux
boottarget=
fwtarget=

# shellcheck source=modules/system/boot/loader/raspberrypi/initrd-secrets.sh
. @initrdSecrets@

echo "uboot-builder: $*"
while getopts "c:b:f:" opt; do
    case "$opt" in
        c) default="$OPTARG" ;;
        b) boottarget="$OPTARG" ;;
        f) fwtarget="$OPTARG" ;;
        \?) usage ;;
    esac
done

if [ -z "$boottarget" ] && [ -z "$fwtarget" ]; then
    echo "Error: at least one of \`-b <boot-dir>\` and \`-f <firmware-dir>\` must be set"
    usage
fi

# # process arguments for this builder, then pass the remainder to extlinux'
# while getopts ":f:" opt; do
#     case "$opt" in
#         f) target="$OPTARG" ;;
#         *) ;;
#     esac
# done
# shift $((OPTIND-2))
# extlinuxBuilderExtraArgs="$@"

copyForced() {
    local src="$1"
    local dst="$2"
    cp "$src" "$dst.tmp"
    mv "$dst.tmp" "$dst"
}

cleanName() {
    local path="$1"
    echo "$path" | sed 's|^/nix/store/||' | sed 's|/|-|g'
}

appendGenerationInitrdSecrets() {
    local generationPath="$1"
    local generationName="$2"
    local target="$3"

    if ! [ -e "$generationPath/initrd" ]; then
        return 0
    fi

    local initrdSource
    local initrdPath
    initrdSource="$(readlink -f "$generationPath/initrd")"
    initrdPath="$target/nixos/$(cleanName "$initrdSource")"

    appendInitrdSecrets "$generationPath" "$initrdPath" "$generationName"
}

appendAllInitrdSecrets() {
    local defaultGenerationPath="$1"
    local target="$2"

    appendGenerationInitrdSecrets "$defaultGenerationPath" default "$target"

    for generation in $(
        (cd /nix/var/nix/profiles && ls -d system-*-link) \
        | sed 's/system-\([0-9]\+\)-link/\1/' \
        | sort -n -r); do
        link=/nix/var/nix/profiles/system-$generation-link
        appendGenerationInitrdSecrets "$link" "${generation}-default" "$target"
        for specialisation in $(
            ls "/nix/var/nix/profiles/system-$generation-link/specialisation" \
            | sort -n -r); do
            link=/nix/var/nix/profiles/system-$generation-link/specialisation/$specialisation
            appendGenerationInitrdSecrets "$link" "${generation}-${specialisation}" "$target"
        done
    done
}

if [ -n "$fwtarget" ]; then
    @firmwareBuilder@ -c "$default" -d "$fwtarget"

    echo "copying u-boot binary..."
    copyForced @uboot@/u-boot.bin "$fwtarget/@ubootBinName@"
fi

if [ -n "$boottarget" ]; then
    echo "generating extlinux configuration..."
    @extlinuxConfBuilder@ -c "$default" -d "$boottarget"
    appendAllInitrdSecrets "$default" "$boottarget"
fi

msg=""
if [ -n "$fwtarget" ]; then
    msg="uboot"
fi
if [ -n "$boottarget" ]; then
    msg="$msg+extlinux"
fi
echo "$msg bootloader installed"
