self: super: { # final: prev:

  # now available from nixpkgs but waiting on https://github.com/NixOS/nixpkgs/pull/429288
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

  libraspberrypi = super.callPackage ../pkgs/raspberrypi/libraspberrypi.nix {};

  raspberrypi-userland = self.libraspberrypi;

  raspberrypi-udev-rules = super.callPackage ../pkgs/raspberrypi/udev-rules.nix {};

  raspberrypi-utils = super.callPackage ../pkgs/raspberrypi/raspberrypi-utils.nix {};

  rpi-userland = self.libraspberrypi;

  rpicam-apps = super.callPackage ../pkgs/raspberrypi/rpicam-apps.nix {
    libcamera = self.libcamera_rpi;
  };

}
