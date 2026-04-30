{ lib
, stdenvNoCC
, fetchFromGitHub
, makeWrapper
, coreutils
, gawk
, gnugrep
, gnused
, which
, xxd
, libraspberrypi
,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rpi-otp-private-key";
  version = "2025.12.08-2712";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "rpi-eeprom";
    rev = "v${finalAttrs.version}";
    hash = "sha256-WByNvK115PbIJFMkZ4TYjU4QdNkyMrswAWcMlPIw2h4=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 tools/rpi-otp-private-key \
      $out/bin/rpi-otp-private-key

    patchShebangs $out/bin/rpi-otp-private-key

    wrapProgram $out/bin/rpi-otp-private-key \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          gawk
          gnugrep
          gnused
          which
          xxd
          libraspberrypi
        ]
      }

    runHook postInstall
  '';

  meta = with lib; {
    description = "Read or program the Raspberry Pi OTP private key";
    homepage = "https://github.com/raspberrypi/rpi-eeprom";
    license = licenses.bsd3;
    mainProgram = "rpi-otp-private-key";
    platforms = [ "armv6l-linux" "armv7l-linux" "aarch64-linux" ];
  };
})
