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
      local prefix=".#packages.aarch64-linux"

      nix build "''${prefix}.''${target}" --json \
        | jq -r '.[].outputs | to_entries[].value' \
        | cachix push "''${CACHE}"
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

    build_and_push "ffmpeg_4"
    build_and_push "ffmpeg_6"

    # build_and_push "kodi"
    build_and_push "kodi-gbm"
    build_and_push "kodi-wayland"

    build_and_push "libcamera"
    build_and_push "libpisp"
    build_and_push "libraspberrypi"

    build_and_push "SDL2"
    build_and_push "vlc"

    build_and_push "linuxAndFirmware.latest.linux_rpi4"
    build_and_push "linuxAndFirmware.latest.linux_rpi5"
    build_and_push "linuxAndFirmware.latest.raspberrypifw"
    build_and_push "linuxAndFirmware.latest.raspberrypiWirelessFirmware"

    set +o xtrace
  '';
}