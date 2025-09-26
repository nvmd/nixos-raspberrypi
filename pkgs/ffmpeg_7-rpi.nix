{ lib, fetchFromGitHub
, callPackage
, ffmpeg
, ffmpegVariant ? "small"
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/tree/test/7.1.1/main
  ffmpegVersion = "7.1.1";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo  = "rpi-ffmpeg";
    # rev   = "test/${ffmpegVersion}/main"; # this branch is being forced-push to
    rev = "857f6c0ab47578dbd4153b4ed41eefbd488fd7fe";
    hash  = "sha256-8hb85ZwCaJBbJFaVBXNIZdxYfrHXs7TrpsunlaOTlwg=";
  };

in callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}