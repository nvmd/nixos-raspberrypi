#! @bash@/bin/sh -e

# shellcheck shell=bash disable=SC2012,SC2239

shopt -s nullglob

export PATH=/empty:@path@

usage() {
    echo "usage: $0 -f <firmware-dir> -b <boot-dir> -c <path-to-default-configuration>" >&2
    exit 1
}

default=               # Default configuration, needed for extlinux
boottarget=
fwtarget=

# shellcheck source=modules/system/boot/loader/raspberrypi/initrd-secrets.sh
. @initrdSecrets@

echo "uboot-builder: $*"
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
    local dstTmp="$dst.tmp.$$"

    cp "$src" "$dstTmp"
    mv "$dstTmp" "$dst"
}

cleanName() {
    local path="$1"
    echo "$path" | sed 's|^/nix/store/||' | sed 's|/|-|g'
}

declare -A stagedInitrdSources

extlinuxHasEntry() {
    local configPath="$1"
    local generationName="$2"

    grep -Fqx "LABEL nixos-$generationName" "$configPath"
}

rewriteExtlinuxInitrd() {
    local configPath="$1"
    local generationName="$2"
    local initrdName="$3"
    local tmpPath
    tmpPath="$(mktemp "$(dirname "$configPath")/.extlinux.conf.tmp.XXXXXX")"

    if awk \
        -v wanted="LABEL nixos-$generationName" \
        -v replacement="  INITRD ../nixos/$initrdName" \
        '
            /^LABEL / { inEntry = ($0 == wanted) }
            inEntry && /^  INITRD / {
                print replacement
                replaced = 1
                next
            }
            { print }
            END { if (!replaced) exit 1 }
        ' "$configPath" > "$tmpPath"; then
        mv "$tmpPath" "$configPath"
        return 0
    fi

    rm -f -- "$tmpPath"
    return 1
}

removeExtlinuxEntry() {
    local configPath="$1"
    local generationName="$2"
    local tmpPath
    tmpPath="$(mktemp "$(dirname "$configPath")/.extlinux.conf.tmp.XXXXXX")"

    awk \
        -v wanted="LABEL nixos-$generationName" \
        '
            /^LABEL / {
                if ($0 == wanted) {
                    skip = 1
                    next
                }
                skip = 0
            }
            !skip { print }
        ' "$configPath" > "$tmpPath"
    mv "$tmpPath" "$configPath"
}

materializeGenerationInitrd() {
    local generationPath="$1"
    local generationName="$2"
    local target="$3"
    local configPath="$4"

    if ! [ -e "$generationPath/initrd" ]; then
        return 0
    fi

    if ! extlinuxHasEntry "$configPath" "$generationName"; then
        return 0
    fi

    local initrdSecrets
    initrdSecrets="$(loadInitrdSecretsScript "$generationPath")"
    if [ -z "$initrdSecrets" ]; then
        return 0
    fi

    local initrdSource
    local initrdPath
    initrdSource="$(readlink -f "$generationPath/initrd")"
    stagedInitrdSources["$target/nixos/$(cleanName "$initrdSource")"]=1
    initrdSecretsIdentity "$generationPath"
    initrdPath="$target/nixos/$(cleanName "$initrdSource").secrets-$result"

    if ! materializeInitrdSecrets "$generationPath" "$initrdSource" "$initrdPath"; then
        reportInitrdSecretsFailure "$generationName"
        if [ "$generationName" = "default" ]; then
            return 1
        fi

        # Do not publish a menu entry without the secrets its generation
        # requires. The rest of the usable older generations remain available.
        removeExtlinuxEntry "$configPath" "$generationName"
        return 0
    fi

    rewriteExtlinuxInitrd "$configPath" "$generationName" "$(basename "$initrdPath")"
}

