{ lib
, stdenv
, fetchFromGitHub
, meson
, ninja
, pkg-config
, boost
, ffmpeg
, libcamera
, libdrm
, libexif
, libjpeg
, libpng
, libtiff
, withDrmPreview ? true
, withEglPreview ? true
, libepoxy
, libGL
, libX11
, withQtPreview ? true
, qt5
, withOpenCVPostProc ? true  #default=false
, opencv
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rpicam-apps";
  version = "1.10.0";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "rpicam-apps";
    rev = "v${finalAttrs.version}";
    hash = "sha256-yyZlZSpYYt1DLAI7rW8lnpR6p9HnqcV6SrEJcAyS6Aw=";
  };

  nativeBuildInputs = [
    meson ninja pkg-config
  ] ++ lib.optional withQtPreview qt5.wrapQtAppsHook;

  buildInputs = [
    boost ffmpeg libexif libcamera
    libdrm  # needed even with drm preview disabled
    libjpeg libpng libtiff
  ] ++ lib.optionals withQtPreview (with qt5; [ qtbase qttools ])
    ++ lib.optionals withEglPreview [ libepoxy libX11 libGL ]
    ++ lib.optionals withOpenCVPostProc [ opencv ];

  mesonFlags = [
    # https://github.com/raspberrypi/rpicam-apps/blob/main/meson_options.txt
    # preview
    (lib.mesonEnable "enable_drm" withDrmPreview)
    (lib.mesonEnable "enable_egl" withEglPreview)
    (lib.mesonEnable "enable_qt" withQtPreview)
    # postprocessing
    (lib.mesonEnable "enable_opencv" withOpenCVPostProc)
    "-Denable_hailo=disabled" #default=enabled, hailort (HailoRT)
    # explicitly disable, fails with:
    # FAILED: post_processing_stages/imx500/imx500-models
    # /bin/sh: /build/source/utils/download-imx500-models.sh: not found
    # Shouldn't it have been implicitly disabled
    # because wrap_mode=nodownload?
    "-Ddownload_imx500_models=false" #default=true
  ];

  meta = with lib; {
    description = "A small suite of libcamera-based applications to drive the cameras on a Raspberry Pi platform.";
    homepage = "https://github.com/raspberrypi/rpicam-apps";
    license = licenses.bsd2;
    platforms = [ "aarch64-linux" ];
  };
})