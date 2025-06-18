{ pkgs
, firmwareBuilder
}:

pkgs.replaceVars ./kernelboot-builder.sh {
  inherit (pkgs) bash;
  path = [ pkgs.coreutils pkgs.gnused ];

  inherit firmwareBuilder;

  copyKernels = null;
}
