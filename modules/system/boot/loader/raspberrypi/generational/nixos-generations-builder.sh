#! @bash@/bin/sh -e

# shellcheck disable=SC3043,SC3044,SC3054

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

    # Move $src as "new" $dst
    mv "$src" "$dst"

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
    # Don't copy the files if $dst already exists, unless it's the default
    # configuration.
    # This means that we have to create $dst atomically to prevent partially
    # copied generations if this script is ever interrupted.
    #
    # For "default" generation: make backup and then replace with the new
    # "default", minimizing the time when where isn't any "default" generation
    # directory
    if ! [ -e $dst ] || [ "$generationName" = "default" ]; then
        local dstTmp="$dst.tmp.$$"
        mkdir -p "$dstTmp" || true

        @nixosGenBuilder@ -c "$generationPath" -n "$generationName" -d "$dstTmp"

        # Move new generation on its place, backing up the previous version
        # if it exists
        # This may only happen when "$generationName" = "default"
        moveWBackup "$dstTmp" "$dst"
    fi

    activeGenerations["$generationName"]=1
}

removeObsoleteGenerations() {
    local path="$1"

    echo "removing obsolete generations in $path..."
    for gen in $path/*; do
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
                ls /nix/var/nix/profiles/system-$generation-link/specialisation \
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

echo "$0: $@"
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
