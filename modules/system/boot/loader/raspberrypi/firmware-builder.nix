{ pkgs
, configTxt
, firmware ? pkgs.raspberrypifw
}:

pkgs.replaceVars ./firmware-builder.sh {
  inherit (pkgs) bash;
  path = [ pkgs.coreutils ];

  inherit firmware configTxt;
}
