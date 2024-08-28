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
  version = "1.5.0";

  # https://github.com/raspberrypi/rpicam-apps/tree/v1.5.0
  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "rpicam-apps";
    rev = "v${finalAttrs.version}";
    hash = "sha256-s4zJh6r3VhiquO54KWZ78dVCH1BmlphY9zEB9BidNyo=";
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
    # preview
    (lib.mesonEnable "enable_drm" withDrmPreview)
    (lib.mesonEnable "enable_egl" withEglPreview)
    (lib.mesonEnable "enable_qt" withQtPreview)
    # postprocessing
    (lib.mesonEnable "enable_opencv" withOpenCVPostProc)
    "-Denable_hailo=disabled" #default=enabled, hailort (HailoRT)
  ];

  # Meson is no longer able to pick up Boost automatically.
  # https://github.com/NixOS/nixpkgs/issues/86131
  BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
  BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";

  meta = with lib; {
    description = "A small suite of libcamera-based applications to drive the cameras on a Raspberry Pi platform.";
    homepage = "https://github.com/raspberrypi/libcamera-apps";
    license = licenses.bsd2;
    platforms = [ "aarch64-linux" ];
  };
})