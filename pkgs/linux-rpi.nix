{ stdenv
, lib
, fetchFromGitHub
, buildLinux
, rpiModel
, modDirVersion
, tag
, rev ? tag
, srcHash
, ...
} @ args:

let
  linuxConfig = let
    arch = stdenv.hostPlatform.uname.processor;
    mkConfig = name: {
      defconfig = "${name}_defconfig";
      structuredExtraConfig = let
        genericConfig = args.structuredExtraConfig or {};
        # this is to enforce some of the "<name>_defconfig" kernel options
        # after nixos overrides some of them
        # specific to <name> and the arch it is being built for
        configFixup = args.fixupStructuredConfig.${name}.${arch} or {};
      in configFixup // genericConfig;
    };
  in {
    # matching first on arch, and the on the board model to easier handle 
    # unsupported (arch,board) combinations
    armv6l = {
      "0" = mkConfig "bcmrpi";
      "1" = mkConfig "bcmrpi";
    };
    armv7l = {
      "02" = mkConfig "bcm2709";
      "2" = mkConfig "bcm2709";
      "3" = mkConfig "bcm2709";
      "4" = mkConfig "bcm2711";
    };
    aarch64 = {
      "02" = mkConfig "bcm2711";
      "3" = mkConfig "bcm2711";
      "4" = mkConfig "bcm2711";
      "5" = mkConfig "bcm2712";
    };
  }.${arch}.${rpiModel};
in
lib.overrideDerivation (buildLinux (args // rec {
  version = "${modDirVersion}-${tag}";
  inherit modDirVersion;
  pname = "linux_rpi-${builtins.elemAt (lib.splitString "_" defconfig) 0}";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "linux";
    inherit rev;
    hash = srcHash;
  };

  inherit (linuxConfig) defconfig structuredExtraConfig;

  features = {
    efiBootStub = false;
  } // (args.features or {});

  kernelPatches = args.kernelPatches or [];

  extraMeta = if (lib.elem rpiModel [ "0" "1" "2" ]) then {
    platforms = with lib.platforms; arm;
    hydraPlatforms = [];
  } else {
    platforms = with lib.platforms; arm ++ aarch64;
    hydraPlatforms = [ "aarch64-linux" ];
  };

  ignoreConfigErrors = true;

} // (args.argsOverride or {}))) (oldAttrs: {
  postConfigure = ''
    # The v7 defconfig has this set to '-v7' which screws up our modDirVersion.
    sed -i $buildRoot/.config -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
    sed -i $buildRoot/include/config/auto.conf -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
  '';

  # Make copies of the DTBs named after the upstream names so that U-Boot finds them.
  # This is ugly as heck, but I don't know a better solution so far.
  postFixup = ''
    dtbDir=${if stdenv.isAarch64 then "$out/dtbs/broadcom" else "$out/dtbs"}
    rm $dtbDir/bcm283*.dtb
    copyDTB() {
      cp -v "$dtbDir/$1" "$dtbDir/$2"
    }
  '' + lib.optionalString (lib.elem stdenv.hostPlatform.system ["armv6l-linux"]) ''
    copyDTB bcm2708-rpi-zero-w.dtb bcm2835-rpi-zero.dtb
    copyDTB bcm2708-rpi-zero-w.dtb bcm2835-rpi-zero-w.dtb
    copyDTB bcm2708-rpi-b.dtb bcm2835-rpi-a.dtb
    copyDTB bcm2708-rpi-b.dtb bcm2835-rpi-b.dtb
    copyDTB bcm2708-rpi-b.dtb bcm2835-rpi-b-rev2.dtb
    copyDTB bcm2708-rpi-b-plus.dtb bcm2835-rpi-a-plus.dtb
    copyDTB bcm2708-rpi-b-plus.dtb bcm2835-rpi-b-plus.dtb
    copyDTB bcm2708-rpi-b-plus.dtb bcm2835-rpi-zero.dtb
    copyDTB bcm2708-rpi-cm.dtb bcm2835-rpi-cm.dtb
  '' + lib.optionalString (lib.elem stdenv.hostPlatform.system ["armv7l-linux"]) ''
    copyDTB bcm2709-rpi-2-b.dtb bcm2836-rpi-2-b.dtb
  '' + lib.optionalString (lib.elem stdenv.hostPlatform.system ["armv7l-linux" "aarch64-linux"]) ''
    copyDTB bcm2710-rpi-zero-2.dtb bcm2837-rpi-zero-2.dtb
    copyDTB bcm2710-rpi-zero-2-w.dtb bcm2837-rpi-zero-2-w.dtb
    copyDTB bcm2710-rpi-3-b.dtb bcm2837-rpi-3-b.dtb
    copyDTB bcm2710-rpi-3-b-plus.dtb bcm2837-rpi-3-a-plus.dtb
    copyDTB bcm2710-rpi-3-b-plus.dtb bcm2837-rpi-3-b-plus.dtb
    copyDTB bcm2710-rpi-cm3.dtb bcm2837-rpi-cm3.dtb
    copyDTB bcm2711-rpi-4-b.dtb bcm2838-rpi-4-b.dtb
  '';
})
