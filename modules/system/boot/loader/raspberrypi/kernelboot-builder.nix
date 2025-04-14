{ pkgs
, firmwareBuilder
}:

pkgs.substituteAll {
  src = ./kernelboot-builder.sh;
  isExecutable = true;
  inherit (pkgs) bash;
  path = [pkgs.coreutils pkgs.gnused pkgs.gnugrep];
  inherit firmwareBuilder;
}