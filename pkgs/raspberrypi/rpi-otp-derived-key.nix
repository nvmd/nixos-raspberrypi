{ lib
, writeShellApplication
, age
, coreutils
, openssl
, xxd
, rpi-otp-private-key
,
}:

writeShellApplication {
  name = "rpi-otp-derived-key";

  runtimeInputs = [
    age
    coreutils
    openssl
    xxd
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
    Usage: rpi-otp-derived-key (--salt STRING | --salt-hex HEX | --salt-file PATH) [options]

    Derive deterministic key material from the Raspberry Pi OTP private key
    using HKDF-SHA256.

    This outputs raw derived key material. If you need a private key for a
    specific algorithm, convert or validate the result for that algorithm
    separately.

    Options:
      --format FORMAT    Output format. Defaults to hex.
      --salt STRING      Salt as a UTF-8 string.
      --salt-hex HEX     Salt as hexadecimal bytes.
      --salt-file PATH   Salt bytes read from a file.
      --length BYTES     Number of bytes to derive. Defaults to 32 for hex/binary.
      --binary           Shorthand for --format binary.
      --otp-words WORDS  Number of 32-bit OTP words to read. Defaults to 8.
      --otp-offset WORD  OTP word offset to start reading from. Defaults to 0.
      --list-formats     Show supported output formats.
      -h, --help         Show this help.

    Supported FORMAT values:
      hex               Lowercase hexadecimal output.
      binary            Raw binary output.
      ed25519           Unencrypted PKCS#8 PEM-encoded Ed25519 private key.
      age               Native age identity text with a public-key comment.

    Notes:
      - The OTP value must be programmed and non-zero.
      - FORMAT affects built-in domain separation for algorithm-specific outputs,
        so `ed25519` and `age` derive different outputs even with the same salt.
      - Salt is usually public. If you want to keep it out of the process list,
        prefer --salt-file.
      - `hex` and `binary` are two representations of the same generic derived
        key material.
      - OpenSSH private-key output is not implemented in this version.
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

        canonical_hex() {
          printf '%s' "$1" | tr -d '[:space:]:' | tr '[:upper:]' '[:lower:]'
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

        salt_hex=""
        user_length=""
        format="hex"
        otp_words=8
        otp_offset=0

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --format)
              [[ $# -ge 2 ]] || die "--format requires an argument"
              format="''${2,,}"
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
            --otp-words)
              [[ $# -ge 2 ]] || die "--otp-words requires an argument"
              is_uint "$2" || die "--otp-words expects a positive integer"
              (( $2 > 0 )) || die "--otp-words expects a positive integer"
              otp_words="$2"
              shift 2
              ;;
            --otp-offset)
              [[ $# -ge 2 ]] || die "--otp-offset requires an argument"
              is_uint "$2" || die "--otp-offset expects a non-negative integer"
              otp_offset="$2"
              shift 2
              ;;
            --list-formats)
              list_formats
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

        info_hex="$(utf8_to_hex "rpi-otp-derived-key:$profile")"

        otp_hex="$(rpi-otp-private-key -l "$otp_words" -o "$otp_offset" | tr -d '[:space:]')"
        is_hex "$otp_hex" || die "rpi-otp-private-key did not return hexadecimal key material"

        expected_hex_length=$((otp_words * 8))
        (( ''${#otp_hex} == expected_hex_length )) || die \
          "expected $expected_hex_length hex digits from rpi-otp-private-key, got ''${#otp_hex}"

        [[ ! "$otp_hex" =~ ^0+$ ]] || die "OTP private key is not programmed (all zeros)"

        declare -a cmd=(
          openssl
          kdf
          -keylen "$length"
          -kdfopt digest:SHA256
          -kdfopt "hexkey:$otp_hex"
          -kdfopt "hexsalt:$salt_hex"
          -kdfopt "hexinfo:$info_hex"
        )

        if [[ "$format" == "binary" ]]; then
          cmd+=(-binary)
        fi

        cmd+=(HKDF)

        case "$format" in
          hex)
            derived_hex="$("''${cmd[@]}")"
            canonical_hex "$derived_hex"
            printf '\n'
            ;;
          binary)
            "''${cmd[@]}"
            ;;
          ed25519)
            derived_hex="$(canonical_hex "$("''${cmd[@]}")")"
            emit_ed25519_pem "$derived_hex"
            ;;
          age)
            derived_hex="$(canonical_hex "$("''${cmd[@]}")")"
            emit_age_identity "$derived_hex"
            ;;
        esac
  '';

  meta = with lib; {
    description = "Derive deterministic key material from the Raspberry Pi OTP private key using HKDF-SHA256";
    homepage = "https://github.com/nvmd/nixos-raspberrypi";
    license = licenses.mit;
    mainProgram = "rpi-otp-derived-key";
    platforms = [ "armv6l-linux" "armv7l-linux" "aarch64-linux" ];
  };
}
