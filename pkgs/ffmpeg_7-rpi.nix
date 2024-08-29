{ lib, fetchFromGitHub
, callPackage
, ffmpeg
, ffmpegVariant ? "small"
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/tree/dev/7.0/rpi_import_1
  ffmpegVersion = "7.0";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo  = "rpi-ffmpeg";
    rev   = "dev/${ffmpegVersion}/rpi_import_1";
    hash  = "sha256-3t4FmFFi8eH8V196SkZ/mpopQtfxaasFPQ+GRuW/NBs=";
  };

in callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}