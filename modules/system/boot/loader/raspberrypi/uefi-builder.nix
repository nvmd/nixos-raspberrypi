{ pkgs
, uefiPackage
, configTxt
, firmwareBuilder
}:

pkgs.substituteAll {
  src = ./uefi-builder.sh;
  isExecutable = true;
  inherit (pkgs) bash;
  path = [pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.rsync];

  uefi = uefiPackage;
  uefiBinName = "RPI_EFI.fd";
  inherit configTxt firmwareBuilder;
}