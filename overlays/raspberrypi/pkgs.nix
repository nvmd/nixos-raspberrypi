self: super: { # final: prev:

  # libcec-rpi = super.libcec.override {
  #   withLibraspberrypi = true;
  # };

  kodi-rpi-gbm = self.kodi-rpi.override {
    gbmSupport = true;
  };
  kodi-rpi-wayland = self.kodi-rpi.override {
    waylandSupport = true;
    # nixos defaults to "gl" for wayland, but libreelec uses "gles"
    # renderSystem = "gles";
  };

  kodi-rpi = (super.kodi.overrideAttrs (old: {
    pname = "kodi-rpi";
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
    # needs to be set explicitly, won't be pulled from scope automagically
    # inherit (self) ffmpeg;
    ffmpeg = self.ffmpeg_6-rpi;
    # libcec = self.libcec-rpi;
    vdpauSupport = false;
  };


  ffmpeg_4-rpi = (super.callPackage ../../pkgs/ffmpeg_4-rpi.nix {
    ffmpeg = super.ffmpeg_4;
  });
  ffmpeg_5-rpi = (super.callPackage ../../pkgs/ffmpeg_5-rpi.nix {
    ffmpeg = super.ffmpeg_5;
  });
  ffmpeg_6-rpi = (super.callPackage ../../pkgs/ffmpeg_6-rpi.nix {
    ffmpeg = super.ffmpeg_6;
  });

  vlc-rpi = (super.vlc.overrideAttrs (old: {
    version = "3.0.20-0+rpt6";

    # https://github.com/RPi-Distro/vlc/commits/bookworm-rpt/
    src = super.fetchFromGitHub {
      owner = "RPi-Distro";
      repo = "vlc";
      rev = "636141a3506e8de95683e3b0eb571bf9a9c19b96";
      hash = "sha256-RjphP48pmHDEMBWMNWWPf/rL0/l0ZMXrXz7yVldwsP0=";
    };
  })).override {
    ffmpeg = self.ffmpeg_6-rpi;
  };

  SDL2-rpi = super.SDL2.override {
    # enough to have the effect of '--enable-video-kmsdrm' ?
    drmSupport = true;
  };

  libcamera-rpi = super.libcamera.overrideAttrs (old: rec {
    version = "0.3.0+rpt20240617";

    src = super.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "libcamera";
      rev = "v${version}";
      hash = "sha256-qqEMJzMotybf1nJp1dsz3zc910Qj0TmqCm1CwuSb1VY=";
    };

    buildInputs = old.buildInputs ++ (with self; [
      libpisp
      python3Packages.pybind11
    ]);
    # patches = [ ];
  });

  rpicam-apps = super.callPackage ../../pkgs/raspberrypi/rpicam-apps.nix {
    libcamera = self.libcamera-rpi;
  };

}