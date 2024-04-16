{ lib, fetchFromGitHub
, callPackage
, ffmpeg
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/commits/dev/6.1.1/rpi_import_1/
  ffmpegVersion = "6.1.1";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo  = "rpi-ffmpeg";
    rev   = "dev/${ffmpegVersion}/rpi_import_1";
    hash  = "sha256-lTcX0C5PdKWch4nB+TCH51IIjvbSrsyyurGonYR8EFU=";
    # hash  = lib.fakeHash;
  };
  # https://github.com/jc-kynesim/rpi-ffmpeg/commits/test/6.0.1/main
  # ffmpegVersion = "6.0.1";
  # rpiFfmpegSrc = fetchFromGitHub {
  #   owner = "jc-kynesim";
  #   repo  = "rpi-ffmpeg";
  #   rev   = "test/${ffmpegVersion}/main";
  #   hash  = "sha256-DvtFmWQcXB/5l3g52uJGBU9GtzRgzF/RDJP3LR5yU5c=";
  # };
  # see also for configure flags
  # https://github.com/jc-kynesim/rpi-ffmpeg/blob/test/6.0.1/main/pi-util/conf_native.sh#L110

in (callPackage ./ffmpeg_4-rpi.nix {}).override {
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
}