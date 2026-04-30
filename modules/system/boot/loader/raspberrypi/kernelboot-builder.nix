{
  pkgs,
  firmwareBuilder,
}:

pkgs.replaceVarsWith {
  src = ./kernelboot-builder.sh;
  isExecutable = true;

  replacements = {
    inherit (pkgs) bash;
    path = pkgs.lib.makeBinPath [
      pkgs.coreutils
      pkgs.gnused
      pkgs.jq
    ];

    inherit firmwareBuilder;
    copyKernels = true;
    initrdSecrets = pkgs.writeText "raspberrypi-initrd-secrets.sh" (builtins.readFile ./initrd-secrets.sh);
  };
}
