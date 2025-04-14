{ pkgs
, ubootPackage
, ubootBinName ? "u-boot-rpi.bin"
, extlinuxConfBuilder
, firmwareBuilder
}:

pkgs.substituteAll {
  src = ./uboot-builder.sh;
  isExecutable = true;

  inherit (pkgs) bash;
  path = [ pkgs.coreutils ];

  uboot = ubootPackage;
  inherit ubootBinName;
  inherit extlinuxConfBuilder;
  inherit firmwareBuilder;
}