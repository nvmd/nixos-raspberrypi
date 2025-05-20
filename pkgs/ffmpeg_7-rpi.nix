{ lib, fetchFromGitHub
, callPackage
, ffmpeg
, ffmpegVariant ? "small"
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/tree/test/7.1/main
  ffmpegVersion = "7.1.1";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo  = "rpi-ffmpeg";
    # rev   = "test/${ffmpegVersion}/main"; # this branch is being forced-push to
    rev = "6dbf87aefd7f491210abe1e043a1c228fa1439a0";
    hash  = "sha256-cLDfw1lyZTny39OfW+dvZaTkZz3zkNdEpvPh1dgHJ2I=";
  };

in callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}