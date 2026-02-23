{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  bash,
  gnugrep,
  coreutils,
  withCpuGovernorConfig ? false,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "raspberrypi-udev-rules";
  version = "20260202";

  # https://github.com/RPi-Distro/raspberrypi-sys-mods/tree/pios/trixie
  src = fetchFromGitHub {
    owner = "RPi-Distro";
    repo = "raspberrypi-sys-mods";
    rev = "49b5eb5aa5038b468e4bc077cfa433630a895ea2";
    hash = "sha256-Yp0gey6FbFHDaZEQBNGDwZ4rhF7l9xgj/Cg/9h5PXkY=";
  };

  installPhase = ''
    mkdir -p $out/lib/udev/rules.d
    mkdir -p $out/lib/tmpfiles.d

    # Note: Installing only explicitly listed rules

    rules_usr_lib_src=usr/lib/udev/rules.d
    declare -a rules_usr_lib=(
      10-vc.rules

      # Disabled: requires the i2cprobe helper script with NixOS path fixes.
      # Likely unnecessary - modern kernels handle I2C/SPI module loading natively.
      # 15-i2c-modprobe.rules

      60-backlight.rules
      60-dma-heap.rules
      # Symlinks gpiochip0 to gpiochip4 for Pi 5 userspace compat (e.g. gpiozero).
      # 60-gpiochip4.rules
      60-i2c-aliases.rules
      ${if withCpuGovernorConfig then "60-ondemand-governor.rules" else ""}
      60-piolib.rules
      61-drm.rules
      70-microbit.rules

      # Hides a NOOBS "SETTINGS" ext4 partition from UDisks.
      # NOOBS was discontinued in 2020 and NixOS was never installed via it.
      # 80-noobs.rules

      99-com.rules
    )

    tmpfiles_usr_lib_src=usr/lib/tmpfiles.d
    declare -a tmpfiles_usr_lib=(
      ${if withCpuGovernorConfig then "raspberrypi-sys-mods-ondemand-governor.conf" else ""}
      sys-kernel-debug.conf
    )

    for i in "''${rules_usr_lib[@]}"; do
      install -vD "$rules_usr_lib_src/$i" $out/lib/udev/rules.d
    done

    for i in "''${tmpfiles_usr_lib[@]}"; do
      install -vD "$tmpfiles_usr_lib_src/$i" $out/lib/tmpfiles.d
    done
  '';

  postFixup = ''
    for i in $out/lib/udev/rules.d/*.rules; do
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
