# dev-shells/ascii-art.nix
#
# ASCII art logo display for nixos-raspberrypi development shell
#
# Uses jp2a to convert the Raspberry Pi logo to colored ASCII art.
# Falls back to a simple text banner if jp2a is not available.
#
# Usage in default.nix:
#   asciiArt = import ./ascii-art.nix { };
#

{ }:

''
  if command -v jp2a >/dev/null 2>&1 && [ -f "./docs/raspberry-pi-logo-berry.png" ]; then
    echo "$(jp2a --colors ./docs/raspberry-pi-logo-berry.png)"
    echo ""
  else
    echo "=== nixos-raspberrypi Development Shell ==="
  fi
''
