{ pkgs }:

let
  appendA = pkgs.writeShellScript "append-initrd-secret-a" ''
    printf 'secret-a\n' >> "$1"
  '';
  appendB = pkgs.writeShellScript "append-initrd-secret-b" ''
    printf 'secret-b\n' >> "$1"
  '';
  appendDynamic = pkgs.writeShellScript "append-initrd-secret-dynamic" ''
    printf '%s\n' "$TEST_SECRET" >> "$1"
  '';
  appendFailure = pkgs.writeShellScript "append-initrd-secret-failure" ''
    printf 'partial-secret\n' >> "$1"
    exit 1
  '';
  fakeFirmwareBuilder = pkgs.writeShellScript "fake-firmware-builder" ''
    exit 0
  '';
  fakeExtlinuxBuilder = pkgs.writeShellApplication {
    name = "fake-extlinux-builder";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
    ];
    text = ''
      default=
      target=
      while getopts "c:d:" opt; do
        case "$opt" in
          c) default="$OPTARG" ;;
          d) target="$OPTARG" ;;
          *) exit 1 ;;
        esac
      done

      initrdSource="$(readlink -f "$default/initrd")"
      initrdName="$(printf '%s\n' "$initrdSource" | sed 's|^/nix/store/||; s|/|-|g')"
      mkdir -p "$target/nixos" "$target/extlinux"
      cp "$initrdSource" "$target/nixos/$initrdName"
      printf '%s\n' \
        'DEFAULT nixos-default' \
        'LABEL nixos-default' \
        "  INITRD ../nixos/$initrdName" \
        > "$target/extlinux/extlinux.conf"
    '';
  };
  fakeUboot = pkgs.runCommand "fake-uboot" { } ''
    mkdir -p "$out"
  '';
  testUbootBuilder = import ../modules/system/boot/loader/raspberrypi/uboot-builder.nix {
    inherit pkgs;
    ubootPackage = fakeUboot;
    ubootBinName = "u-boot.bin";
    extlinuxConfBuilder = "${fakeExtlinuxBuilder}/bin/fake-extlinux-builder";
    firmwareBuilder = fakeFirmwareBuilder;
  };
