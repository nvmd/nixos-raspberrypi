{ lib, fetchFromGitHub
, callPackage
, ffmpeg
, ffmpegVariant ? "small"
}:

let
  # there are, in the order of latest changes:
  # * https://github.com/jc-kynesim/rpi-ffmpeg/commits/release/5.1/main
  # * https://github.com/jc-kynesim/rpi-ffmpeg/commits/pi/5.1.4/rpi_23
  # * https://github.com/jc-kynesim/rpi-ffmpeg/commits/test/5.1.4/main
  ffmpegVersion = "5.1.4";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo  = "rpi-ffmpeg";
    rev   = "test/${ffmpegVersion}/main";
    # hash  = "sha256-lTcX0C5PdKWch4nB+TCH51IIjvbSrsyyurGonYR8EFU=";
    hash  = lib.fakeHash;
  };
in callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}