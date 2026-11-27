#! @bash@/bin/sh -e

# shellcheck shell=bash disable=SC2012,SC2239

shopt -s nullglob

export PATH=/empty:@path@

# used to track copied generations to decide which are obsolete
# and need to be removed
declare -A activeGenerations

moveWBackup() {
    local src="$1"
    local dst="$2"

    # Backup $dst if already exists
    local dstBkp="$dst.bkp.$$"
    if [ -e "$dst" ]; then
        mv "$dst" "$dstBkp"
    fi

    # Move $src as "new" $dst, restoring the previous directory if the
    # publication itself fails.
    if ! mv "$src" "$dst"; then
        if [ -e "$dstBkp" ]; then
            mv "$dstBkp" "$dst"
        fi
        return 1
    fi

    # Remove backup directory of the previous $dst
    rm -rf "$dstBkp"
}

# Copy generation's kernel, initrd, cmdline to `gensDir/generationName`.
addEntry() {
    local generationPath="$1"
    local generationName="$2"
    local gensDir="$3"

    local dst="$gensDir/$generationName"

    echo "* nixos generation '$generationName' -> $dst"
    # Rebuild every retained generation from its immutable store initrd. This
    # prevents an activation from retaining a stale or repeatedly-appended
    # secret payload in an older generation.
    local dstTmp
    dstTmp="$(mktemp -d "$gensDir/.${generationName}.tmp.XXXXXX")"

    if ! @nixosGenBuilder@ -c "$generationPath" -n "$generationName" -d "$dstTmp"; then
        rm -rf -- "$dstTmp"
        return 1
    fi

    if [ -e "$dstTmp/.skip-generation" ]; then
        rm -rf -- "$dstTmp"
        return 0
    fi

    # Publish the complete generation directory only after its secret payload,
    # kernel, command line and device trees have all been created successfully.
    moveWBackup "$dstTmp" "$dst"

    activeGenerations["$generationName"]=1
}

removeObsoleteGenerations() {
    local path="$1"

    echo "removing obsolete generations in $path..."
    for gen in "$path"/*; do
        if ! [ "${activeGenerations["$(basename "$gen")"]}" = 1 ]; then
            echo "* $gen is obsolete"
            rm -vrf "$gen"
        fi
    done
}

addAllEntries() {
    local defaultGenerationPath="$1"
    local outdir="$2"
    local numGenerations="$3"

    local gensDir="$outdir/@nixosGenerationsDir@"
    mkdir -p "$gensDir" || true

    # Add default generation
    addEntry "$defaultGenerationPath" default "$gensDir"

    if [ "$numGenerations" -gt 0 ]; then
        # Add up to $numGenerations generations of the system profile, in reverse
        # (most recent to least recent) order.
        for generation in $(
            (cd /nix/var/nix/profiles && ls -d system-*-link) \
            | sed 's/system-\([0-9]\+\)-link/\1/' \
            | sort -n -r \
            | head -n "$numGenerations"); do
            link=/nix/var/nix/profiles/system-$generation-link
            addEntry "$link" "${generation}-default" "$gensDir"
            for specialisation in $(
                ls "/nix/var/nix/profiles/system-$generation-link/specialisation" \
                | sort -n -r); do
                link=/nix/var/nix/profiles/system-$generation-link/specialisation/$specialisation
                addEntry "$link" "${generation}-${specialisation}" "$gensDir"
            done
        done
    fi

    removeObsoleteGenerations "$gensDir"
}

usage() {
    echo "usage: $0 -c <path-to-default-configuration> [-b <boot-dir>] [-g <num-generations>]" >&2
    exit 1
}


default=                # Default configuration
numGenerations=0        # Number of other generations to keep (kernel, initrd, DTBs, overlays)
boottarget=
fwtarget=

echo "$0: $*"
while getopts "c:b:g:f:" opt; do
    case "$opt" in
        c) default="$OPTARG" ;;
        b) boottarget="$OPTARG" ;;
        g) numGenerations="$OPTARG" ;;
        f) fwtarget="$OPTARG" ;;
        \?) usage ;;
    esac
done

if [ -z "$boottarget" ] && [ -z "$fwtarget" ]; then
    echo "Error: at least one of \`-b <boot-dir>\` and \`-f <firmware-dir>\` must be set"
    usage
fi

if [ -n "$fwtarget" ]; then
    echo "installing nixos-generation-independent firmware..."
    @installFirmwareBuilder@ -c "$default" -d "$fwtarget"

    echo "installing nixos generations..."
    addAllEntries "$default" "$fwtarget" "$numGenerations"
fi

if [ -n "$boottarget" ]; then
    echo "'-b $boottarget' isn't used when loading the kernel directly with \`kernel\`: "\
         "kernels are copied directly to <firmware-dir>"
    exit 0
fi

echo "generational bootloader installed"
