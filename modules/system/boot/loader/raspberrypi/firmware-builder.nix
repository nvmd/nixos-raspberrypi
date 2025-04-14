{ pkgs
, configTxt
, firmware ? pkgs.raspberrypifw
}:

pkgs.substituteAll {
  src = ./firmware-builder.sh;
  isExecutable = true;

  inherit (pkgs) bash;
  path = [ pkgs.coreutils ];

  inherit firmware configTxt;
}