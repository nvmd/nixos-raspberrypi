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
