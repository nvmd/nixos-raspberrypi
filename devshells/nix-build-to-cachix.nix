{ writeShellApplication, jq, cachix, ... }:

writeShellApplication {
  name = "nix-build-to-cachix";
  runtimeInputs = [ jq cachix ];
  text = ''
    set -euo pipefail

    CACHE="$1"
    TARGET="''${2-""}"  # set to "" if not specified


    build_and_push() {
      local target="$1"

      nix build "''${target}" --json \
        | jq -r '.[].outputs | to_entries[].value' \
        | cachix push "''${CACHE}"
    }

    build_and_push_packages() {
      build_and_push ".#packages.aarch64-linux.$1"
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
      # "ffmpeg_7"

      # "kodi"
      "kodi-gbm"
      # "kodi-wayland"

      "libcamera"
      "libpisp"
      "libraspberrypi"

      "raspberrypi-utils"
      "raspberrypi-udev-rules"
      "rpicam-apps"

      "SDL2"

      "vlc"

      # linuxAndFirmware.latest.*
      "linux_rpi4"
      "linux_rpi5"
      "raspberrypifw"
      "raspberrypiWirelessFirmware"
    )

    for i in "''${packages[@]}"; do
      build_and_push_packages "$i"
    done

    set +o xtrace
  '';
}