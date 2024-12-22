{ lib, fetchFromGitHub
, callPackage
, ffmpeg
, ffmpegVariant ? "small"
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/tree/dev/7.0/rpi_import_1
  ffmpegVersion = "7.1";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo  = "rpi-ffmpeg";
    rev   = "test/${ffmpegVersion}/main";
    hash  = "sha256-PIoN38zD6OHuEEuH/Pma3hLzMppl0lX3voX8K/G+drs=";
  };

in callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}