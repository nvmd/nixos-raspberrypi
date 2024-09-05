#! @bash@/bin/sh

# This can end up being called disregarding the shebang.
set -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

usage() {
    echo "usage: $0 -f <firmware-dir> -d <boot-dir> -c <path-to-default-configuration>" >&2
    exit 1
}

default=               # Default configuration, needed for extlinux
fwtarget=/boot/firmware  # firmware target directory
boottarget=/boot         # boot configuration target directory

echo "uboot-builder: $@"
while getopts "c:d:f:" opt; do
    case "$opt" in
        c) default="$OPTARG" ;;
        d) boottarget="$OPTARG" ;;
        f) fwtarget="$OPTARG" ;;
        \?) usage ;;
    esac
done
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
    cp $src $dst.tmp
    mv $dst.tmp $dst
}

@firmwareBuilder@ -c $default -d $fwtarget

echo "generating extlinux configuration..."
# Call the extlinux builder
@extlinuxConfBuilder@ -c $default -d $boottarget

echo "copying u-boot binary..."
# Add the uboot file
copyForced @uboot@/u-boot.bin $fwtarget/@ubootBinName@

echo "uboot+extlinux bootloader installed"
