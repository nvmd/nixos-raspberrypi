{
  lib,
  fetchFromGitHub,
  callPackage,
  ffmpeg,
  ffmpegVariant ? "small",
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/releases/tag/n8.0
  ffmpegVersion = "8.0";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo = "rpi-ffmpeg";
    rev = "n${ffmpegVersion}";
    hash = "sha256-okNZ1/m/thFAY3jK/GSV0+WZFnjrMr8uBPsOdH6Wq9E=";
  };

in
callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}
