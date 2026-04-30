# shellcheck shell=bash
# Shared by Raspberry Pi bootloader builders that materialize initrd secrets.

declare -gA initrdSecretsAppended

loadInitrdSecretsScript() {
    local generationPath="$1"
    local bootspec="$generationPath/boot.json"

    if ! [ -e "$bootspec" ]; then
        return 0
    fi

    jq -r '."org.nixos.bootspec.v1".initrdSecrets // empty' "$bootspec"
}

appendInitrdSecrets() {
    local generationPath="$1"
    local initrdPath="$2"
    local generationName="$3"

    if ! [ -e "$initrdPath" ] || [ "${initrdSecretsAppended[$initrdPath]:-}" = 1 ]; then
        return 0
    fi

    local initrdSecrets
    initrdSecrets="$(loadInitrdSecretsScript "$generationPath")"

    if [ -z "$initrdSecrets" ]; then
        initrdSecretsAppended["$initrdPath"]=1
        return 0
    fi

    local initrdDir
    local tmpPath
    initrdDir="$(dirname "$initrdPath")"
    tmpPath="$(mktemp "$initrdDir/.initrd.tmp.XXXXXX")"

    cp "$initrdPath" "$tmpPath"
    if "$initrdSecrets" "$tmpPath"; then
        mv "$tmpPath" "$initrdPath"
        initrdSecretsAppended["$initrdPath"]=1
        return 0
    fi

    rm -f "$tmpPath"

    if [ "$generationName" = "default" ]; then
        echo "failed to create initrd secrets!" >&2
        exit 1
    fi

    echo "warning: failed to create initrd secrets for \"$generationName\", an older generation" >&2
    echo "note: this is normal after having removed or renamed a file in \`boot.initrd.secrets\`" >&2
}
