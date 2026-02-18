{
  stdenv,
  lib,
  fetchFromGitHub,
  fetchpatch,
  libidn,
  libtasn1,
  p11-kit,
  zlib,
  cmake,
  nasm,
  pkg-config,
  gnutls,
  vdpauSupport ? true,
  libvdpau, # "${VDPAU_SUPPORT}" = "yes" -a "${DISPLAYSERVER}" = "x11"
  dav1dSupport ? true,
  dav1d, # target_has_feature "(neon|sse)"
  v4l2Support ? true,
  libdrm, # "${V4L2_SUPPORT}" = "yes"
  v4l2RequestSupport ? true,
  systemd,
  udev, # raspberryPi == true && raspberryPiDevice = "RPi4" –> "${PKG_V4L2_REQUEST}" = "yes"
  vaapiSupport ? true,
  libva, # "${VAAPI_SUPPORT}" = "yes"
  raspberryPi ? true, # "${PROJECT}" = "RPi"
  raspberryPiVersion ? "4", # "${DEVICE}" = "RPi4"
  speex,
  bzip2,
  libepoxy, # for vout_egl
  x264, # --enable-libx264
}:

let
  ffmpegVersion = "4.4";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo = "rpi-ffmpeg";
    rev = "release/${ffmpegVersion}/rpi_import_1";
    hash = "sha256-n+0/S51WrogVkrpmngDRw/0EC46OsTIxegyrw6S+Xbk=";
  };

  myConfigureFlags = [
    "--disable-debug --enable-stripping"

    "--enable-pic"
    "--enable-optimizations"
    "--enable-logging"

    "--disable-static"
    "--enable-shared"

    "--disable-doc"
    "--enable-gpl"

    "--enable-libx264"

    "--enable-avdevice \
    --enable-avcodec \
    --enable-avformat \
    --enable-swscale \
    --enable-postproc \
    --enable-avfilter"

    "--enable-pthreads"
    "--enable-network"
    "--enable-gnutls --disable-openssl"
    "--enable-swscale-alpha"

    "--enable-dct \
    --enable-fft \
    --enable-mdct \
    --enable-rdft"

    "--enable-runtime-cpudetect"

    "--enable-demuxers \
    --enable-parsers \
    --enable-bsfs \
    --enable-protocol=http"

    "--enable-filters"

    "--enable-bzlib"

    "--enable-libspeex"

    "--enable-zlib"
    "--enable-asm"
  ]
  ++ [
    "--disable-mmal"
    "--enable-neon"
  ]
  ++ lib.optionals raspberryPi [
    #"--disable-rpi"
    "--enable-sand"
  ]
  ++ lib.optionals v4l2Support [
    "--enable-v4l2_m2m"
    "--enable-libdrm"
    #                   "--enable-epoxy" # for vout_egl
    #                   "--enable-vout-egl"#rpi
    "--enable-vout-drm" # rpi
  ]
  ++ lib.optionals v4l2RequestSupport [
    "--enable-libudev"
    "--enable-v4l2-request"
  ]
  ++ lib.optional vaapiSupport "--enable-vaapi"
  ++ lib.optional vdpauSupport "--enable-vdpau"
  ++ lib.optional dav1dSupport "--enable-libdav1d"
  ++ [
    # I need programs
    # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/ffmpeg-full/default.nix#L303
    "--enable-ffmpeg"
    "--enable-ffplay"
    "--enable-ffprobe"
  ];

  # https://github.com/jc-kynesim/rpi-ffmpeg/blob/pi/4.3.4/rpi_15_rc1/pi-util/conf_native.sh#L85
  rpiConfigureFlags = [
    "--disable-stripping"
    "--disable-thumb
    --enable-v4l2-request\
    --enable-libdrm"
    # "--enable-vout-egl" # can't find epoxy so i can't enable this
    "--enable-vout-drm\
    --enable-gpl"
    # SHARED_LIBS
    "--enable-shared"
    # RPIOPTS
    "--disable-mmal --enable-sand"
    "--enable-libudev --enable-libx264" # from: https://blog.eiler.eu/posts/20210117/
  ];

  # https://github.com/xbmc/xbmc/blob/19.5-Matrix/tools/depends/target/ffmpeg/CMakeLists.txt#L111
  kodiConfigureFlags = [
    # hardcoded
    #--extra-version="kodi-${FFMPEG_VER}"
    "--disable-devices
    --disable-doc
    --disable-ffplay
    --disable-ffmpeg
    --disable-ffprobe
    --enable-gpl
    --enable-runtime-cpudetect
    --enable-postproc
    --enable-pthreads
    --enable-muxer=spdif
    --enable-muxer=adts
    --enable-muxer=asf
    --enable-muxer=ipod
    --enable-encoder=ac3
    --enable-encoder=aac
    --enable-encoder=wmav2
    --enable-protocol=http
    --enable-encoder=png
    --enable-encoder=mjpeg"
  ]
  ++ [
    # optional
    "--enable-pic"
    "--enable-gnutls"
    # and some more optional
    # ...
  ]
  ++ lib.optional vaapiSupport "--enable-vaapi"
  ++ lib.optional vdpauSupport "--enable-vdpau"
  ++ lib.optional dav1dSupport "--enable-libdav1d";

  # https://github.com/LibreELEC/LibreELEC.tv/blob/10.0.4/packages/multimedia/ffmpeg/package.mk#L105
  libreelecConfigureFlags = [
    "--disable-static"
    "--enable-shared"
    "--enable-gpl \
    --disable-version3 \
    --enable-logging \
    --disable-doc"

    # ${PKG_FFMPEG_DEBUG}
    "--disable-debug --enable-stripping"

    "--enable-pic \
 
    --enable-optimizations \
    --disable-extra-warnings \
    --disable-programs \
    --enable-avdevice \
    --enable-avcodec \
    --enable-avformat \
    --enable-swscale \
    --enable-postproc \
    --enable-avfilter \
    --disable-devices \
    --enable-pthreads \
    --enable-network \
    --enable-gnutls --disable-openssl \
    --disable-gray \
    --enable-swscale-alpha \
    --disable-small \
    --enable-dct \
    --enable-fft \
    --enable-mdct \
    --enable-rdft \
    --disable-crystalhd \
    
    --enable-runtime-cpudetect \
    --disable-hardcoded-tables \
    --disable-encoders \
    --enable-encoder=ac3 \
    --enable-encoder=aac \
    --enable-encoder=wmav2 \
    --enable-encoder=mjpeg \
    --enable-encoder=png \
    
    --disable-muxers \
    --enable-muxer=spdif \
    --enable-muxer=adts \
    --enable-muxer=asf \
    --enable-muxer=ipod \
    --enable-muxer=mpegts \
    --enable-demuxers \
    --enable-parsers \
    --enable-bsfs \
    --enable-protocol=http \
    --disable-indevs \
    --disable-outdevs \
    --enable-filters \
    --disable-avisynth \
    --enable-bzlib \
    --disable-lzma \
    --disable-alsa \
    --disable-frei0r \
    --disable-libopencore-amrnb \
    --disable-libopencore-amrwb \
    --disable-libopencv \
    --disable-libdc1394 \
    --disable-libfreetype \
    --disable-libgsm \
    --disable-libmp3lame \
    --disable-libopenjpeg \
    --disable-librtmp \
    
    --enable-libspeex \
    --disable-libtheora \
    --disable-libvo-amrwbenc \
    --disable-libvorbis \
    --disable-libvpx \
    --disable-libx264 \
    --disable-libxavs \
    --disable-libxvid \
    --enable-zlib \
    --enable-asm \
    --disable-altivec \
    
    --disable-symver"
  ]
  ++ [
    "--disable-mmal" # PKG_FFMPEG_RPI
    "--enable-neon" # target_has_feature neon;
  ]
  ++ lib.optionals raspberryPi [
    "--disable-rpi"
    "--enable-sand"
  ]
  ++ lib.optionals v4l2Support [
    "--enable-v4l2_m2m"
    "--enable-libdrm"
    #                   "--enable-epoxy" # for vout_egl
    #                   "--enable-vout-egl"#rpi
    "--enable-vout-drm" # rpi
  ]
  ++ lib.optional vaapiSupport "--enable-vaapi"
  ++ lib.optionals v4l2RequestSupport [
    "--enable-libudev"
    "--enable-v4l2-request"
  ]
  ++ lib.optionals (raspberryPi && (raspberryPiVersion == "4")) [
    # PKG_FFMPEG_HWACCEL
    "--disable-hwaccel=h264_v4l2request"
    "--disable-hwaccel=mpeg2_v4l2request"
    "--disable-hwaccel=vp8_v4l2request"
    "--disable-hwaccel=vp9_v4l2request"
  ]
  ++ lib.optional vdpauSupport "--enable-vdpau"
  ++ lib.optional dav1dSupport "--enable-libdav1d";

