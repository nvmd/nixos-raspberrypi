{ pkgs, configTxt
, ubootPackage
, ubootBinName ? "u-boot-rpi.bin"
, firmware ? pkgs.raspberrypifw
, extlinuxConfBuilder
, firmwareBuilder
}:

pkgs.substituteAll {
  src = ./uboot-builder.sh;
  isExecutable = true;
  inherit (pkgs) bash;
  path = [pkgs.coreutils pkgs.gnused pkgs.gnugrep];

  uboot = ubootPackage;
  inherit ubootBinName;
  inherit firmware configTxt;
  inherit extlinuxConfBuilder;
  inherit firmwareBuilder;
}