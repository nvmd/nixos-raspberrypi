# shellcheck shell=bash
# Shared by Raspberry Pi bootloader builders that materialize initrd secrets.

loadInitrdSecretsScript() {
    local generationPath="$1"
    local bootspec="$generationPath/boot.json"

    if ! [ -e "$bootspec" ]; then
        return 0
    fi

    jq -r '."org.nixos.bootspec.v1".initrdSecrets // empty' "$bootspec"
}

initrdSecretsIdentity() {
    local generationPath="$1"
    local initrdSecrets
    local generationSystem

    initrdSecrets="$(loadInitrdSecretsScript "$generationPath")"
    generationSystem="$(readlink -f "$generationPath")"

    # Include both the resolved system closure and the appender. Generations
    # may share the same store initrd while requiring different secret
    # payloads, while aliases of the same system (for example, "default" and
    # its numbered profile generation) can safely share one composite.
    result="$({
        printf '%s\0' "$generationSystem"
        printf '%s\0' "$initrdSecrets"
    } | sha256sum | cut -d ' ' -f 1)"
}

materializeInitrdSecrets() {
    local generationPath="$1"
    local initrdSource="$2"
    local initrdPath="$3"

    if ! [ -e "$initrdSource" ]; then
        echo "initrd source does not exist: $initrdSource" >&2
        return 1
    fi

    local initrdSecrets
    initrdSecrets="$(loadInitrdSecretsScript "$generationPath")"

    local initrdDir
    local tmpPath
    initrdDir="$(dirname "$initrdPath")"
    tmpPath="$(mktemp "$initrdDir/.initrd.tmp.XXXXXX")"

    # Never use an existing boot-partition copy as input: it may already have
    # a secret archive appended by an earlier activation.
    if ! cp -- "$initrdSource" "$tmpPath"; then
        rm -f -- "$tmpPath"
        return 1
    fi

    if [ -n "$initrdSecrets" ] && ! "$initrdSecrets" "$tmpPath"; then
        rm -f -- "$tmpPath"
        return 1
    fi

    # The temporary file lives beside its destination, so this is an atomic
    # publication on every supported boot filesystem.
    if ! mv -f -- "$tmpPath" "$initrdPath"; then
        rm -f -- "$tmpPath"
        return 1
    fi
}

reportInitrdSecretsFailure() {
    local generationName="$1"

    if [ "$generationName" = "default" ]; then
        echo "failed to create initrd secrets!" >&2
        return
    fi

    echo "warning: failed to create initrd secrets for \"$generationName\", an older generation" >&2
    echo "note: this is normal after having removed or renamed a file in \`boot.initrd.secrets\`" >&2
}
