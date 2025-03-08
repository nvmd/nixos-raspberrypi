{ lib, fetchFromGitHub
, callPackage
, ffmpeg
, ffmpegVariant ? "small"
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/commits/dev/6.1.1/rpi_import_1/
  # ffmpegVersion = "6.1.1";
  # rpiFfmpegSrc = fetchFromGitHub {
  #   owner = "jc-kynesim";
  #   repo  = "rpi-ffmpeg";
  #   rev   = "dev/${ffmpegVersion}/rpi_import_1";
  #   hash  = "sha256-A5+aGmYijEH+GPRCHpGpK742Bvu/cT6R2ZezIE8S6h4=";
  #   # hash  = lib.fakeHash;
  # };
  # https://github.com/jc-kynesim/rpi-ffmpeg/commits/test/6.0.1/main
  ffmpegVersion = "6.0.1";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo  = "rpi-ffmpeg";
    # rev   = "test/${ffmpegVersion}/main";
    rev   = "a4f8d3f69e97de0a0005a06ad76063e0a52fd7f5";
    hash  = "sha256-wmj2WyJ9Tywiv4SB0Jgov/p5Hn2j3sAN8yvgCPOTCKg=";
    # hash  = lib.fakeHash;
  };
  # see also for configure flags
  # https://github.com/jc-kynesim/rpi-ffmpeg/blob/test/6.0.1/main/pi-util/conf_native.sh#L110

in callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}