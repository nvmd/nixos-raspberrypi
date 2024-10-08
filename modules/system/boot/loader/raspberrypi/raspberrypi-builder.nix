{ pkgs
, firmwareBuilder
}:

pkgs.substituteAll {
  src = ./raspberrypi-builder.sh;
  isExecutable = true;
  inherit (pkgs) bash;
  path = [pkgs.coreutils pkgs.gnused pkgs.gnugrep];
  inherit firmwareBuilder;
}