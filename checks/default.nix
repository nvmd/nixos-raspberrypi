{
  self,
  nixpkgs,
  rpiSystems,
  moduleSystems ? [ "x86_64-linux" ],
}:

let
  inherit (nixpkgs) lib;

  mkPackageChecks =
    system:
    let
      pkgs = self.legacyPackages.${system};
      rpi-otp-private-key-stub = pkgs.writeShellApplication {
        name = "rpi-otp-private-key";
        text = ''
          words=8
          offset=0

          while [ "$#" -gt 0 ]; do
            case "$1" in
              -c)
                exit 0
                ;;
              -l)
                words="$2"
                shift 2
                ;;
              -o)
                offset="$2"
                shift 2
                ;;
              *)
                echo "unexpected argument: $1" >&2
                exit 1
                ;;
            esac
          done

          [ "$words" = 8 ]
          [ "$offset" = 0 ]
          printf '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f\n'
        '';
      };
      rpi-fw-crypto-stub = pkgs.writeShellApplication {
        name = "rpi-fw-crypto";
        runtimeInputs = [ pkgs.openssl ];
        text = ''
          otp_hex=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

          case "''${1:-}" in
            get-num-otp-keys)
              [ "$#" -eq 1 ]
              printf 'Number of OTP keys: 2\n'
              ;;
            hmac)
              shift
              input=""
              output=""
              key_id=""

              while [ "$#" -gt 0 ]; do
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

              [ "$key_id" = 1 ]
              [ -n "$input" ]
              [ -n "$output" ]
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
      rpi-otp-derived-key-test = pkgs.callPackage ../pkgs/raspberrypi/rpi-otp-derived-key.nix {
        raspberrypi-utils = rpi-fw-crypto-stub;
        rpi-otp-private-key = rpi-otp-private-key-stub;
      };
      rpi-otp-derived-key-provision-test =
        pkgs.callPackage ../pkgs/raspberrypi/rpi-otp-derived-key-provision.nix
          {
            rpi-otp-derived-key = rpi-otp-derived-key-test;
          };
    in
    {
      rpi-otp-derived-key = pkgs.rpi-otp-derived-key;
      rpi-otp-derived-key-provision = pkgs.rpi-otp-derived-key-provision;
      rpi-otp-private-key = pkgs.rpi-otp-private-key;

      rpi-otp-derived-key-functional =
        pkgs.runCommand "rpi-otp-derived-key-functional"
          {
            nativeBuildInputs = [
              pkgs.age
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.openssl
              rpi-otp-derived-key-test
            ];
          }
          ''
                      expected_formats='hex
            binary
            ed25519
            age'
                      actual_formats="$(rpi-otp-derived-key --list-formats)"
                      [ "$actual_formats" = "$expected_formats" ]

                      expected_schemes='firmware-hmac-v1
            legacy-hkdf-v1'
                      actual_schemes="$(rpi-otp-derived-key --list-schemes)"
                      [ "$actual_schemes" = "$expected_schemes" ]

                      if rpi-otp-derived-key --salt test >/dev/null 2>&1; then
                        echo 'derivation without an explicit scheme unexpectedly succeeded' >&2
                        exit 1
                      fi

                      hex="$(rpi-otp-derived-key --scheme firmware-hmac-v1 --salt test --length 16)"
                      [ "$hex" = 3af1c2989382191c946c59a857de7b1a ]

                      long_hex="$(rpi-otp-derived-key --scheme firmware-hmac-v1 --salt test --length 48)"
                      [ "$long_hex" = 03ce52c89f68a872ccccf2932f23c48c6eb5324ff325550f83fd8abf4f0a717fc63b05a15210efda0a979f37e250dd87 ]

                      legacy_hex="$(rpi-otp-derived-key --scheme legacy-hkdf-v1 --salt test --length 16)"
                      [ "$legacy_hex" = e7dcc3a57ae51c6f2c5046b1c6352863 ]

                      rpi-otp-derived-key --scheme firmware-hmac-v1 --salt test --format ed25519 > ed25519.pem
                      openssl pkey -in ed25519.pem -noout

                      rpi-otp-derived-key --scheme firmware-hmac-v1 --salt test --format age > age-identity.txt
                      age_secret="$(grep '^AGE-SECRET-KEY-1' age-identity.txt)"
                      age_recipient="$(printf '%s\n' "$age_secret" | age-keygen -y)"
                      grep -qx "# public key: $age_recipient" age-identity.txt

                      touch $out
          '';

      rpi-otp-derived-key-provision-functional =
        pkgs.runCommand "rpi-otp-derived-key-provision-functional"
          {
            nativeBuildInputs = [
              pkgs.coreutils
              pkgs.fakeroot
              pkgs.gnugrep
              rpi-otp-derived-key-provision-test
            ];
          }
          ''
            work="$PWD/work"
            salt="$work/stage/salt/luks-key"
            key="$work/run/secrets/luks.key"
            target="$work/target/var/lib/rpi-otp-derived-key/salt/luks-key"
            cleanup="$work/cleanup-marker"
            mkdir -p "$work"

            fakeroot -- bash -c '
              set -euo pipefail

              salt="$1"
              key="$2"
              target="$3"
              cleanup="$4"
              work="$5"

              mkdir -p "$(dirname -- "$key")" "$(dirname -- "$target")"
              chmod 0750 "$(dirname -- "$key")"
              chmod 0755 "$(dirname -- "$target")"

              rpi-otp-derived-key-provision stage \
                --scheme firmware-hmac-v1 \
                --format hex \
                --salt-file "$salt" \
                --out "$key"

              test -e "$salt"
              test -e "$key"
              grep -Eq "^[0-9a-f]{64}$" "$key"
              stat -c "%a %U %G" "$salt" | grep -qx "400 root root"
              stat -c "%a %U %G" "$key" | grep -qx "400 root root"
              stat -c "%a" "$(dirname -- "$key")" | grep -qx "750"

              cp "$salt" "$work/first.salt"
              cp "$key" "$work/first.key"

              rpi-otp-derived-key-provision stage \
                --scheme firmware-hmac-v1 \
                --format hex \
                --salt-file "$salt" \
                --out "$key"

              cmp "$work/first.salt" "$salt"
              cmp "$work/first.key" "$key"
              grep -Eq "^[0-9a-f]{64}$" "$key"

              touch "$cleanup"
              rpi-otp-derived-key-provision install-salt \
                --salt-file "$salt" \
                --target-file "$target" \
                --cleanup "$salt" \
                --cleanup "$key" \
                --cleanup "$cleanup"

              cmp "$work/first.salt" "$target"
              stat -c "%a %U %G" "$target" | grep -qx "400 root root"
              stat -c "%a" "$(dirname -- "$target")" | grep -qx "755"
              test ! -e "$salt"
              test ! -e "$key"
              test ! -e "$cleanup"

              target_inode="$(stat -c "%i" "$target")"
              touch "$work/idempotent-cleanup"
              rpi-otp-derived-key-provision install-salt \
                --salt-file "$work/first.salt" \
                --target-file "$target" \
                --cleanup "$work/idempotent-cleanup"
              test "$(stat -c "%i" "$target")" = "$target_inode"
              cmp "$work/first.salt" "$target"
              test ! -e "$work/idempotent-cleanup"

              printf "%032d" 0 > "$work/different.salt"
              touch "$work/mismatch-cleanup"
              if rpi-otp-derived-key-provision install-salt \
                --salt-file "$work/different.salt" \
                --target-file "$target" \
                --cleanup "$work/mismatch-cleanup"; then
                echo "mismatched salt installation unexpectedly succeeded" >&2
                exit 1
              fi
              cmp "$work/first.salt" "$target"
              test -e "$work/mismatch-cleanup"

              if rpi-otp-derived-key-provision stage \
                --scheme firmware-hmac-v1 \
                --format invalid \
                --salt-file "$work/first.salt" \
                --out "$work/run/secrets/failed.key"; then
                echo "invalid output format unexpectedly succeeded" >&2
                exit 1
              fi
              ! compgen -G "$work/run/secrets/.failed.key.tmp.*" >/dev/null
            ' -- "$salt" "$key" "$target" "$cleanup" "$work"

            touch $out
          '';
    };

  mkModuleChecks =
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      raspberrypi-initrd-secrets = pkgs.callPackage ./raspberrypi-initrd-secrets.nix { };
      rpi-otp-derived-key-before = pkgs.callPackage ./rpi-otp-derived-key-before.nix {
        inherit self;
      };
      rpi-otp-derived-key-disko-hooks = pkgs.callPackage ./rpi-otp-derived-key-disko-hooks.nix {
        inherit self;
      };
      rpi-otp-derived-key-ensure-script = pkgs.callPackage ./rpi-otp-derived-key-ensure-script.nix {
        inherit self;
      };
      rpi-otp-derived-key-generic-initrd = pkgs.callPackage ./rpi-otp-derived-key-generic-initrd.nix {
        inherit self nixpkgs;
      };
      rpi-otp-derived-key-invalid-configs = pkgs.callPackage ./rpi-otp-derived-key-invalid-configs.nix {
        inherit self nixpkgs;
      };
      rpi-otp-derived-key-install-time-salt =
        pkgs.callPackage ./rpi-otp-derived-key-install-time-salt.nix
          {
            inherit self;
          };
      rpi-otp-derived-key-install-time-otp-check =
        pkgs.callPackage ./rpi-otp-derived-key-install-time-otp-check.nix
          {
            inherit self;
          };
      rpi-otp-derived-key-initrd-luks = pkgs.callPackage ./rpi-otp-derived-key-initrd-luks.nix {
        inherit self;
      };
      rpi-otp-derived-key-stage2 = pkgs.callPackage ./rpi-otp-derived-key-stage2.nix {
        inherit self;
      };
    };
in
lib.recursiveUpdate (lib.genAttrs rpiSystems mkPackageChecks) (
  lib.genAttrs moduleSystems mkModuleChecks
)
