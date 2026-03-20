final: prev: {

  ffmpeg = final.ffmpeg_8;
  ffmpeg-headless = final.ffmpeg_8-headless;
  ffmpeg-full = final.ffmpeg_8-full;

  ffmpeg_7 = (
    prev.callPackage ../pkgs/ffmpeg_7-rpi.nix {
      ffmpeg = prev.ffmpeg_7;
    }
  ); # small
  ffmpeg_7-headless = final.ffmpeg_7.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_7-full = final.ffmpeg_7.override {
    ffmpegVariant = "full";
  };

  ffmpeg_8 = (
    prev.callPackage ../pkgs/ffmpeg_8-rpi.nix {
      ffmpeg = prev.ffmpeg_8;
    }
  ); # small
  ffmpeg_8-headless = final.ffmpeg_8.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_8-full = final.ffmpeg_8.override {
    ffmpegVariant = "full";
  };


  kodi = (prev.kodi.overrideAttrs (old: {
    pname = old.pname + "-rpi";
    buildInputs = old.buildInputs ++ [ final.dav1d ];
    cmakeFlags = let
      enableFeature = enable: feature:
        assert (prev.lib.isString feature);
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

  kodi-gbm = final.kodi.override {
    gbmSupport = true;
  };

  kodi-wayland = final.kodi.override {
    waylandSupport = true;
    # nixos defaults to "gl" for wayland, but libreelec uses "gles"
    # renderSystem = "gles";
  };


  libcamera = final.libcamera_rpi;

  libcamera_rpi = prev.libcamera.overrideAttrs (old: rec {
    pname = old.pname + "-rpi";
    version = "0.6.0+rpt20251202";

    src = prev.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "libcamera";
      rev = "v${version}";
      hash = "sha256-sJKzmeeXD/66P5o+X9w3J2gwxDNsdBUdXEqU6goJdN4=";
    };

    mesonFlags = old.mesonFlags ++ [
      # add flags that raspberry suggests, but nixpkgs doesn't include
      "--buildtype=release"
      "-Dpipelines=rpi/vc4,rpi/pisp"
      "-Dipas=rpi/vc4,rpi/pisp"
      "-Dgstreamer=enabled"
      "-Dtest=false"
      "-Dcam=disabled"
      "-Dpycamera=enabled"
      (prev.lib.mesonEnable "libunwind" false)
    ];

    meta = old.meta // {
      homepage = "https://github.com/raspberrypi/libcamera";
      changelog = "https://github.com/raspberrypi/libcamera/releases/tag/v${version}";
    };
  });

  vlc = prev.vlc.overrideAttrs (old: {
    pname = old.pname + "-rpi";
    version = "3.0.22-0+rpt1";

    # https://github.com/RPi-Distro/vlc/commits/pios/trixie
    src = prev.fetchFromGitHub {
      owner = "RPi-Distro";
      repo = "vlc";
      rev = "1e4f72f9f7af4de546c90062c248f6174af69f28";
      hash = "sha256-uuCRpv+tZ63KGOQJ9eejx7WNfzWpTAMkxoLGQNj0og0=";
    };
  });

}
