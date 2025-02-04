{ lib, fetchFromGitHub
, callPackage
, ffmpeg
, ffmpegVariant ? "small"
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/tree/test/7.1/main
  ffmpegVersion = "7.1";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo  = "rpi-ffmpeg";
    # rev   = "test/${ffmpegVersion}/main"; # this branch is being forced-push to
    rev = "024838d04594c4acff3f8bc79fe885482dea8121";
    hash  = "sha256-Lt/4eeW1f84ysCNp/5HG7qTLNnyEuKuMUBY/PW+REqc=";
  };

in callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}