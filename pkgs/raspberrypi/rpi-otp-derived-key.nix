{
  lib,
  writeShellApplication,
  age,
  coreutils,
  openssl,
  xxd,
  raspberrypi-utils,
  rpi-otp-private-key,
}:

writeShellApplication {
  name = "rpi-otp-derived-key";

  passthru.rpiFwCryptoPackage = raspberrypi-utils;

  runtimeInputs = [
    age
    coreutils
    openssl
    xxd
    raspberrypi-utils
    rpi-otp-private-key
  ];

  text = ''
        set -euo pipefail

        die() {
          echo "rpi-otp-derived-key: $*" >&2
          exit 1
        }

        usage() {
          cat <<'EOF'
    Usage: rpi-otp-derived-key --scheme SCHEME \
             (--salt STRING | --salt-hex HEX | --salt-file PATH) [options]

    Derive deterministic key material from a Raspberry Pi OTP private key.
    SCHEME is mandatory so package upgrades cannot silently rotate existing keys.

    This outputs raw derived key material. If you need a private key for a
    specific algorithm, convert or validate the result for that algorithm
    separately.

    Options:
      --format FORMAT    Output format. Defaults to hex.
      --scheme SCHEME    Versioned derivation scheme. Required.
      --salt STRING      Salt as a UTF-8 string.
      --salt-hex HEX     Salt as hexadecimal bytes.
      --salt-file PATH   Salt bytes read from a file.
      --length BYTES     Number of bytes to derive. Defaults to 32 for hex/binary.
      --binary           Shorthand for --format binary.
      --key-id ID        Firmware crypto OTP key slot. Defaults to 1.
                        Only valid with firmware-hmac-v1.
      --otp-words WORDS  Legacy OTP word count. Defaults to 8.
                        Only valid with legacy-hkdf-v1.
      --otp-offset WORD  Legacy OTP word offset. Defaults to 0.
                        Only valid with legacy-hkdf-v1.
      --list-formats     Show supported output formats.
      --list-schemes     Show supported derivation schemes.
      -h, --help         Show this help.

    Supported SCHEME values:
      firmware-hmac-v1  Firmware-side HMAC-SHA256 counter KDF. Recommended for
                        new enrollment; the raw OTP key stays out of userspace.
      legacy-hkdf-v1    Original HKDF-SHA256 construction. Migration only; it
                        reads the raw OTP key and reproduces existing outputs.

    Supported FORMAT values:
      hex               Lowercase hexadecimal output.
      binary            Raw binary output.
      ed25519           Unencrypted PKCS#8 PEM-encoded Ed25519 private key.
      age               Native age identity text with a public-key comment.

    Notes:
      - The OTP value must be programmed and non-zero.
      - The schemes intentionally produce different outputs. To migrate an
        existing encrypted volume, first enroll a firmware-hmac-v1 recovery key
        while the legacy key can still unlock it.
      - FORMAT affects built-in domain separation for algorithm-specific outputs,
        so `ed25519` and `age` derive different outputs even with the same salt.
      - Salt is usually public. If you want to keep it out of the process list,
        prefer --salt-file.
      - `hex` and `binary` are two representations of the same generic derived
        key material.
      - OpenSSH private-key output is not implemented in this version.
    EOF
        }

        list_schemes() {
          cat <<'EOF'
    firmware-hmac-v1
    legacy-hkdf-v1
    EOF
        }

        list_formats() {
          cat <<'EOF'
    hex
    binary
    ed25519
    age
    EOF
        }

        is_uint() {
          [[ "$1" =~ ^[0-9]+$ ]]
        }

        is_hex() {
          [[ "$1" =~ ^[0-9A-Fa-f]+$ ]] && (( ''${#1} % 2 == 0 ))
        }

        utf8_to_hex() {
          printf '%s' "$1" | xxd -p -c 999999 | tr -d '\n'
        }

        file_to_hex() {
          xxd -p -c 999999 "$1" | tr -d '\n'
        }

        age_identity_from_hex() {
          local secret_hex="$1"
          local charset="qpzry9x8gf2tvdw0s3jn54khce6mua7l"
          local hrp="age-secret-key-"
          local -a hrp_values=(
            3 3 3 1 3 3 3 3 3 3 1 3 3 3 1
            0
            1 7 5 13 19 5 3 18 5 20 13 11 5 25 13
          )
          local -a generators=(0x3b6a57b2 0x26508e6d 0x1ea119fa 0x3d4233dd 0x2a1462b3)
          local -a values=()
          local -a checksum_input=()
          local acc=0
          local bits=0
          local max_acc=$(((1 << 12) - 1))
          local chk=1
          local i byte value top mod out

          for ((i = 0; i < ''${#secret_hex}; i += 2)); do
            byte=$((16#''${secret_hex:i:2}))
            acc=$((((acc << 8) | byte) & max_acc))
            bits=$((bits + 8))

            while ((bits >= 5)); do
              bits=$((bits - 5))
              values+=($(((acc >> bits) & 31)))
            done
          done

          if ((bits > 0)); then
            values+=($(((acc << (5 - bits)) & 31)))
          fi

          checksum_input=(
            "''${hrp_values[@]}"
            "''${values[@]}"
            0 0 0 0 0 0
          )

          for value in "''${checksum_input[@]}"; do
            top=$((chk >> 25))
            chk=$((((chk & 0x1ffffff) << 5) ^ value))

            for i in 0 1 2 3 4; do
              if (( (top >> i) & 1 )); then
                chk=$((chk ^ generators[i]))
              fi
            done
          done

          mod=$((chk ^ 1))
          out="$hrp"
          out+="1"

          for value in "''${values[@]}"; do
            out+="''${charset:value:1}"
          done

          for ((i = 0; i < 6; i++)); do
            value=$(((mod >> (5 * (5 - i))) & 31))
            out+="''${charset:value:1}"
          done

          printf '%s\n' "''${out^^}"
        }

        emit_ed25519_pem() {
          local seed_hex="$1"
          printf '302e020100300506032b657004220420%s' "$seed_hex" \
            | xxd -r -p \
            | openssl pkey -inform DER -outform PEM
        }

        emit_age_identity() {
          local secret_hex="$1"
          local identity recipient

          identity="$(age_identity_from_hex "$secret_hex")"
          recipient="$(printf '%s\n' "$identity" | age-keygen -y)"

          printf '# public key: %s\n' "$recipient"
          printf '%s\n' "$identity"
        }

        write_u32_be() {
          local value="$1"

          printf '%08x' "$value" | xxd -r -p
        }

        firmware_hmac_kdf() {
          local output_file="$1"
          local profile="$2"
          local length="$3"
          local salt_hex="$4"
          local key_id="$5"
          local label="rpi-otp-derived-key:firmware-hmac-v1:$profile"
          local salt_file="$work_dir/salt"
          local salt_digest_file="$work_dir/salt.sha256"
          local message_file="$work_dir/message"
          local block_file="$work_dir/block"
          local material_file="$work_dir/material"
          local output_bits=$((length * 8))
          local blocks=$(((length + 31) / 32))
          local block block_size num_keys num_keys_output

          if ! num_keys_output="$(rpi-fw-crypto get-num-otp-keys)"; then
            die "could not query firmware crypto OTP key slots"
          fi
          num_keys="''${num_keys_output##*: }"
          is_uint "$num_keys" || die \
            "unexpected response from rpi-fw-crypto get-num-otp-keys: $num_keys_output"
          (( key_id < num_keys )) || die \
            "OTP key slot $key_id is outside the firmware-reported range 0-$((num_keys - 1))"

          # firmware-hmac-v1 is the HMAC-SHA256 counter KDF from NIST SP
          # 800-108: [i]_32 || Label || 0x00 || Context || [L]_32. Hashing the
          # public salt makes Context fixed-size and keeps every firmware
          # request well below its 2 KiB message limit.
          printf '%s' "$salt_hex" | xxd -r -p > "$salt_file"
          openssl dgst -sha256 -binary "$salt_file" > "$salt_digest_file"
          : > "$material_file"

          for ((block = 1; block <= blocks; block++)); do
            {
              write_u32_be "$block"
              printf '%s\0' "$label"
              cat "$salt_digest_file"
              write_u32_be "$output_bits"
            } > "$message_file"

            if ! rpi-fw-crypto hmac \
              --in "$message_file" \
              --key-id "$key_id" \
              --out "$block_file"
            then
              die "firmware HMAC failed for OTP key slot $key_id"
            fi

            block_size="$(wc -c < "$block_file")"
            (( block_size == 32 )) || die \
              "rpi-fw-crypto returned $block_size bytes; expected 32"
            cat "$block_file" >> "$material_file"
          done

          head -c "$length" "$material_file" > "$output_file"
        }

        legacy_hkdf() {
          local output_file="$1"
          local profile="$2"
          local length="$3"
          local salt_hex="$4"
          local otp_words="$5"
          local otp_offset="$6"
          local info_hex otp_hex expected_hex_length

          info_hex="$(utf8_to_hex "rpi-otp-derived-key:$profile")"
          otp_hex="$(rpi-otp-private-key -l "$otp_words" -o "$otp_offset" | tr -d '[:space:]')"
          is_hex "$otp_hex" || die "rpi-otp-private-key did not return hexadecimal key material"

          expected_hex_length=$((otp_words * 8))
          (( ''${#otp_hex} == expected_hex_length )) || die \
            "expected $expected_hex_length hex digits from rpi-otp-private-key, got ''${#otp_hex}"

          [[ ! "$otp_hex" =~ ^0+$ ]] || die "OTP private key is not programmed (all zeros)"

          # This backend exists solely to reproduce keys enrolled by versions
          # predating firmware-hmac-v1. It necessarily reads the raw OTP key.
          openssl kdf \
            -keylen "$length" \
            -kdfopt digest:SHA256 \
            -kdfopt "hexkey:$otp_hex" \
            -kdfopt "hexsalt:$salt_hex" \
            -kdfopt "hexinfo:$info_hex" \
            -binary \
            HKDF > "$output_file"
        }

        work_dir=""
        cleanup() {
          if [[ -n "$work_dir" ]]; then
            rm -rf -- "$work_dir"
          fi
        }
        trap cleanup EXIT

        salt_hex=""
        user_length=""
        format="hex"
        scheme=""
        key_id=1
        key_id_set=0
        otp_words=8
        otp_words_set=0
        otp_offset=0
        otp_offset_set=0

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --format)
              [[ $# -ge 2 ]] || die "--format requires an argument"
              format="''${2,,}"
              shift 2
              ;;
            --scheme)
              [[ $# -ge 2 ]] || die "--scheme requires an argument"
              [[ -z "$scheme" ]] || die "--scheme specified more than once"
              scheme="''${2,,}"
              shift 2
              ;;
            --salt)
              [[ $# -ge 2 ]] || die "--salt requires an argument"
              [[ -z "$salt_hex" ]] || die "salt specified more than once"
              salt_hex="$(utf8_to_hex "$2")"
              shift 2
              ;;
            --salt-hex)
              [[ $# -ge 2 ]] || die "--salt-hex requires an argument"
              [[ -z "$salt_hex" ]] || die "salt specified more than once"
              is_hex "$2" || die "--salt-hex expects an even-length hexadecimal string"
              salt_hex="''${2,,}"
              shift 2
              ;;
            --salt-file)
              [[ $# -ge 2 ]] || die "--salt-file requires an argument"
              [[ -z "$salt_hex" ]] || die "salt specified more than once"
              [[ -r "$2" ]] || die "cannot read salt file: $2"
              salt_hex="$(file_to_hex "$2")"
              shift 2
              ;;
            --length)
              [[ $# -ge 2 ]] || die "--length requires an argument"
              is_uint "$2" || die "--length expects a positive integer"
              (( $2 > 0 )) || die "--length expects a positive integer"
              user_length="$2"
              shift 2
              ;;
            --binary)
              [[ "$format" == "hex" ]] || die "--binary conflicts with --format $format"
              format="binary"
              shift
              ;;
            --key-id)
              [[ $# -ge 2 ]] || die "--key-id requires an argument"
              is_uint "$2" || die "--key-id expects a non-negative integer"
              key_id="$2"
              key_id_set=1
              shift 2
              ;;
            --otp-words)
              [[ $# -ge 2 ]] || die "--otp-words requires an argument"
              is_uint "$2" || die "--otp-words expects a positive integer"
              (( $2 > 0 )) || die "--otp-words expects a positive integer"
              otp_words="$2"
              otp_words_set=1
              shift 2
              ;;
            --otp-offset)
              [[ $# -ge 2 ]] || die "--otp-offset requires an argument"
              is_uint "$2" || die "--otp-offset expects a non-negative integer"
              otp_offset="$2"
              otp_offset_set=1
              shift 2
              ;;
            --list-formats)
              list_formats
              exit 0
              ;;
            --list-schemes)
              list_schemes
              exit 0
              ;;
            -h|--help)
              usage
              exit 0
              ;;
            --)
              shift
              break
              ;;
            *)
              die "unknown argument: $1"
              ;;
          esac
        done

        (( $# == 0 )) || die "unexpected positional arguments: $*"
        [[ -n "$salt_hex" ]] || die "one of --salt, --salt-hex, or --salt-file is required"
        [[ -n "$salt_hex" ]] || die "salt must not be empty"

        case "$format" in
          hex|binary)
            profile="raw"
            length="''${user_length:-32}"
            ;;
          ed25519)
            [[ -z "$user_length" ]] || die "--length is only supported with --format hex or --format binary"
            profile="ed25519"
            length=32
            ;;
          age)
            [[ -z "$user_length" ]] || die "--length is only supported with --format hex or --format binary"
            profile="age"
            length=32
            ;;
          *)
            die "unsupported --format: $format"
            ;;
        esac

        [[ -n "$scheme" ]] || die \
          "--scheme is required; choose firmware-hmac-v1 for new enrollment or legacy-hkdf-v1 for existing keys"

        case "$scheme" in
          firmware-hmac-v1)
            (( otp_words_set == 0 )) || die \
              "--otp-words is only valid with --scheme legacy-hkdf-v1"
            (( otp_offset_set == 0 )) || die \
              "--otp-offset is only valid with --scheme legacy-hkdf-v1"
            (( length <= 8192 )) || die \
              "firmware-hmac-v1 supports at most 8192 output bytes"
            ;;
          legacy-hkdf-v1)
            (( key_id_set == 0 )) || die \
              "--key-id is only valid with --scheme firmware-hmac-v1"
            ;;
          *)
            die "unsupported --scheme: $scheme"
            ;;
        esac

        umask 077
        work_dir="$(mktemp -d)"
        derived_file="$work_dir/derived"

        case "$scheme" in
          firmware-hmac-v1)
            firmware_hmac_kdf "$derived_file" "$profile" "$length" "$salt_hex" "$key_id"
            ;;
          legacy-hkdf-v1)
            legacy_hkdf "$derived_file" "$profile" "$length" "$salt_hex" "$otp_words" "$otp_offset"
            ;;
        esac

        case "$format" in
          hex)
            file_to_hex "$derived_file"
            printf '\n'
            ;;
          binary)
            cat "$derived_file"
            ;;
          ed25519)
            derived_hex="$(file_to_hex "$derived_file")"
            emit_ed25519_pem "$derived_hex"
            ;;
          age)
            derived_hex="$(file_to_hex "$derived_file")"
            emit_age_identity "$derived_hex"
            ;;
        esac
  '';

  meta = with lib; {
    description = "Derive deterministic keys through the Raspberry Pi firmware cryptography service";
    homepage = "https://github.com/nvmd/nixos-raspberrypi";
    license = licenses.mit;
    mainProgram = "rpi-otp-derived-key";
    platforms = [
      "armv6l-linux"
      "armv7l-linux"
      "aarch64-linux"
    ];
  };
}
