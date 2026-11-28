final: prev: {
  # https://github.com/nvmd/nixos-raspberrypi/issues/64
  jemalloc = prev.jemalloc.override { pageSizeKiB = 16; };
}
