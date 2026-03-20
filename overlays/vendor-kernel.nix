let
  # the latter value is retained when can't be merged
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
  builtins.concatLists [
    (mkLinuxFor prev "6_12_47" [ "02" "3" "4" "5" ])
    (mkLinuxFor prev "6_12_44" [ "02" "3" "4" "5" ])
    (mkLinuxFor prev "6_12_34" [ "02" "3" "4" "5" ])
    (mkLinuxFor prev "6_12_25" [ "02" "3" "4" "5" ])
    (mkLinuxFor prev "6_6_74" [ "02" "4" "5" ])
    (mkLinuxFor prev "6_6_51" [ "02" "4" "5" ])
    (mkLinuxFor prev "6_6_31" [ "4" "5" ])
    (mkLinuxFor prev "6_6_28" [ "4" "5" ])
    (mkLinuxFor prev "6_1_73" [ "4" "5" ])
    (mkLinuxFor prev "6_1_63" [ "4" "5" ])
  ]
)
