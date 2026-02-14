# sources for raspberrypi-firmware
# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/firmware/raspberrypi/default.nix
#
# https://github.com/raspberrypi/firmware/
# see `extra/git_hash` for a matching hash of the `raspberrypi/linux`
[
  {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20250915
    version = "1.20250915";
    tag = "1.20250915";
    # rev = "676efed1194de38975889a34276091da1f5aadd3";
    srcHash = "sha256-DqVgsPhppxCsZ+H6S7XY5bBoRhOgPipKibDwikqBk08=";
  }
  {
    version = "0-unstable-20250829";
    # this release for linux 6.12.44 is untagged in the upstream
    rev = "73065c21a0337eac9de13521fc1254cdadd3bd0a";
    srcHash = "sha256-cprLY/xtYuE2LjgbQGuPlHBlIYLS5YSp/URvgCLMB14=";
  }
  {
    # this release is untagged in the upstream
    # this is the version of the matching stable kernel from `raspberrypi/linux`
    version = "1.20250702";
    rev = "7022a895240b2f853d9035ab61616b646caf7b3a";
    srcHash = "sha256-VpjzwVzjgwBRXIfeGblnPzgjYyw7Nr1GqyjKtGnuduk=";
  }
  {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20250430
    version = "1.20250430";
    tag = "1.20250430";
    srcHash = "sha256-U41EgEDny1R+JFktSC/3CE+2Qi7GJludj929ft49Nm0=";
  }
  {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20250127
    version = "1.20250127";
    tag = "1.20250127";
    srcHash = "sha256-gdZt9xS3X1Prh+TU0DLy6treFoJjiUUUiZ3IoDbopzI=";
  }
  {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20241008
    version = "1.20241008";
    tag = "1.20241008";
    srcHash = "sha256-4gnK0KbqFnjBmWia9Jt2gveVWftmHrprpwBqYVqE/k0=";
  }
  {
    # https://github.com/raspberrypi/firmware/releases/tag/1.20240529
    version = "1.20240529";
    tag = "1.20240529";
    srcHash = "sha256-KsCo7ZG6vKstxRyFljZtbQvnDSqiAPdUza32xTY/tlA=";
  }
  {
    # they seem to got back to releases
    # https://github.com/raspberrypi/firmware/releases/tag/1.20240424
    version = "1.20240424";
    tag = "1.20240424";
    srcHash = "sha256-X5OinkLh/+mx34DM8mCk4tqOGuJdYxkvygv3gA77NJI=";
  }
  {
    version = "stable_20240124";
    rev = "4649b6d52005b52b1d23f553b5e466941bc862dc";
    srcHash = "sha256-K+5QBjsic3c2OTi8ROot3BVDnIrXDjZ4C6k3WKWogxI=";
  }
  {
    # as in nixpkgs-unstable
    version = "stable_20231123";
    rev = "524247ac6d8b1f4ddd53730e978a70c76a320bd6";
    srcHash = "sha256-rESwkR7pc5MTwIZ8PaMUPXuzxfv+jVpdRp8ijvxHGcg=";
  }
]