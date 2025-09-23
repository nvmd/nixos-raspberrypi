self: super: {
  # Fixes the issue https://github.com/nvmd/nixos-raspberrypi/issues/48

  # This overlay is to be removed once https://github.com/NixOS/nixpkgs/pull/429288
  # is upstreamed
  libpisp = super.libpisp.overrideAttrs (old: {
    preFixup = ''
      so=$out/lib/libpisp.so.1
      patchelf --set-soname $so $so
      patchelf --remove-rpath $so
      needed=$(patchelf --print-needed $so)
      for pkg in ${super.glibc} ${super.boost} ${super.libgcc} ${super.stdenv.cc.cc.lib}; do
        for lib in $needed; do
          for libpath in $(find -L $pkg/lib -type f -name "$lib"); do
            patchelf --replace-needed $lib $libpath $so
          done
        done
      done
    '';
  });
}