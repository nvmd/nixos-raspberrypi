{
  fetchFromGitHub,
  fetchpatch2,
  callPackage,
  ffmpeg,
  ffmpegVariant ? "small",
}:

let
  # https://github.com/jc-kynesim/rpi-ffmpeg/tree/test/8.0.1/main
  ffmpegVersion = "8.0.1";
  rpiFfmpegSrc = fetchFromGitHub {
    owner = "jc-kynesim";
    repo = "rpi-ffmpeg";
    # rev   = "test/${ffmpegVersion}/main"; # this branch is being forced-push to
    rev = "2a287060cc6e9024e0d20bc7f61da696546b553b";
    hash = "sha256-UPeq1ZM8BRtLaVu+GuGjo/BF5+N7qs3BkaeZNhp5hb0=";
  };

in
callPackage ./ffmpeg-rpi.nix {
  inherit ffmpeg;
  version = ffmpegVersion;
  source = rpiFfmpegSrc;
  inherit ffmpegVariant;

  excludePatches = [
    # rpi fork effectively already handles this change in lcevc_dec API v2/v4
    # via #ifdef LCEVC_DEC_VERSION_MAJOR
    "lcevcdec"
    # exclude to avoid double application when used with nixpkgs-unstable (which uses 8.0.1)
    "unbreak-hardcoded-tables"
  ];

  # this patch is already present in nixpkgs-unstable (8.0.1), but not on 25.11 (8.0)
  # fixes build failure https://code.ffmpeg.org/FFmpeg/FFmpeg/issues/21102
  extraPatches = [
    (fetchpatch2 {
      name = "unbreak-hardcoded-tables.patch";
      url = "https://git.ffmpeg.org/gitweb/ffmpeg.git/patch/1d47ae65bf6df91246cbe25c997b25947f7a4d1d";
      hash = "sha256-ulB5BujAkoRJ8VHou64Th3E94z6m+l6v9DpG7/9nYsM=";
    })
  ];
}
