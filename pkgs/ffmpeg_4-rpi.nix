{
  lib,
  fetchFromGitHub,
  callPackage,
  ffmpeg,
  ffmpegVariant ? "small",
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/commits/release/4.4/rpi_import_1/
  ffmpegVersion = "4.4";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo = "rpi-ffmpeg";
    rev = "release/${ffmpegVersion}/rpi_import_1";
    hash = "sha256-n+0/S51WrogVkrpmngDRw/0EC46OsTIxegyrw6S+Xbk=";
  };

in
callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;
}
