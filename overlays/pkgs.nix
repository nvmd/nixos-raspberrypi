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


  ffmpeg_4-rpi = (super.callPackage ../pkgs/ffmpeg_4-rpi.nix {
    ffmpeg = super.ffmpeg_4;
  });
  ffmpeg_5-rpi = (super.callPackage ../pkgs/ffmpeg_5-rpi.nix {
    ffmpeg = super.ffmpeg_5;
  });
  ffmpeg_6-rpi = (super.callPackage ../pkgs/ffmpeg_6-rpi.nix {
    ffmpeg = super.ffmpeg_6;
  });

  vlc-rpi = (super.vlc.overrideAttrs (old: {
    version = "3.0.21-0+rpt1";

    # https://github.com/RPi-Distro/vlc/commits/bookworm-rpt/
    src = super.fetchFromGitHub {
      owner = "RPi-Distro";
      repo = "vlc";
      rev = "a9357f06c552c3983798c583bc40e55414088486";
      hash = "sha256-Di3uJ3gMlhrcY4jU8XE9U2oOVsbXi0V7ZG7C/XKRHeE=";
    };
  })).override {
    ffmpeg = self.ffmpeg_6-rpi;
  };

  SDL2-rpi = (super.SDL2.override {
    # enough to have the effect of '--enable-video-kmsdrm' (on by default) ?
    drmSupport = true;
  }).overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [
      # these are off by default
      # https://github.com/libsdl-org/SDL/blob/SDL2/CMakeLists.txt#L417
      "--enable-arm-simd"
      "--enable-arm-neon"
    ];
  });

}