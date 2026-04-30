{
  pkgs,
  ubootPackage,
  ubootBinName ? "u-boot-rpi.bin",
  extlinuxConfBuilder,
  firmwareBuilder,
}:

pkgs.replaceVarsWith {
  src = ./uboot-builder.sh;
  isExecutable = true;

  replacements = {
    inherit (pkgs) bash;
    path = pkgs.lib.makeBinPath [
      pkgs.coreutils
      pkgs.gnused
      pkgs.jq
    ];

    uboot = ubootPackage;
    inherit ubootBinName;
    inherit extlinuxConfBuilder;
    inherit firmwareBuilder;
    initrdSecrets = pkgs.writeText "raspberrypi-initrd-secrets.sh" (builtins.readFile ./initrd-secrets.sh);
  };
}
