final: prev: {
  # https://github.com/nvmd/nixos-raspberrypi/issues/64
  # credit for the initial version of this snippet goes to @micahcc
  jemalloc = prev.jemalloc.overrideAttrs (old: {
    # --with-lg-page=(log2 page_size)
    # RPi5 (bcm2712): since our page size is 16384 (2**14), we need 14
    configureFlags = let
      pageSizeFlag = "--with-lg-page";
    in (prev.lib.filter (flag: prev.lib.hasPrefix pageSizeFlag flag == false) old.configureFlags)
      ++ [ "${pageSizeFlag}=14" ];
  });
}