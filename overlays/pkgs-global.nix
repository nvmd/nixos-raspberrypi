self: super: { # final: prev:

  # libcec = super.libcec-rpi;

  kodi = super.kodi-rpi;
  kodi-gbm = super.kodi-rpi-gbm;
  kodi-wayland = super.kodi-rpi-wayland;

  # some packages depend on versioned naming, some on simple `ffmpeg`
  # for example retroarchBare – ffmpeg_4
  #             kodi – ffmpeg (even though current version needs _6)

  ffmpeg_4 = super.ffmpeg_4-rpi; # small
  ffmpeg_4-headless = super.ffmpeg_4-rpi.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_4-full = super.ffmpeg_4-rpi.override {
    ffmpegVariant = "full";
  };

  ffmpeg_5 = super.ffmpeg_5-rpi; # small
  ffmpeg_5-headless = super.ffmpeg_5-rpi.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_5-full = super.ffmpeg_5-rpi.override {
    ffmpegVariant = "full";
  };
  
  ffmpeg_6 = super.ffmpeg_6-rpi; # small
  ffmpeg_6-headless = super.ffmpeg_6-rpi.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_6-full = super.ffmpeg_6-rpi.override {
    ffmpegVariant = "full";
  };

  # ffmpeg_7 = super.ffmpeg_7-rpi; # small
  # ffmpeg_7-headless = super.ffmpeg_7-rpi.override {
  #   ffmpegVariant = "headless";
  # };
  # ffmpeg_7-full = super.ffmpeg_7-rpi.override {
  #   ffmpegVariant = "full";
  # };

  # as in `...ffmpeg/default.nix`
  # need to override those because as well, because there
  # those definitions are recursively local
  ffmpeg = self.ffmpeg_6; # chromaprint
  ffmpeg-headless = self.ffmpeg_6-headless; # python3.11-matplotlib
  ffmpeg-full = self.ffmpeg_6-full;

  vlc = self.vlc-rpi;

  SDL2 = self.SDL2-rpi;

  # libcamera = self.libcamera-rpi;
}