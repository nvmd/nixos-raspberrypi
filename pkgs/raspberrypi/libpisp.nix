{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, meson
, ninja
, nlohmann_json
, boost
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libpisp";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "libpisp";
    rev = "v${finalAttrs.version}";
    hash = "sha256-tHfFcNSmXLcUHhqiGRh2YZT8xioUq0zMOMZl9rjG8ys=";
  };

  nativeBuildInputs = [ pkg-config meson ninja ];
  buildInputs = [ nlohmann_json boost ];
  # Meson is no longer able to pick up Boost automatically.
  # https://github.com/NixOS/nixpkgs/issues/86131
  BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
  BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";

  meta = with lib; {
    description = "Helper library to generate run-time configuration for the Raspberry Pi ISP (PiSP)";
    homepage = "https://github.com/raspberrypi/libpisp";
    license = licenses.bsd2;
    maintainers = with maintainers; [ kazenyuk ];
  };
})