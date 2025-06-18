#! @bash@/bin/sh -e

shopt -s nullglob

export PATH=/empty:@path@

# used to track copied files to decide which are obsolete
# and need to be removed
declare -A filesCopied

# Convert a path to a file in the Nix store such as
# /nix/store/<hash>-<name>/file to <hash>-<name>-<file>.
cleanName() {
    local path="$1"
    echo "$path" | sed 's|^/nix/store/||' | sed 's|/|-|g'
}

# Copy a file from the Nix store to `kernelsDir`.
copyToKernelsDir() {
    local src="$1"
    local kernelsDir="$2"

    local dst="$kernelsDir/$(cleanName $src)"
    # Don't copy the file if $dst already exists.  This means that we
    # have to create $dst atomically to prevent partially copied
    # kernels or initrd if this script is ever interrupted.
    if ! test -e $dst; then
        local dstTmp=$dst.tmp.$$
        cp $src $dstTmp
        mv $dstTmp $dst
    fi
    filesCopied[$dst]=1
    result=$dst
}

copyForced() {
    local src="$1"
    local dst="$2"
    cp $src $dst.tmp
    mv $dst.tmp $dst
}

# Copy generation's kernel and initrd to `kernelsDir`.
# Default generation's are also copied to `outdir`
addEntry() {
    local generationPath="$1"
    local generationName="$2"
    local outdir="$3"
    local kernelsDir="$4"

    if ! test -e $generationPath/kernel -a -e $generationPath/initrd; then
        return
    fi

    local kernel=$(readlink -f $generationPath/kernel)
    local initrd=$(readlink -f $generationPath/initrd)

    if test "1" = "@copyKernels@"; then
        copyToKernelsDir $kernel $kernelsDir; kernel=$result
        copyToKernelsDir $initrd $kernelsDir; initrd=$result
    fi

    echo $(readlink -f $generationPath) > $kernelsDir/$generationName-system
    echo $(readlink -f $generationPath/init) > $kernelsDir/$generationName-init
    cp $generationPath/kernel-params $kernelsDir/$generationName-cmdline.txt
    echo $initrd > $kernelsDir/$generationName-initrd
    echo $kernel > $kernelsDir/$generationName-kernel

    if test "$generationName" = "default"; then
      copyForced $kernel $outdir/kernel.img
      copyForced $initrd $outdir/initrd

      cp "$(readlink -f "$generationPath/init")" $outdir/nixos-init
      echo "`cat $generationPath/kernel-params` init=$generationPath/init" >$outdir/cmdline.txt
    fi
}

removeObsolete() {
    local path="$1"

    # Remove obsolete files from $path and $path/old.
    for fn in $path/*linux* $path/*initrd-initrd*; do
        if ! test "${filesCopied[$fn]}" = 1; then
            rm -vf -- "$fn"
        fi
    done
}

addAllEntries() {
    local defaultGenerationPath="$1"
    local outdir="$2"

    local kernelsDir="$outdir/nixos-kernels"
    mkdir -p $kernelsDir || true

    # Add default generation
    addEntry $defaultGenerationPath default $outdir $kernelsDir

    # Add all generations of the system profile to the menu, in reverse
    # (most recent to least recent) order.
    for generation in $(
        (cd /nix/var/nix/profiles && ls -d system-*-link) \
        | sed 's/system-\([0-9]\+\)-link/\1/' \
        | sort -n -r); do
        link=/nix/var/nix/profiles/system-$generation-link
        addEntry $link $generation $outdir $kernelsDir
    done

    removeObsolete $kernelsDir
}

usage() {
    echo "usage: $0 -c <path-to-default-configuration> [-d <boot-dir>]" >&2
    exit 1
}


default=                # Default configuration

echo "kernelboot-builder: $@"
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

if [ -n "$fwtarget" ]; then
    @firmwareBuilder@ -c $default -d $fwtarget

    echo "updating the boot generations directory..."
    addAllEntries $default $fwtarget
fi

if [ -n "$boottarget" ]; then
    echo "'-b $boottarget' isn't used when loading the kernel directly with kernelboot: \
          kernels are copied directly to <firmware-dir>"
fi

echo "kernelboot bootloader installed"
