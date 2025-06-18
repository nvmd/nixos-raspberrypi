{ pkgs
, firmwareBuilder
}:

pkgs.replaceVarsWith {
  src = ./kernelboot-builder.sh;
  isExecutable = true;

  replacements = {
    inherit (pkgs) bash;
    path = pkgs.lib.makeBinPath [
      pkgs.coreutils
      pkgs.gnused
    ];

    inherit firmwareBuilder;
    copyKernels = true;
  };
}