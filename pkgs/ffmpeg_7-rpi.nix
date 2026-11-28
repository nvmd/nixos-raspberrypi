{
  lib,
  fetchFromGitHub,
  callPackage,
  ffmpeg,
  ffmpegVariant ? "small",
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/tree/test/7.1.5/main
  ffmpegVersion = "7.1.5";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo = "rpi-ffmpeg";
    # rev   = "test/${ffmpegVersion}/main"; # this branch is being forced-push to
    rev = "950ab0323334111e1a4cdc6b037eadfaf0524167";
    hash = "sha256-lPsx9TnSsEkmN+E0OcOrvPkseXY7xFUEtOP3EJiP9B0=";
  };

in
callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}
