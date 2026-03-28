let
  # Kernel version → supported RPi model suffixes.
  # RPi3 is missing from 6.6.x and 6.1.x: those kernel branches dropped
  # support for the bcm2837 SoC used in RPi 3.
  kernelMatrix = {
    "6_12_47" = [
      "02"
      "3"
      "4"
      "5"
    ];
    "6_12_44" = [
      "02"
      "3"
      "4"
      "5"
    ];
    "6_12_34" = [
      "02"
      "3"
      "4"
      "5"
    ];
    "6_12_25" = [
      "02"
      "3"
      "4"
      "5"
    ];
    "6_6_74" = [
      "02"
      "4"
      "5"
    ];
    "6_6_51" = [
      "02"
      "4"
      "5"
    ];
    "6_6_31" = [
      "4"
      "5"
    ];
    "6_6_28" = [
      "4"
      "5"
    ];
    "6_1_73" = [
      "4"
      "5"
    ];
    "6_1_63" = [
      "4"
      "5"
    ];
  };

  # Deep merge that concatenates lists (for kernelPatches) and recurses into
  # attrsets, unlike lib.recursiveUpdate which replaces attrsets wholesale.
  recursiveMerge =
    lib: attrList:
    let
      f =
        attrPath:
        lib.zipAttrsWith (
          n: values:
          if lib.tail values == [ ] then
            lib.head values
          else if lib.all lib.isList values then
            lib.unique (lib.concatLists values)
          else if lib.all lib.isAttrs values then
            f (attrPath ++ [ n ]) values
          else
            lib.last values
        );
    in
    f [ ] attrList;

  mkLinuxFor =
    pkgs: version: models:
    let
      argsFor = (import ./kernels.nix { inherit pkgs; }).${version};
      linuxVersionForModel = rpiModel: {
        "linux_rpi${rpiModel}_v${version}" = pkgs.callPackage ../pkgs/linux-rpi.nix (
          recursiveMerge pkgs.lib [
            {
              kernelPatches = with pkgs.kernelPatches; [
                bridge_stp_helper
                request_key_helper
              ];
              inherit rpiModel;
            }
            argsFor
          ]
        );
      };
    in
    map linuxVersionForModel models;

in
final: prev:
prev.lib.mergeAttrsList (
  builtins.concatLists (prev.lib.mapAttrsToList (mkLinuxFor prev) kernelMatrix)
)
