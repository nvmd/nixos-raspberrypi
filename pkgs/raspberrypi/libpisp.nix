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
  version = "1.0.5";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "libpisp";
    rev = "v${finalAttrs.version}";
    hash = "sha256-CHd44CH5dBcZuK+5fZtONZ8HE/lwGKwK5U0BYUK8gG4=";
  };

  nativeBuildInputs = [ pkg-config meson ninja ];
  buildInputs = [ nlohmann_json boost ];
  # Meson is no longer able to pick up Boost automatically.
  # https://github.com/NixOS/nixpkgs/issues/86131
  BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
  BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";
})