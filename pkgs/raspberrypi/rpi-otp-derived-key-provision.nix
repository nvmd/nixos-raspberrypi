{ lib
, writeShellApplication
, coreutils
, openssl
, rpi-otp-private-key
, rpi-otp-derived-key
,
}:

writeShellApplication {
  name = "rpi-otp-derived-key-provision";

  runtimeInputs = [
    coreutils
    openssl
    rpi-otp-private-key
    rpi-otp-derived-key
  ];

  text = ''
    set -euo pipefail

    die() {
      echo "rpi-otp-derived-key-provision: $*" >&2
      exit 1
    }

    usage() {
      cat <<'EOF'
    Usage:
      rpi-otp-derived-key-provision stage --salt-file PATH --out PATH [--format FORMAT]
      rpi-otp-derived-key-provision install-salt --salt-file PATH --target-file PATH [--cleanup PATH ...]

    Provision Raspberry Pi OTP-derived secrets for install-time workflows.

    Commands:
      stage
        Verify that the OTP private key is programmed, create a persistent salt
        if it does not already exist, and derive a secret output from that salt.

      install-salt
        Atomically copy a staged salt to durable state and optionally remove
        staged files after the copy succeeds.

    Options:
      --format FORMAT       Output format for stage. Defaults to hex.
      --salt-file PATH      Salt file to create/read.
      --out PATH            Output path for stage.
      --target-file PATH    Durable salt destination for install-salt.
      --cleanup PATH        Path to remove after install-salt succeeds. Repeatable.
      -h, --help            Show this help.
    EOF
    }

    tmp_paths=()

    cleanup_tmp_paths() {
      if (( ''${#tmp_paths[@]} > 0 )); then
        rm -f -- "''${tmp_paths[@]}"
      fi
    }

    trap cleanup_tmp_paths EXIT

    ensure_parent_dir() {
      local path="$1"
      local dir

      dir="$(dirname -- "$path")"
      install -d -m 0700 "$dir"
    }

    mk_tmp_for() {
      local path="$1"
      local dir
      local base
      local tmp_path

      dir="$(dirname -- "$path")"
      base="$(basename -- "$path")"
      tmp_path="$(mktemp "$dir/.$base.tmp.XXXXXX")"
      tmp_paths+=("$tmp_path")

      printf '%s\n' "$tmp_path"
    }

    set_secret_permissions() {
      local path="$1"

      chown root:root "$path"
      chmod 0400 "$path"
    }

    ensure_otp_private_key() {
      if ! rpi-otp-private-key -c >/dev/null; then
        die "Raspberry Pi OTP private key is not programmed"
      fi
    }

    create_salt_if_missing() {
      local salt_file="$1"
      local tmp_path

      ensure_parent_dir "$salt_file"

      if [[ -e "$salt_file" ]]; then
        [[ -f "$salt_file" ]] || die "salt path exists but is not a regular file: $salt_file"
      else
        tmp_path="$(mk_tmp_for "$salt_file")"
        openssl rand -out "$tmp_path" 32
        set_secret_permissions "$tmp_path"
        mv -n "$tmp_path" "$salt_file"
        [[ -f "$salt_file" ]] || die "failed to create salt file: $salt_file"
      fi

      set_secret_permissions "$salt_file"
    }

    stage_command() {
      local format="hex"
      local salt_file=""
      local out=""
      local tmp_path

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --format)
            [[ $# -ge 2 ]] || die "--format requires an argument"
            format="$2"
            shift 2
            ;;
          --salt-file)
            [[ $# -ge 2 ]] || die "--salt-file requires an argument"
            salt_file="$2"
            shift 2
            ;;
          --out)
            [[ $# -ge 2 ]] || die "--out requires an argument"
            out="$2"
            shift 2
            ;;
          -h|--help)
            usage
            exit 0
            ;;
          *)
            die "unknown stage argument: $1"
            ;;
        esac
      done

      [[ -n "$salt_file" ]] || die "stage requires --salt-file"
      [[ -n "$out" ]] || die "stage requires --out"

      ensure_otp_private_key
      create_salt_if_missing "$salt_file"
      ensure_parent_dir "$out"

      tmp_path="$(mk_tmp_for "$out")"
      rpi-otp-derived-key \
        --format "$format" \
        --salt-file "$salt_file" \
        > "$tmp_path"

      set_secret_permissions "$tmp_path"
      mv -f "$tmp_path" "$out"
    }

    install_salt_command() {
      local salt_file=""
      local target_file=""
      local tmp_path
      local cleanup_path
      local -a cleanup_paths=()

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --salt-file)
            [[ $# -ge 2 ]] || die "--salt-file requires an argument"
            salt_file="$2"
            shift 2
            ;;
          --target-file)
            [[ $# -ge 2 ]] || die "--target-file requires an argument"
            target_file="$2"
            shift 2
            ;;
          --cleanup)
            [[ $# -ge 2 ]] || die "--cleanup requires an argument"
            cleanup_paths+=("$2")
            shift 2
            ;;
          -h|--help)
            usage
            exit 0
            ;;
          *)
            die "unknown install-salt argument: $1"
            ;;
        esac
      done

      [[ -n "$salt_file" ]] || die "install-salt requires --salt-file"
      [[ -n "$target_file" ]] || die "install-salt requires --target-file"
      [[ -f "$salt_file" ]] || die "salt file does not exist: $salt_file"
      [[ -r "$salt_file" ]] || die "cannot read salt file: $salt_file"

      ensure_parent_dir "$target_file"
      tmp_path="$(mk_tmp_for "$target_file")"
      cp "$salt_file" "$tmp_path"
      set_secret_permissions "$tmp_path"
      mv -f "$tmp_path" "$target_file"

      for cleanup_path in "''${cleanup_paths[@]}"; do
        rm -f -- "$cleanup_path"
      done
    }

    if [[ $# -lt 1 ]]; then
      usage >&2
      exit 1
    fi

    command="$1"
    shift

    case "$command" in
      stage)
        stage_command "$@"
        ;;
      install-salt)
        install_salt_command "$@"
        ;;
      -h|--help)
        usage
        ;;
      *)
        die "unknown command: $command"
        ;;
    esac
  '';

  meta = with lib; {
    description = "Provision install-time secrets derived from the Raspberry Pi OTP private key";
    homepage = "https://github.com/nvmd/nixos-raspberrypi";
    license = licenses.mit;
    mainProgram = "rpi-otp-derived-key-provision";
    platforms = [ "armv6l-linux" "armv7l-linux" "aarch64-linux" ];
  };
}
