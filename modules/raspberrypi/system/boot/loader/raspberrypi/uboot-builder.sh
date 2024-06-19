#! @bash@/bin/sh

# This can end up being called disregarding the shebang.
set -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

usage() {
    echo "usage: $0 -f <firmware-dir> -t <timeout> -c <path-to-default-configuration> [-d <boot-dir>] [-g <num-generations>] [-n <dtbName>] [-r]" >&2
    echo "all options following '-f <firmware-dir>' are passed directly to generic-extlinux-compatible's builder" >&2
    exit 1
}

target=/boot/firmware  # firmware target directory

echo $@
# process arguments for this builder, then pass the remainder to extlinux'
while getopts ":f:" opt; do
    case "$opt" in
        f) target="$OPTARG" ;;
        *) ;;
    esac
done
shift $((OPTIND-2))
extlinuxBuilderExtraArgs="$@"

copyForced() {
    local src="$1"
    local dst="$2"
    cp $src $dst.tmp
    mv $dst.tmp $dst
}

# Call the extlinux builder
@extlinuxConfBuilder@ $extlinuxBuilderExtraArgs

@firmwareBuilder@ "-d $target"

# # Add the firmware files
# # fwdir=@firmware@/share/raspberrypi/boot/
# SRC_FIRMWARE_DIR=@firmware@/share/raspberrypi/boot

# DTBS=("$SRC_FIRMWARE_DIR"/*.dtb)
# for dtb in "${DTBS[@]}"; do
# # for dtb in $dtb_path/broadcom/*.dtb; do
#     dst="$target/$(basename $dtb)"
#     copyForced $dtb "$dst"
# done

# SRC_OVERLAYS_DIR="$SRC_FIRMWARE_DIR/overlays"
# SRC_OVERLAYS=("$SRC_OVERLAYS_DIR"/*)
# mkdir -p $target/overlays
# for ovr in "${SRC_OVERLAYS[@]}"; do
# # for ovr in $dtb_path/overlays/*; do
#     dst="$target/overlays/$(basename $ovr)"
#     copyForced $ovr "$dst"
# done

# STARTFILES=("$SRC_FIRMWARE_DIR"/start*.elf)
# BOOTCODE="$SRC_FIRMWARE_DIR/bootcode.bin"
# FIXUPS=("$SRC_FIRMWARE_DIR"/fixup*.dat)
# for SRC in "${STARTFILES[@]}" "$BOOTCODE" "${FIXUPS[@]}"; do
#     dst="$target/$(basename $SRC)"
#     copyForced "$SRC" "$dst"
# done

# # Add the config.txt
# copyForced @configTxt@ $target/config.txt

# Add the uboot file
copyForced @uboot@/u-boot.bin $target/@ubootBinName@
