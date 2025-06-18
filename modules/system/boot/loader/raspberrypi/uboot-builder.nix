{ pkgs
, ubootPackage
, ubootBinName ? "u-boot-rpi.bin"
, extlinuxConfBuilder
, firmwareBuilder
}:

pkgs.replaceVars ./uboot-builder.sh {
  inherit (pkgs) bash;
  path = [ pkgs.coreutils ];

  uboot = ubootPackage;
  inherit ubootBinName;
  inherit extlinuxConfBuilder;
  inherit firmwareBuilder;
}
