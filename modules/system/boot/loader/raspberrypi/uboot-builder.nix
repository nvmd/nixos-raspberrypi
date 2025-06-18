{ pkgs
, ubootPackage
, ubootBinName ? "u-boot-rpi.bin"
, extlinuxConfBuilder
, firmwareBuilder
}:

pkgs.replaceVarsWith {
  src = ./uboot-builder.sh;
  isExecutable = true;

  replacements = {
    inherit (pkgs) bash;
    path = pkgs.lib.makeBinPath [
      pkgs.coreutils
    ];

    uboot = ubootPackage;
    inherit ubootBinName;
    inherit extlinuxConfBuilder;
    inherit firmwareBuilder;
  };
}