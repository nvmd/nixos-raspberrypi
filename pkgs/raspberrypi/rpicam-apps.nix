{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, meson
, ninja
, boost
, ffmpeg
, libcamera
, libdrm
, libexif
, libjpeg
, libpng
, libtiff
, withDrmPreview ? true #default=true
, withEglPreview ? true #default=true
, libepoxy
, libGL
, libX11
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

  nativeBuildInputs = [ pkg-config meson ninja ];
  buildInputs = [
    boost ffmpeg libexif libcamera
    libdrm  # needed even with drm preview disabled
    libjpeg libpng libtiff
  ] ++ lib.optionals withEglPreview [ libepoxy libX11 libGL ]
    ++ lib.optionals withOpenCVPostProc [ opencv ];
  mesonFlags = [
    # preview
    "${lib.mesonEnable "enable_drm" withDrmPreview}"
    "${lib.mesonEnable "enable_egl" withEglPreview}"
    "-Denable_qt=disabled"  #default=enabled
    # postprocessing
    "${lib.mesonEnable "enable_opencv" withOpenCVPostProc}"
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