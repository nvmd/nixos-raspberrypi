{ lib, fetchFromGitHub
, callPackage
, ffmpeg
, ffmpegVariant ? "small"
}:

let
  # there are, in the order of latest changes:
  # * https://github.com/jc-kynesim/rpi-ffmpeg/commits/release/5.1/main
  # * https://github.com/jc-kynesim/rpi-ffmpeg/commits/test/5.1.6/main
  ffmpegVersion = "5.1.6";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo  = "rpi-ffmpeg";
    rev   = "test/${ffmpegVersion}/main";
    # rev   = "release/${ffmpegVersion}/main";
    hash  = "sha256-AzUzmTrFjI7UWU5vOvnXKpwuLij+AUN1i59RlsmuAGI=";
  };
in callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}