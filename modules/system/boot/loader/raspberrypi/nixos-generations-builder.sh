#! @bash@/bin/sh -e

shopt -s nullglob

export PATH=/empty:@path@

# used to track copied generations to decide which are obsolete
# and need to be removed
declare -A activeGenerations

# Copy generation's kernel, initrd, cmdline to `kernelsDir`.
addEntry() {
    local generationPath="$1"
    local generationName="$2"
    local kernelsDir="$3"

    local dst="$kernelsDir/$generationName"

    # Don't copy the files if $dst already exists.  This means that we
    # have to create $dst atomically to prevent partially copied
    # generations if this script is ever interrupted.
    if ! test -e $dst; then
        local dstTmp=$dst.tmp.$$
        mkdir -p $dstTmp || true

        @nixosGenBuilder@ $generationPath $generationName $dstTmp

        mv $dstTmp $dst
    fi

    activeGenerations[$generationName]=1
}

removeObsoleteGenerations() {
    local path="$1"

    echo "removing obsolete generations in $path..."
    for gen in $path/*; do
        if ! test "${activeGenerations["$(basename $gen)"]}" = 1; then
            echo "* $gen is obsolete"
            rm -vrf "$gen"
        fi
    done
}

addAllEntries() {
    local defaultGenerationPath="$1"
    local outdir="$2"
    local numGenerations="$3"

    local kernelsDir="$outdir/@nixosGenerationsDir@/"
    mkdir -p $kernelsDir || true

    # Add default generation
    addEntry $defaultGenerationPath default $kernelsDir

    if [ "$numGenerations" -gt 0 ]; then
        # Add up to $numGenerations generations of the system profile, in reverse
        # (most recent to least recent) order.
        for generation in $(
            (cd /nix/var/nix/profiles && ls -d system-*-link) \
            | sed 's/system-\([0-9]\+\)-link/\1/' \
            | sort -n -r \
            | head -n $numGenerations); do
            link=/nix/var/nix/profiles/system-$generation-link
            addEntry $link "${generation}-default" $kernelsDir
            for specialisation in $(
                ls /nix/var/nix/profiles/system-$generation-link/specialisation \
                | sort -n -r); do
                link=/nix/var/nix/profiles/system-$generation-link/specialisation/$specialisation
                addEntry $link "${generation}-${specialisation}" $kernelsDir
            done
        done
    fi

    removeObsoleteGenerations $kernelsDir
}

usage() {
    echo "usage: $0 -c <path-to-default-configuration> [-d <boot-dir>] [-g <num-generations>]" >&2
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
    @installFirmwareBuilder@ -c $default -d $fwtarget

    echo "updating nixos generations..."
    addAllEntries $default $fwtarget $numGenerations
fi

if [ -n "$boottarget" ]; then
    echo "'-b $boottarget' isn't used when loading the kernel directly with kernelboot: "\
         "kernels are copied directly to <firmware-dir>"
    exit 0
fi

echo "kernelboot bootloader installed"
