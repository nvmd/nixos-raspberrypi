{
  lib,
  fetchFromGitHub,
  ffmpeg,
  libepoxy, # for vout_egl
  withV4l2Request ? true,
  udev,
  systemd, # v4l2-request
  # disabled because i can't solve libepoxy not being found by ffmpeg confgure script
  withVoutEgl ? false,
  withVoutDrm ? true,
  version ? null,
  source ? null,
  ffmpegVariant ? "small",
}:

let
  extraVersion = "rpi";

in
(ffmpeg.overrideAttrs (old: {
  pname = old.pname + "-rpi";

  doCheck = false; # disabled because `imgutils` test fails

  # see also
  # https://github.com/jc-kynesim/rpi-ffmpeg/blob/release/4.4/rpi_import_1/pi-util/conf_native.sh#L85
  configureFlags =
    old.configureFlags
    ++ [
      "--extra-version=${extraVersion}"
      "--enable-logging"
      "--enable-asm"
    ]
    ++ [
      "--disable-mmal"
      "--enable-neon"
    ]
    ++ [
      "--enable-sand"
    ]
    ++ lib.optionals withVoutEgl [
      "--enable-epoxy"
      "--enable-vout-egl" # rpi
    ]
    ++ lib.optionals withVoutDrm [
      # when withV4l2
      "--enable-vout-drm" # rpi
    ]
    ++ lib.optionals withV4l2Request [
      "--enable-v4l2-request"
      "--enable-libudev"
    ];
  buildInputs =
    old.buildInputs
    ++ lib.optionals withVoutEgl [
      libepoxy.dev
    ]
    ++ lib.optionals withV4l2Request [
      udev
      systemd
    ];
})).override
  {
    inherit version source;
    hash = source.hash;

    # version = ffmpegVersion + "-rpi";
    # source = rpiFfmpegSrc;
    # hash = rpiFfmpegSrc.hash;
    inherit ffmpegVariant;

    withStripping = true;

    withDocumentation = false;
    withHtmlDoc = false;
    withManPages = false;

    # withV4l2 = true;  # default on linux
    # withDrm = true;   # default on linux
    withXlib = withVoutEgl; # for libepoxy

    withVaapi = false;
    # !!! keep this enabled, because some applications may need it
    # for example, vlc 3.0.20: fails with 'undefined reference to
    # `av_vdpau_get_surface_parameters'' otherwise
    withVdpau = true;
  }

# > configure flags: --disable-static --prefix=/nix/store/hksqdxfkpspl4bqhvzq88v46c5zlf1c9-ffmpeg-4.4-rpi --target_os=linux --arch=aarch64 --pkg-config=pkg-config --enable-gpl --enable-version3 --disable-nonfree --disable-static --enable-shared --enable-pic --disable-thumb --disable-small --enable-runtime-cpudetect --disable-gray --enable-swscale-alpha --enable-hardcoded-tables --enable-safe-bitstream-reader --enable-pthreads --disable-w32threads --disable-os2threads --enable-network --enable-pixelutils --datadir=/nix/store/k9hkfl02wlmms2czv8a56c3sfk0c1947-ffmpeg-4.4-rpi-data/share/ffmpeg --enable-ffmpeg --enable-ffplay --enable-ffprobe --bindir=/nix/store/xmgl25z6yh1166ykgf3srqhihdzx45ng-ffmpeg-4.4-rpi-bin/bin --enable-avcodec --enable-avdevice --enable-avfilter --enable-avformat --enable-avresample --enable-avutil --enable-postproc --enable-swresample --enable-swscale --libdir=/nix/store/sgxz7wifxfi3yk2706fjfn1ja418lz4l-ffmpeg-4.4-rpi-lib/lib --incdir=/nix/store/4i8zcixbngr553ajfsg7qxasy372j18s-ffmpeg-4.4-rpi-dev/include --disable-doc --disable-htmlpages --disable-manpages --enable-podpages --enable-txtpages --enable-alsa --disable-libaom --enable-libass --disable-libbluray --disable-libbs2b --enable-bzlib --disable-libcaca --disable-libcelt --disable-chromaprint --disable-cuda --disable-cuda-llvm --enable-libdav1d --disable-libdc1394 --enable-libdrm --disable-libfdk-aac --disable-libflite --enable-fontconfig --enable-libfontconfig --enable-libfreetype --disable-frei0r --disable-libfribidi --disable-libgme --enable-gnutls --disable-libgsm --enable-iconv --disable-libjack --disable-ladspa --enable-lzma --disable-libmfx --disable-libmodplug --enable-libmp3lame --disable-libmysofa --enable-cuvid --enable-nvdec --enable-nvenc --disable-openal --disable-opencl --disable-libopencore-amrnb --disable-libopencore-amrwb --disable-opengl --disable-libopenh264 --disable-libopenjpeg --disable-libopenmpt --enable-libopus --enable-libpulse --disable-librav1e --disable-librtmp --disable-libsmbclient --enable-sdl2 --enable-libsoxr --enable-libspeex --enable-libsrt --enable-libssh --disable-librsvg --disable-libsvtav1 --disable-libtensorflow --enable-libtheora --enable-libv4l2 --enable-v4l2-m2m --disable-vaapi --disable-vdpau --disable-libvidstab --disable-libvmaf --disable-libvo-amrwbenc --enable-libvorbis --enable-libvpx --enable-vulkan --disable-libwebp --enable-libx264 --enable-libx265 --disable-libxavs --disable-libxcb --disable-libxcb-shape --disable-libxcb-shm --disable-libxcb-xfixes --enable-xlib --disable-libxml2 --enable-libxvid --enable-libzimg --enable-zlib --disable-libzmq --disable-debug --enable-optimizations --disable-extra-warnings --enable-stripping --extra-version=rpi --enable-logging --enable-asm --disable-mmal --enable-neon --disable-thumb --enable-sand --enable-epoxy --enable-vout-egl --enable-vout-drm --enable-v4l2-request --enable-libudev
# > ERROR: v4l2-request requires libudev
