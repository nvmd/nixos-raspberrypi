{ lib
, stdenvNoCC
, fetchFromGitHub
, bash
, gnugrep
, coreutils
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "raspberrypi-udev-rules";
  version = "20240911";

  # https://github.com/RPi-Distro/raspberrypi-sys-mods/tree/bookworm/
  src = fetchFromGitHub {
    owner = "RPi-Distro";
    repo = "raspberrypi-sys-mods";
    rev = "22b66366ef9bdcdc83de5be883931b7af9c55904";
    hash = "sha256-an8oS62KJZyyU6jTnnoGW5WOm3UD4JZ/leR4jyeIlU8=";
  };

  installPhase = ''
    mkdir -p $out/etc/udev/rules.d
    mkdir -p $out/lib/udev/rules.d

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
      60-pico.rules
      70-microbit.rules

      # doesn't seem to provide any value on nixos
      # 80-noobs.rules
    )

    for i in "''${rules_lib[@]}"; do
      install -vD "$rules_lib_src/$i" $out/lib/udev/rules.d
    done
    for i in "''${rules_etc[@]}"; do
      install -vD "$rules_etc_src/$i" $out/etc/udev/rules.d
    done
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