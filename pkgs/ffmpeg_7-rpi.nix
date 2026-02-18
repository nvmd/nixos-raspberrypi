{
  lib,
  fetchFromGitHub,
  callPackage,
  ffmpeg,
  ffmpegVariant ? "small",
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/tree/test/7.1.2/main
  ffmpegVersion = "7.1.2";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo = "rpi-ffmpeg";
    # rev   = "test/${ffmpegVersion}/main"; # this branch is being forced-push to
    rev = "de943d66dab18e89fc10c74459bea1d787edc49d";
    hash = "sha256-Qbgos7uzYXF5E557kR2EXhX9eJRmO0LVmSE2NOpEZY0=";
  };

in
callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}
