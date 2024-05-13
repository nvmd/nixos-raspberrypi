self: super: { # final: prev:

  # libcec = self.libcec-rpi;

  # some packages depend on versioned naming, some on simple `ffmpeg`
  # for example retroarchBare – ffmpeg_4
  #             kodi – ffmpeg (even though current version needs _6)

  ffmpeg_4 = self.ffmpeg_4-rpi; # small
  ffmpeg_4-headless = self.ffmpeg_4-rpi.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_4-full = self.ffmpeg_4-rpi.override {
    ffmpegVariant = "full";
  };

  ffmpeg_5 = self.ffmpeg_5-rpi; # small
  ffmpeg_5-headless = self.ffmpeg_5-rpi.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_5-full = self.ffmpeg_5-rpi.override {
    ffmpegVariant = "full";
  };
  
  ffmpeg_6 = self.ffmpeg_6-rpi; # small
  ffmpeg_6-headless = self.ffmpeg_6-rpi.override {
    ffmpegVariant = "headless";
  };
  ffmpeg_6-full = self.ffmpeg_6-rpi.override {
    ffmpegVariant = "full";
  };

  # as in `...ffmpeg/default.nix`
  # need to override those because as well, because there
  # those definitions are recursively local
  ffmpeg = self.ffmpeg_6; # chromaprint
  ffmpeg-headless = self.ffmpeg_6-headless; # python3.11-matplotlib
  ffmpeg-full = self.ffmpeg_6-full;
}