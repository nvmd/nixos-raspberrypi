{ writeShellApplication, jq, cachix, ... }:

writeShellApplication {
  name = "nix-build-to-cachix";
  runtimeInputs = [ jq cachix ];
  text = ''
    set -euo pipefail

    CACHE="$1"
    TARGET="''${2-""}"  # set to "" if not specified


    build_and_push() {
      local prefix="$1"
      local target="$2"

      nix build "''${prefix}.''${target}" --json \
        | jq -r '.[].outputs | to_entries[].value' \
        | cachix push "''${CACHE}"
    }

    build_and_push_packages() {
      build_and_push ".#packages.aarch64-linux" "$1"
    }

    build_and_push_nixpkgs() {
      build_and_push ".#legacyPackages.aarch64-linux" "$1"
    }

    build_and_push_nixpkgs_unstable() {
      build_and_push ".#legacyPackagesUnstable.aarch64-linux" "$1"
    }


    set -o xtrace

    if [ -n "''${TARGET}" ]; then
      echo "bulding and pushing only the specified target"
      build_and_push "''${TARGET}"
      exit
    fi

    echo "building and pushing all predetermined targets"

    # pushing all packages at once, sadly, isn't that easy
    # * https://docs.cachix.org/pushing
    # * https://github.com/NixOS/nix/issues/7165
    # thus, the following boilerplate

    declare -a packages=(
      "ffmpeg_4"
      "ffmpeg_6"

      # "kodi"
      "kodi-gbm"
      "kodi-wayland"

      "libcamera"
      "libpisp"
      "libraspberrypi"

      "SDL2"

      "vlc"

      "linux_rpi4"
      "linux_rpi5"
      "raspberrypifw"
      "raspberrypiWirelessFirmware"
    )
    declare -a nixpkgs=(
      "libcamera"
      "libpisp"
      "libraspberrypi"

      "SDL2"

      "vlc"

      "linuxAndFirmware.latest.linux_rpi4"
      "linuxAndFirmware.latest.linux_rpi5"
      "linuxAndFirmware.latest.raspberrypifw"
      "linuxAndFirmware.latest.raspberrypiWirelessFirmware"
    )
    declare -a nixpkgs_unstable=(
      "linuxAndFirmware.latest.linux_rpi4"
      # "linuxAndFirmware.latest.linux_rpi5"
      "linuxAndFirmware.latest.raspberrypifw"
      "linuxAndFirmware.latest.raspberrypiWirelessFirmware"
    )

    for i in "''${packages[@]}"; do
      build_and_push_packages "$i"
    done

    for i in "''${nixpkgs[@]}"; do
      build_and_push_nixpkgs "$i"
    done

    for i in "''${nixpkgs_unstable[@]}"; do
      build_and_push_nixpkgs_unstable "$i"
    done

    set +o xtrace
  '';
}