in
stdenv.mkDerivation rec {
  pname = "ffmpeg-rpi";
  version = ffmpegVersion;

  src = rpiFfmpegSrc;

  preConfigure = ''
    export CCACHE_DIR=/nix/var/cache/ccache
    export CCACHE_UMASK=007

  '';

  # maybe I should base this derivation on
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/ffmpeg/generic.nix
  # it handles lots of configure flags better than I do
  configureFlags = [
    "--extra-version=rpi"
    # ] ++ libreelecConfigureFlags;
    # ] ++ rpiConfigureFlags;
  ]
  ++ myConfigureFlags;

  enableParallelBuilding = true;

  buildInputs = [
    libidn
    libtasn1
    p11-kit
    zlib
  ]
  ++ [
    speex
    bzip2 # for --enable-bzlib
    libepoxy.dev # for vout_egl
    x264 # --enable-libx264
  ]
  ++ lib.optional v4l2Support libdrm.dev
  ++ lib.optional v4l2RequestSupport systemd
  ++ lib.optional vaapiSupport libva
  ++ lib.optional vdpauSupport libvdpau
  ++ lib.optional dav1dSupport dav1d;

  nativeBuildInputs = [
    pkg-config
    gnutls
  ]
  ++ lib.optional stdenv.hostPlatform.isx86 nasm;
}
