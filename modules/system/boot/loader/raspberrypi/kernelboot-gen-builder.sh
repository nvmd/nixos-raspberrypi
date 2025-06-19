#! @bash@/bin/sh -e

shopt -s nullglob

export PATH=/empty:@path@

copyForced() {
    local src="$1"
    local dst="$2"
    cp $src $dst.tmp
    mv $dst.tmp $dst
}

# Copy generation's kernel, initrd, cmdline to `kernelsDir`.
addEntry() {
    local generationPath="$1"
    local generationName="$2"
    local genDir="$3"

    if ! test -e $generationPath/kernel -a -e $generationPath/initrd; then
        return
    fi

    echo -n "kernel..."

    local kernel=$(readlink -f $generationPath/kernel)
    local initrd=$(readlink -f $generationPath/initrd)

    echo $(readlink -f $generationPath) > $genDir/system-link
    echo $(readlink -f $generationPath/init) > $genDir/init-link
    echo $initrd > $genDir/initrd-link
    echo $kernel > $genDir/kernel-link

    copyForced $kernel $genDir/kernel.img
    copyForced $initrd $genDir/initrd
    # cp "$(readlink -f "$generationPath/init")" $genDir/nixos-init
    echo "`cat $generationPath/kernel-params` init=$generationPath/init" > $genDir/cmdline.txt

    echo -n "device tree..."

    @installDeviceTree@ -c $generationPath -d $genDir

    echo
}

echo "$0: $@"
addEntry $@
echo "boot files installed for nixos generation '$2'"
