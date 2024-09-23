self: super: { # final: prev:

  libcamera = self.libcamera_rpi;

  libcamera_rpi = super.libcamera.overrideAttrs (old: rec {
    pname = old.pname + "-rpi";
    version = "0.3.0+rpt20240617";

    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "libcamera";
      rev = "v${version}";
      hash = "sha256-qqEMJzMotybf1nJp1dsz3zc910Qj0TmqCm1CwuSb1VY=";
    };

    # not needed for nixpkgs-unstable
    postPatch = ''
      ${old.postPatch}
      patchShebangs src/py/
    '';

    buildInputs = old.buildInputs ++ (with self; [
      libpisp
      python3Packages.pybind11  # not needed for nixpkgs-unstable
    ]);

    mesonFlags = old.mesonFlags ++ [
      # add flags that raspberry suggests, but nixpkgs doesn't include
      "--buildtype=release"
      "-Dpipelines=rpi/vc4,rpi/pisp"
      "-Dipas=rpi/vc4,rpi/pisp"
      "-Dgstreamer=enabled"
      "-Dtest=false"
      "-Dcam=disabled"
      "-Dpycamera=enabled"
    ];

    meta = old.meta // {
      homepage = "https://github.com/raspberrypi/libcamera";
      changelog = "https://github.com/raspberrypi/libcamera/releases";
    };
  });

  libpisp = self.callPackage ../pkgs/raspberrypi/libpisp.nix {};

  libraspberrypi = super.callPackage ../pkgs/raspberrypi/libraspberrypi.nix {};

  raspberrypi-userland = self.libraspberrypi;

  raspberrypi-udev-rules = super.callPackage ../pkgs/raspberrypi/udev-rules.nix {};

  raspberrypi-utils = super.callPackage ../pkgs/raspberrypi/raspberrypi-utils.nix {};

  rpi-userland = self.libraspberrypi;

  rpicam-apps = super.callPackage ../pkgs/raspberrypi/rpicam-apps.nix {
    libcamera = self.libcamera_rpi;
  };

}