in
pkgs.runCommand "raspberrypi-initrd-secrets"
  {
    nativeBuildInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
  }
  ''
    set -euo pipefail

    # shellcheck source=modules/system/boot/loader/raspberrypi/initrd-secrets.sh
    source ${../modules/system/boot/loader/raspberrypi/initrd-secrets.sh}

    makeBootspec() {
      local generation="$1"
      local appender="$2"

      mkdir -p "$generation"
      jq -n --arg appender "$appender" \
        '{"org.nixos.bootspec.v1": {"initrdSecrets": $appender}}' \
        > "$generation/boot.json"
    }

    pristine="$PWD/pristine-initrd"
    printf 'pristine-initrd\n' > "$pristine"

    makeBootspec "$PWD/generation-a" ${appendA}
    makeBootspec "$PWD/generation-b" ${appendB}

    # Two generations sharing the same store initrd must never share the
    # payload selected during this builder invocation.
    shared="$PWD/shared-materialized-initrd"
    materializeInitrdSecrets "$PWD/generation-a" "$pristine" "$shared"
    printf 'pristine-initrd\nsecret-a\n' > "$PWD/expected-a"
    cmp "$PWD/expected-a" "$shared"

    materializeInitrdSecrets "$PWD/generation-b" "$pristine" "$shared"
    printf 'pristine-initrd\nsecret-b\n' > "$PWD/expected-b"
    cmp "$PWD/expected-b" "$shared"

    # Repeated activation starts from the pristine initrd and is byte-for-byte
    # stable instead of appending a second payload.
    materializeInitrdSecrets "$PWD/generation-b" "$pristine" "$shared"
    cmp "$PWD/expected-b" "$shared"

    # A rotated runtime value replaces the previous payload rather than
    # retaining it in the boot-partition copy.
    makeBootspec "$PWD/generation-dynamic" ${appendDynamic}
    export TEST_SECRET=old-secret
    materializeInitrdSecrets "$PWD/generation-dynamic" "$pristine" "$shared"
    export TEST_SECRET=new-secret
    materializeInitrdSecrets "$PWD/generation-dynamic" "$pristine" "$shared"
    printf 'pristine-initrd\nnew-secret\n' > "$PWD/expected-new"
    cmp "$PWD/expected-new" "$shared"

    # Failed appenders must leave an already-published destination untouched.
    makeBootspec "$PWD/generation-failure" ${appendFailure}
    cp "$PWD/expected-new" "$shared"
    if materializeInitrdSecrets "$PWD/generation-failure" "$pristine" "$shared"; then
      echo "failing initrd appender unexpectedly succeeded" >&2
      exit 1
    fi
    cmp "$PWD/expected-new" "$shared"

    # Payload names include the resolved system and appender identity, even
    # when the immutable source initrd is shared. Menu aliases for the same
    # system reuse a composite instead of consuming duplicate boot storage.
    initrdSecretsIdentity "$PWD/generation-a"
    identityA="$result"
    initrdSecretsIdentity "$PWD/generation-a"
    identityAlias="$result"
    initrdSecretsIdentity "$PWD/generation-b"
    identityAppender="$result"
    test "$identityA" = "$identityAlias"
    test "$identityA" != "$identityAppender"

    # A generation without secrets also overwrites stale output from the
    # pristine source.
    mkdir -p "$PWD/generation-empty"
    printf 'stale-payload\n' > "$shared"
    materializeInitrdSecrets "$PWD/generation-empty" "$pristine" "$shared"
    cmp "$pristine" "$shared"

    # Exercise the U-Boot wrapper itself. It stages extlinux, points the entry
    # at a generation-specific composite, and refreshes that composite from the
    # pristine source on each invocation.
    ubootGeneration="$PWD/uboot-generation"
    ubootTarget="$PWD/uboot-target"
    mkdir -p "$ubootGeneration" "$ubootTarget"
    ln -s "$pristine" "$ubootGeneration/initrd"
    makeBootspec "$ubootGeneration" ${appendDynamic}

    export TEST_SECRET=uboot-old
    ${testUbootBuilder} -b "$ubootTarget" -c "$ubootGeneration"
    composite="$(sed -n 's|^  INITRD ../nixos/||p' "$ubootTarget/extlinux/extlinux.conf")"
    pristineName="$(printf '%s\n' "$(readlink -f "$pristine")" | sed 's|^/nix/store/||; s|/|-|g')"
    test -n "$composite"
    test ! -e "$ubootTarget/nixos/$pristineName"
    printf 'pristine-initrd\nuboot-old\n' > "$PWD/expected-uboot-old"
    cmp "$PWD/expected-uboot-old" "$ubootTarget/nixos/$composite"

    export TEST_SECRET=uboot-new
    ${testUbootBuilder} -b "$ubootTarget" -c "$ubootGeneration"
    printf 'pristine-initrd\nuboot-new\n' > "$PWD/expected-uboot-new"
    cmp "$PWD/expected-uboot-new" "$ubootTarget/nixos/$composite"

    # A failed default-generation append must not switch extlinux.conf or
    # replace the last known-good composite.
    cp "$ubootTarget/extlinux/extlinux.conf" "$PWD/extlinux-before-failure"
    cp "$ubootTarget/nixos/$composite" "$PWD/composite-before-failure"
    makeBootspec "$ubootGeneration" ${appendFailure}
    if ${testUbootBuilder} -b "$ubootTarget" -c "$ubootGeneration"; then
      echo "U-Boot builder unexpectedly published a failed appender" >&2
      exit 1
    fi
    cmp "$PWD/extlinux-before-failure" "$ubootTarget/extlinux/extlinux.conf"
    cmp "$PWD/composite-before-failure" "$ubootTarget/nixos/$composite"
    test -z "$(find "$ubootTarget" -maxdepth 1 -name '.raspberrypi-extlinux.tmp.*' -print -quit)"

    touch "$out"
  ''