pruneUnreferencedInitrdSources() {
    local target="$1"
    local configPath="$target/extlinux/extlinux.conf"
    local initrdSource
    local initrdName

    # The generic extlinux builder stages each pristine initrd before this
    # wrapper creates generation-specific composites. Remove a base copy only
    # when no remaining (for example, no-secret) entry still references it.
    for initrdSource in "${!stagedInitrdSources[@]}"; do
        initrdName="$(basename "$initrdSource")"
        if ! grep -Fqx "  INITRD ../nixos/$initrdName" "$configPath"; then
            rm -f -- "$initrdSource"
        fi
    done
}

materializeAllInitrdSecrets() {
    local defaultGenerationPath="$1"
    local target="$2"
    local configPath="$target/extlinux/extlinux.conf"

    materializeGenerationInitrd "$defaultGenerationPath" default "$target" "$configPath"

    for generation in $(
        (cd /nix/var/nix/profiles && ls -d system-*-link) \
        | sed 's/system-\([0-9]\+\)-link/\1/' \
        | sort -n -r); do
        link=/nix/var/nix/profiles/system-$generation-link
        materializeGenerationInitrd "$link" "${generation}-default" "$target" "$configPath"
        for specialisation in $(
            ls "/nix/var/nix/profiles/system-$generation-link/specialisation" \
            | sort -n -r); do
            link=/nix/var/nix/profiles/system-$generation-link/specialisation/$specialisation
            materializeGenerationInitrd "$link" "${generation}-${specialisation}" "$target" "$configPath"
        done
    done

    pruneUnreferencedInitrdSources "$target"
}

publishExtlinuxTree() {
    local stage="$1"
    local target="$2"

    mkdir -p "$target/nixos" "$target/extlinux"

    # Publish every file needed by the new configuration before switching the
    # configuration itself. An interrupted run therefore leaves the previous
    # extlinux.conf and all of the files it references intact.
    declare -A activeBootFiles
    local src
    local name
    local dst
    local dstTmp
    for src in "$stage/nixos"/*; do
        name="$(basename "$src")"
        dst="$target/nixos/$name"
        activeBootFiles["$name"]=1

        if [ -d "$src" ]; then
            if ! [ -e "$dst" ]; then
                dstTmp="$dst.tmp.$$"
                cp -a "$src" "$dstTmp"
                mv "$dstTmp" "$dst"
            fi
        else
            copyForced "$src" "$dst"
        fi
    done

    copyForced "$stage/extlinux/extlinux.conf" "$target/extlinux/extlinux.conf"

    # The new configuration is live; files not referenced by it can now be
    # removed without making an interrupted update unbootable.
    local old
    for old in "$target/nixos"/*; do
        name="$(basename "$old")"
        if ! [ "${activeBootFiles[$name]:-}" = 1 ]; then
            echo "Removing no longer needed boot file: $old"
            chmod +w -- "$old"
            rm -rf -- "$old"
        fi
    done
}

if [ -n "$fwtarget" ]; then
    @firmwareBuilder@ -c "$default" -d "$fwtarget"

    echo "copying u-boot binary..."
    copyForced @uboot@/u-boot.bin "$fwtarget/@ubootBinName@"
fi

if [ -n "$boottarget" ]; then
    echo "generating extlinux configuration..."
    mkdir -p "$boottarget"
    extlinuxStage="$(mktemp -d "$boottarget/.raspberrypi-extlinux.tmp.XXXXXX")"
    cleanupExtlinuxStage() {
        if [ -n "${extlinuxStage:-}" ] && [ -e "$extlinuxStage" ]; then
            rm -rf -- "$extlinuxStage"
        fi
    }
    trap cleanupExtlinuxStage EXIT

    @extlinuxConfBuilder@ -c "$default" -d "$extlinuxStage"
    materializeAllInitrdSecrets "$default" "$extlinuxStage"
    publishExtlinuxTree "$extlinuxStage" "$boottarget"

    rm -rf -- "$extlinuxStage"
    extlinuxStage=
fi

msg=""
if [ -n "$fwtarget" ]; then
    msg="uboot"
fi
if [ -n "$boottarget" ]; then
    msg="$msg+extlinux"
fi
echo "$msg bootloader installed"
