{ lib
, stdenvNoCC
, fetchFromGitHub
, bash
, gnugrep
, coreutils
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "raspberrypi-udev-rules";
  version = "20250423";

  # https://github.com/RPi-Distro/raspberrypi-sys-mods/tree/bookworm/
  src = fetchFromGitHub {
    owner = "RPi-Distro";
    repo = "raspberrypi-sys-mods";
    rev = "9921bca8dfb37b88c1cc6578753d707bc4a1917f";
    hash = "sha256-v3dc8ffTD8jc9L8X0aTehK5E68VV7zpC+v8A/COr9K4=";
  };

  installPhase = ''
    mkdir -p $out/etc/udev/rules.d
    mkdir -p $out/lib/udev/rules.d
    mkdir -p $out/lib/tmpfiles.d

    # Note: Installing only explicitly listed rules

    rules_etc_src=etc.armhf/udev/rules.d
    declare -a rules_etc=(
      99-com.rules
    )

    rules_lib_src=lib/udev/rules.d
    declare -a rules_lib=(
      10-vc.rules

      # disable until i know what to do with /usr/lib/raspberrypi-sys-mods/i2cprobe
      # is it even still needed?
      # 15-i2c-modprobe.rules

      60-backlight.rules
      60-dma-heap.rules
      60-gpiochip4.rules
      60-i2c-aliases.rules
      60-pico.rules
      60-piolib.rules
      61-drm.rules
      70-microbit.rules

      # doesn't seem to provide any value on nixos
      # 80-noobs.rules
    )

    rules_usr_lib_src=usr/lib/udev/rules.d
    declare -a rules_usr_lib=(
      60-ondemand-governor.rules
    )

    for i in "''${rules_etc[@]}"; do
      install -vD "$rules_etc_src/$i" $out/etc/udev/rules.d
    done
    for i in "''${rules_lib[@]}"; do
      install -vD "$rules_lib_src/$i" $out/lib/udev/rules.d
    done
    for i in "''${rules_usr_lib[@]}"; do
      install -vD "$rules_usr_lib_src/$i" $out/lib/udev/rules.d
    done

    install -vD "usr/lib/tmpfiles.d/raspberrypi-sys-mods-ondemand-governor.conf" $out/lib/tmpfiles.d
  '';

  fixupPhase = ''
    for i in $out/{etc,lib}/udev/rules.d/*.rules; do
      substituteInPlace $i \
        --replace-quiet \"/bin/sh \"${bash}/bin/sh \
        --replace-quiet \"/bin/grep \"${lib.getExe gnugrep} \
        --replace-quiet \"/bin/chgrp \"${coreutils}/bin/chgrp \
        --replace-quiet \"/bin/chmod \"${coreutils}/bin/chmod \
        --replace-quiet /usr/bin/test ${coreutils}/bin/test
    done
  '';

  meta = with lib; {
    description = "A collection of Raspberry Pi-sourced system configuration files and associated scripts";
    homepage = "https://github.com/RPi-Distro/raspberrypi-sys-mods/";
    # https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/master/debian/copyright
    license = licenses.bsd3;
    platforms = platforms.all;
    # buildable by all, but will make sense only on these, obviously
    # platforms = [ "aarch64-linux" "armv7l-linux" "armv6l-linux" ];
  };
})