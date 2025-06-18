#! @bash@/bin/sh -e

shopt -s nullglob

export PATH=/empty:@path@

usage() {
    echo "usage: $0 -f <firmware-dir> -b <boot-dir> -c <path-to-default-configuration>" >&2
    exit 1
}

default=               # Default configuration, needed for extlinux
# fwtarget=/boot/firmware  # firmware target directory
# boottarget=/boot         # boot configuration target directory

echo "uboot-builder: $@"
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
    cp $src $dst.tmp
    mv $dst.tmp $dst
}

if [ -n "$fwtarget" ]; then
    @firmwareBuilder@ -c $default -d $fwtarget

    echo "copying u-boot binary..."
    copyForced @uboot@/u-boot.bin $fwtarget/@ubootBinName@
fi

if [ -n "$boottarget" ]; then
    echo "generating extlinux configuration..."
    @extlinuxConfBuilder@ -c $default -d $boottarget
fi

msg=""
if [ -n "$fwtarget" ]; then
    msg="uboot"
fi
if [ -n "$boottarget" ]; then
    msg="$msg+extlinux"
fi
echo "$msg bootloader installed"
