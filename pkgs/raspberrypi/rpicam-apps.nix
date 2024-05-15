{ lib
, stdenv
, fetchFromGitHub
, meson
, pkg-config
, libjpeg
, libtiff
, libpng
, libcamera
, libepoxy
, boost
, libexif
, ninja
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rpicam-apps";
  version = "1.4.4";

  # https://github.com/raspberrypi/rpicam-apps/tree/v1.4.4
  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "rpicam-apps";
    rev = "v${finalAttrs.version}";
    hash = "sha256-uoewZMGf3vsBoRDfRz8KBKl+J6st/J44SHvNRMBdaUI=";
  };

  nativeBuildInputs = [ meson pkg-config ];
  buildInputs = [ libjpeg libtiff libcamera libepoxy boost libexif libpng ninja ];
  mesonFlags = [
    "-Denable_qt=false"
    "-Denable_opencv=false"
    "-Denable_tflite=false"
    "-Denable_drm=true"
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