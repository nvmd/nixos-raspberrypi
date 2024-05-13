self: super: { # final: prev:

  libcec = super.libcec.override {
    withLibraspberrypi = true;
  };

  # don't enable just yet because kodi-20-rpi-gbm still depends on older
  # nix kodi infrastructure present with version 20,
  # but self.master.pkgs.kodi is already 21 with "composable" PR merged
  # so ffmpeg won't override
  # kodi = self.kodi-rpi;
  # kodi-gbm = self.kodi-rpi-gbm;
  # kodi-wayland = self.kodi-rpi-wayland;

  kodi-rpi-gbm = self.kodi-rpi.override {
    gbmSupport = true;
  };
  kodi-rpi-wayland = self.kodi-rpi.override {
    waylandSupport = true;
  };

  kodi-rpi = (self.unstable.pkgs.kodi.overrideAttrs (old: {
    pname = "kodi-rpi";
    buildInputs = old.buildInputs ++ [ self.dav1d ];
    cmakeFlags = let
      enableFeature = enable: feature:
        assert (super.lib.isString feature); # e.g. passing OPENSSL instead of "OPENSSL"
        "-DENABLE_${feature}=${if enable then "ON" else "OFF"}";
    in old.cmakeFlags ++ [
      "-DENABLE_INTERNAL_DAV1D=OFF"
    ] ++ [ # libreelec hardcoded
      # leaving because this is probably here due to performance considerations
      "-DENABLE_LCMS2=OFF"
    ] ++ [
      (enableFeature true  "NEON")
      (enableFeature false "VAAPI")
    ] ++ [
      "-DENABLE_CEC=ON"
      "-DENABLE_AVAHI=ON"
      #-DAPP_RENDER_SYSTEM=
    ];
  })).override {
    # needs to be set explicitly, won't be pulled from scope automagically
    # inherit (self) ffmpeg;
    ffmpeg = self.ffmpeg_6-rpi;
    vdpauSupport = false;
  };


  ffmpeg_4-rpi = (super.callPackage ../../pkgs/ffmpeg_4-rpi.nix {
    ffmpeg = super.ffmpeg_4;
  });
  ffmpeg_5-rpi = (super.callPackage ../../pkgs/ffmpeg_5-rpi.nix {
    ffmpeg = super.ffmpeg_4;
  });
  ffmpeg_6-rpi = (super.callPackage ../../pkgs/ffmpeg_6-rpi.nix {
    ffmpeg = super.ffmpeg_6;
  });


  # an attempt for `nixpkgs` with RPi4-specific compiler optimizations
  # enabled for all packages
  pkgs-rpi4 = import super {
    # pass the nixpkgs config to the unstable alias
    # to ensure `allowUnfreePredicate` is propagated
    config = super.config.nixpkgs.config;
    localSystem = {
      gcc = {
        # why not just `cpu` for apple m1?
        # for forward compatibility, i guess.
        # so cached binaries could work on everything apple silicon (≥m1)...
        # but are those flags correct?
        # a13 – is it the correct flag?
        # a13 is also armv8.4, but m1,m2 are armv8.5...
        # arch = "armv8.3-a+crypto+sha2+aes+crc+fp16+lse+simd+ras+rdm+rcpc";
        # cpu = "apple-a13";

        # tune for both architecture and microarchitecture
        # Many of the supported CPUs implement optional architectural extensions.
        # Where this is so the architectural extensions are normally enabled by default.
        # +crypto is listed separately, so i guess isn't enabled by default,
        # because crypto extension is not enabled in `base` model cpu
        # see note https://developer.arm.com/documentation/100095/0003/Programmers-Model/About-the-programmers-model?lang=en
        # see also https://gist.github.com/fm4dd/c663217935dc17f0fc73c9c81b0aa845#note-to-crypto-miners
        # no crypto extension in rpi4's BCM2835, also BCM2711 and others:
        # https://forums.raspberrypi.com/viewtopic.php?t=243410&start=25#p1705544
        # cat /proc/cpuinfo
        cpu = "cortex-a72";

        # `-march` and `-mtune` override `-mcpu` on ARM
        # arch = "armv8-a";
        # the supported extensions for architecture:
        # +crc    | The Cyclic Redundancy Check (CRC) instructions
        #         | Y, src: https://www.valvers.com/open-software/raspberry-pi/bare-metal-programming-in-c-part-1/
        #              not clear, did find in arm's docs
        # +simd   | The ARMv8-A Advanced SIMD and floating-point instructions
        #         | Y, src: https://developer.arm.com/documentation/100095/0003/Programmers-Model/About-the-programmers-model?lang=en
        # +crypto | The cryptographic instructions
        #         | Y, src: https://gist.github.com/fm4dd/c663217935dc17f0fc73c9c81b0aa845
        #         |         https://developer.arm.com/documentation/100095/0003/Programmers-Model/About-the-programmers-model?lang=en
        #                     (if RPi has it)
        # ... some other i don't need
        # tune = "...";
      };
      inherit (super) system;
    };
  };
}