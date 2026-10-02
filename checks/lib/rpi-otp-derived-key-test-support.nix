{
  lib,
  pkgs,
  mockOtpHex ? "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
}:

let
  otpDerivedKeyLib = import ../../lib/rpi-otp-derived-key.nix { };

  mockRpiOtpPrivateKey = pkgs.writeShellApplication {
    name = "rpi-otp-private-key";
    text = ''
            set -euo pipefail

            otp_hex='${mockOtpHex}'

            while [[ $# -gt 0 ]]; do
              case "$1" in
                -c)
                  if [[ "$otp_hex" =~ ^0+$ ]]; then
                    exit 1
                  fi
                  exit 0
                  ;;
                -l|-o)
                  shift 2
                  ;;
                -w)
                  shift 2
                  exit 0
                  ;;
                -h|--help)
                  cat <<'EOF'
      Usage: rpi-otp-private-key [-c] [-w KEY] [-l WORDS] [-o OFFSET]
      EOF
                  exit 0
                  ;;
                --)
                  shift
                  break
                  ;;
                *)
                  shift
                  ;;
              esac
            done

            printf '%s\n' "$otp_hex"
    '';
  };

  mockRpiFwCrypto = pkgs.writeShellApplication {
    name = "rpi-fw-crypto";
    runtimeInputs = [ pkgs.openssl ];
    text = ''
      set -euo pipefail

      otp_hex='${mockOtpHex}'

      case "''${1:-}" in
        get-num-otp-keys)
          [[ $# -eq 1 ]]
          printf 'Number of OTP keys: 2\n'
          ;;
        hmac)
          shift
          input=""
          output=""
          key_id=""

          while [[ $# -gt 0 ]]; do
            case "$1" in
              --in)
                input="$2"
                shift 2
                ;;
              --out)
                output="$2"
                shift 2
                ;;
              --key-id)
                key_id="$2"
                shift 2
                ;;
              *)
                echo "unexpected argument: $1" >&2
                exit 1
                ;;
            esac
          done

          [[ "$key_id" == 1 ]]
          [[ -n "$input" ]]
          [[ -n "$output" ]]
          if [[ "$otp_hex" =~ ^0+$ ]]; then
            echo "Last crypto error: 6 (Key is not set)" >&2
            exit 250
          fi
          openssl dgst -sha256 -mac HMAC -macopt "hexkey:$otp_hex" \
            -binary -out "$output" "$input"
          ;;
        *)
          echo "unexpected command: ''${1:-}" >&2
          exit 1
          ;;
      esac
    '';
  };

  testOverlay = final: prev: {
    raspberrypi-utils = mockRpiFwCrypto;
    rpi-otp-private-key = mockRpiOtpPrivateKey;
    rpi-otp-derived-key =
      (prev.callPackage ../../pkgs/raspberrypi/rpi-otp-derived-key.nix {
        raspberrypi-utils = final.raspberrypi-utils;
        rpi-otp-private-key = final.rpi-otp-private-key;
      }).overrideAttrs
        (old: {
          meta = (old.meta or { }) // {
            platforms = lib.platforms.linux;
          };
        });
    rpi-otp-derived-key-provision =
      (prev.callPackage ../../pkgs/raspberrypi/rpi-otp-derived-key-provision.nix {
        rpi-otp-derived-key = final.rpi-otp-derived-key;
      }).overrideAttrs
        (old: {
          meta = (old.meta or { }) // {
            platforms = lib.platforms.linux;
          };
        });
  };
in
{
  persistentSaltPathForName =
    name: "/var/lib/rpi-otp-derived-key/salt/${otpDerivedKeyLib.saltPathComponentForName name}";
  supportedRaspberryPiVariantModule = {
    options.boot.loader.raspberry-pi.variant = lib.mkOption {
      type = lib.types.enum [
        "02"
        "4"
        "5"
      ];
      default = "4";
      description = "Test-only Raspberry Pi variant option for rpi-otp-derived-key.";
    };
  };
  testPkgs = pkgs.extend testOverlay;
}
