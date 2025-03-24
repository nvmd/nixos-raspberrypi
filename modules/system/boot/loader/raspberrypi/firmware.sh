#!/usr/bin/env bash

set -euo pipefail

configtxt="$1"
bootcode_source="$2"
dtb_source="$3"
target="$4"   # Firmware target directory

# Add the firmware files
dtb_path="$dtb_source"


echo "copying dtbs..."

DTBS=("$dtb_path"/*.dtb)
for dtb in "${DTBS[@]}"; do
# for dtb in $dtb_path/broadcom/*.dtb; do
    dst="$target/$(basename "$dtb")"
    cp "$dtb" "$dst"
done

SRC_OVERLAYS_DIR="$dtb_path/overlays"
SRC_OVERLAYS=("$SRC_OVERLAYS_DIR"/*)
mkdir -p "$target"/overlays
for ovr in "${SRC_OVERLAYS[@]}"; do
# for ovr in $dtb_path/overlays/*; do
    dst="$target/overlays/$(basename "$ovr")"
    cp "$ovr" "$dst"
done


echo "copying bootcode..."

STARTFILES=("$bootcode_source"/start*.elf)
BOOTCODE="$bootcode_source/bootcode.bin"
FIXUPS=("$bootcode_source"/fixup*.dat)
for SRC in "${STARTFILES[@]}" "$BOOTCODE" "${FIXUPS[@]}"; do
    dst="$target/$(basename "$SRC")"
    cp "$SRC" "$dst"
done

echo "copying config.txt..."
cp "$configtxt" "$target"/config.txt
