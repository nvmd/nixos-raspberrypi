{ lib
, pkgs
, mockOtpHex ? "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
,
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

  testOverlay = final: prev: {
    rpi-otp-private-key = mockRpiOtpPrivateKey;
    rpi-otp-derived-key =
      (prev.callPackage ../../pkgs/raspberrypi/rpi-otp-derived-key.nix {
        rpi-otp-private-key = final.rpi-otp-private-key;
      }).overrideAttrs (old: {
        meta = (old.meta or { }) // {
          platforms = lib.platforms.linux;
        };
      });
    rpi-otp-derived-key-provision =
      (prev.callPackage ../../pkgs/raspberrypi/rpi-otp-derived-key-provision.nix {
        rpi-otp-private-key = final.rpi-otp-private-key;
        rpi-otp-derived-key = final.rpi-otp-derived-key;
      }).overrideAttrs (old: {
        meta = (old.meta or { }) // {
          platforms = lib.platforms.linux;
        };
      });
  };
in
{
  persistentSaltPathForName = name: "/var/lib/rpi-otp-derived-key/salt/${otpDerivedKeyLib.saltPathComponentForName name}";
  testPkgs = pkgs.extend testOverlay;
}
