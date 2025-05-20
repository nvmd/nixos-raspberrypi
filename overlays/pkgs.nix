self: super: { # final: prev:

  ffmpeg = self.ffmpeg_6;
  ffmpeg-headless = self.ffmpeg_6-headless;
  ffmpeg-full = self.ffmpeg_6-full;

  ffmpeg_4 = (super.callPackage ../pkgs/ffmpeg_4-rpi.nix {
    ffmpeg = super.ffmpeg;
  }); # small
  ffmpeg_4-headless = self.ffmpeg_4.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_4-full = self.ffmpeg_4.override {
    ffmpegVariant = "full";
  };

  ffmpeg_5 = (super.callPackage ../pkgs/ffmpeg_5-rpi.nix {
    ffmpeg = super.ffmpeg;
  }); # small
  ffmpeg_5-headless = self.ffmpeg_5.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_5-full = self.ffmpeg_5.override {
    ffmpegVariant = "full";
  };

  ffmpeg_6 = (super.callPackage ../pkgs/ffmpeg_6-rpi.nix {
    ffmpeg = super.ffmpeg;
  }); # small
  ffmpeg_6-headless = self.ffmpeg_6.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_6-full = self.ffmpeg_6.override {
    ffmpegVariant = "full";
  };

  ffmpeg_7 = (super.callPackage ../pkgs/ffmpeg_7-rpi.nix {
    ffmpeg = super.ffmpeg;
  }); # small
  ffmpeg_7-headless = self.ffmpeg_7.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_7-full = self.ffmpeg_7.override {
    ffmpegVariant = "full";
  };


  kodi = (super.kodi.overrideAttrs (old: {
    pname = old.pname + "-rpi";
    buildInputs = old.buildInputs ++ [ self.dav1d ];
    cmakeFlags = let
      enableFeature = enable: feature:
        assert (super.lib.isString feature);
        "-DENABLE_${feature}=${if enable then "ON" else "OFF"}";
    in old.cmakeFlags ++ [
      "-DENABLE_INTERNAL_DAV1D=OFF"
    ] ++ [
      # inspired by being hardcoded in libreelec
      # leaving because this is potentially due to performance considerations
      "-DENABLE_LCMS2=OFF"
    ] ++ [
      (enableFeature true  "NEON")
      (enableFeature false "VAAPI")
    ] ++ [
      "-DENABLE_CEC=ON"
      "-DENABLE_AVAHI=ON"
      #-DAPP_RENDER_SYSTEM=
    ];
  })).override {
    vdpauSupport = false;
  };

  kodi-gbm = self.kodi.override {
    gbmSupport = true;
  };

  kodi-wayland = self.kodi.override {
    waylandSupport = true;
    # nixos defaults to "gl" for wayland, but libreelec uses "gles"
    # renderSystem = "gles";
  };


  libcamera = self.libcamera_rpi;

  libcamera_rpi = super.libcamera.overrideAttrs (old: rec {
    pname = old.pname + "-rpi";
    version = "0.5.0+rpt20250429";

    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "libcamera";
      rev = "v${version}";
      hash = "sha256-7nXoYgwV354T42QM9LA9U0xlG2f4Gc7I1inaEG/HwTI=";
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
      changelog = "https://github.com/raspberrypi/libcamera/releases/tag/v${version}";
    };
  });

  vlc = super.vlc.overrideAttrs (old: {
    pname = old.pname + "-rpi";
    version = "3.0.21-0+rpt1";

    # https://github.com/RPi-Distro/vlc/commits/bookworm-rpt/
    src = super.fetchFromGitHub {
      owner = "RPi-Distro";
      repo = "vlc";
      rev = "a9357f06c552c3983798c583bc40e55414088486";
      hash = "sha256-Di3uJ3gMlhrcY4jU8XE9U2oOVsbXi0V7ZG7C/XKRHeE=";
    };
  });

}