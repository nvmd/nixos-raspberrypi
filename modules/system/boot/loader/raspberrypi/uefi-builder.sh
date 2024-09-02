#! @bash@/bin/sh

# This can end up being called disregarding the shebang.
set -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

usage() {
    echo "usage: $0 -f <firmware-dir> -d <boot-dir> -c <path-to-default-configuration> [-r] [-u]" >&2
    exit 1
}

default=                    # Default configuration
fwtarget=/boot/firmware     # firmware target directory
boottarget=/boot            # boot configuration target directory

echo "uefi-builder: $@"
while getopts "c:d:f:ru" opt; do
    case "$opt" in
        c) default="$OPTARG" ;;
        d) boottarget="$OPTARG" ;;
        f) fwtarget="$OPTARG" ;;
        r) useVendorFirmware=1 ;;
        u) useUefiFirmware=1 ;;
        \?) usage ;;
    esac
done


copyForced() {
    local src="$1"
    local dst="$2"
    cp $src $dst.tmp
    mv $dst.tmp $dst
}

# TODO: don't just copy the "RPI_EFI.fd" image over the existing one:
# the non-volatile EFI store is backed by the UEFI image itself,
# user configuration will be lost even if the image itself hasn't changed!

if [ -n "$useVendorFirmware" ]; then
    echo "using vendor firmware"
    @firmwareBuilder@ -c $default -d $fwtarget

    echo "copying uefi firmware binary..."
    copyForced @uefi@/RPI_EFI.fd $fwtarget/@uefiBinName@
fi

if [ -n "$useUefiFirmware" ]; then
    echo "using firmware supplied with uefi firmware image"

    # merge files with vendor firmware, if they were copied before
    # don't overwrite config.txt installed by firmwareBuilder!
    rsync -a --exclude 'config.txt' --exclude 'Readme.md' @uefi@/ $fwtarget/

    echo "copying config.txt..."
    copyForced @configTxt@ $fwtarget/config.txt
fi
