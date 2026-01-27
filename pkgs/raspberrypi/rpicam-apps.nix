{ lib
, stdenv
, fetchFromGitHub
, meson
, ninja
, pkg-config
, boost
, libcamera
, libdrm
, libexif
, libjpeg
, libpng
, libtiff
, withLibavEncoder ? true
, ffmpeg
, withDrmPreview ? true
, withEglPreview ? true
, libepoxy
, libGL
, libX11
, withQtPreview ? true
, qt5
, withOpenCVPostProc ? true  #default=false
, opencv
, withIMX500 ? true  #default=false
, withRpiFeatures ? true
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rpicam-apps";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "rpicam-apps";
    rev = "v${finalAttrs.version}";
    hash = "sha256-3f0ThN4C9ZZ/6Is51Q6QA2tnEDnLKCLbxlCNqsGzw14=";
  };

  nativeBuildInputs = [
    meson ninja pkg-config
  ] ++ lib.optional withQtPreview qt5.wrapQtAppsHook;

  buildInputs = [
    boost
    libexif
    libcamera
    libdrm  # needed even with drm preview disabled
    libjpeg libpng libtiff
  ] ++ lib.optionals withLibavEncoder [ ffmpeg ]
    ++ lib.optionals withQtPreview (with qt5; [ qtbase qttools ])
    ++ lib.optionals withEglPreview [ libepoxy libX11 libGL ]
    ++ lib.optionals withOpenCVPostProc [ opencv ];

  # https://github.com/raspberrypi/rpicam-apps/blob/main/meson_options.txt
  mesonFlags = [
    (lib.mesonEnable "enable_libav" withLibavEncoder)
    # preview
    (lib.mesonEnable "enable_drm" withDrmPreview)
    (lib.mesonEnable "enable_egl" withEglPreview)
    (lib.mesonEnable "enable_qt" withQtPreview)
    # postprocessing
    (lib.mesonEnable "enable_opencv" withOpenCVPostProc)
    (lib.mesonEnable "enable_hailo" false) #default=auto, hailort (HailoRT)
    (lib.mesonBool "enable_imx500" withIMX500)
    (lib.mesonBool "disable_rpi_features" (!withRpiFeatures))
  ];

  meta = with lib; {
    description = "A small suite of libcamera-based applications to drive the cameras on a Raspberry Pi platform.";
    homepage = "https://github.com/raspberrypi/rpicam-apps";
    license = licenses.bsd2;
    platforms = [ "aarch64-linux" ];
  };
})