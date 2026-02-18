{
  pkgs,
  configTxt,
  firmware ? pkgs.raspberrypifw,
}:

pkgs.replaceVarsWith {
  src = ./firmware-builder.sh;
  isExecutable = true;

  replacements = {
    inherit (pkgs) bash;
    path = pkgs.lib.makeBinPath [
      pkgs.coreutils
    ];

    inherit firmware configTxt;
  };
}
