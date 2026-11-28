{
  fetchFromGitHub,
  callPackage,
  ffmpeg,
  ffmpegVariant ? "small",
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/tree/test/8.1.2/main
  ffmpegVersion = "8.1.2";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo = "rpi-ffmpeg";
    # rev   = "test/${ffmpegVersion}/main"; # this branch is being forced-push to
    rev = "f60aae17021abae85b1ba9759e8b2da33f723902";
    hash = "sha256-mPcARTkZAAljvmsahC/HTe5eK+E1brbEGb2Q1X37egg=";
  };

in
callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}
