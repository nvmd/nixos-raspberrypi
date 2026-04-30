{ self
, nixpkgs
, rpiSystems
, moduleSystems ? [ "x86_64-linux" ]
,
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
      rpi-otp-derived-key-test = pkgs.callPackage ../pkgs/raspberrypi/rpi-otp-derived-key.nix {
        rpi-otp-private-key = rpi-otp-private-key-stub;
      };
      rpi-otp-derived-key-provision-test = pkgs.callPackage ../pkgs/raspberrypi/rpi-otp-derived-key-provision.nix {
        rpi-otp-private-key = rpi-otp-private-key-stub;
        rpi-otp-derived-key = rpi-otp-derived-key-test;
      };
    in
    {
      rpi-otp-derived-key = pkgs.rpi-otp-derived-key;
      rpi-otp-derived-key-provision = pkgs.rpi-otp-derived-key-provision;
      rpi-otp-private-key = pkgs.rpi-otp-private-key;

      rpi-otp-derived-key-functional = pkgs.runCommand "rpi-otp-derived-key-functional"
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

                    hex="$(rpi-otp-derived-key --salt test --length 16)"
                    [ "''${#hex}" -eq 32 ]
                    printf '%s\n' "$hex" | grep -Eq '^[0-9a-f]{32}$'

                    rpi-otp-derived-key --salt test --format ed25519 > ed25519.pem
                    openssl pkey -in ed25519.pem -noout

                    rpi-otp-derived-key --salt test --format age > age-identity.txt
                    age_secret="$(grep '^AGE-SECRET-KEY-1' age-identity.txt)"
                    age_recipient="$(printf '%s\n' "$age_secret" | age-keygen -y)"
                    grep -qx "# public key: $age_recipient" age-identity.txt

                    touch $out
        '';

      rpi-otp-derived-key-provision-functional = pkgs.runCommand "rpi-otp-derived-key-provision-functional"
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

            rpi-otp-derived-key-provision stage \
              --format hex \
              --salt-file "$salt" \
              --out "$key"

            test -e "$salt"
            test -e "$key"
            grep -Eq "^[0-9a-f]{64}$" "$key"
            stat -c "%a %U %G" "$salt" | grep -qx "400 root root"
            stat -c "%a %U %G" "$key" | grep -qx "400 root root"

            cp "$salt" "$work/first.salt"
            cp "$key" "$work/first.key"

            rpi-otp-derived-key-provision stage \
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
            test ! -e "$salt"
            test ! -e "$key"
            test ! -e "$cleanup"
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
      rpi-otp-derived-key-install-time-salt = pkgs.callPackage ./rpi-otp-derived-key-install-time-salt.nix {
        inherit self;
      };
      rpi-otp-derived-key-install-time-otp-check = pkgs.callPackage ./rpi-otp-derived-key-install-time-otp-check.nix {
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
lib.recursiveUpdate
  (lib.genAttrs rpiSystems mkPackageChecks)
  (lib.genAttrs moduleSystems mkModuleChecks)
