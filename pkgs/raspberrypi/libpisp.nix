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
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "libpisp";
    rev = "v${finalAttrs.version}";
    hash = "sha256-YshU7G5Rov67CVwFbf5ENp2j5ptAvkVrlMu85KmnEpk=";
  };

  nativeBuildInputs = [ pkg-config meson ninja ];
  buildInputs = [ nlohmann_json boost ];

  meta = with lib; {
    description = "Helper library to generate run-time configuration for the Raspberry Pi ISP (PiSP)";
    homepage = "https://github.com/raspberrypi/libpisp";
    license = licenses.bsd2;
    maintainers = with maintainers; [ kazenyuk ];
  };
})