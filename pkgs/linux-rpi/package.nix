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
    # https://www.raspberrypi.com/documentation/computers/linux_kernel.html#native-build-configuration
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
(buildLinux (args // rec {
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

} // (args.argsOverride or {}))).overrideAttrs {
  postConfigure = ''
    # The v7 defconfig has this set to '-v7' which screws up our modDirVersion.
    sed -i $buildRoot/.config -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
    sed -i $buildRoot/include/config/auto.conf -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
  '';

  postFixup = let
    armArch = if stdenv.isAarch64 then "arm64" else "arm";
  in ''
    # Provide overlays together with README just like `raspberrypifw`
    # (https://github.com/raspberrypi/firmware/) does
    # Raspberry's bootloader may check if it's present in `overlays/` on
    # FIRMWARE partition
    # see
    # * https://www.raspberrypi.com/documentation/computers/config_txt.html#os_prefix
    # * https://www.raspberrypi.com/documentation/computers/config_txt.html#overlay_prefix

    # `src` is, unfortunately, unset in postPatch for linux
    # see:
    # * https://github.com/NixOS/nixpkgs/blob/be281b772565298a2e0b18138df2e25cbf838521/pkgs/os-specific/linux/kernel/manual-config.nix#L290
    # * https://github.com/NixOS/nixpkgs/pull/332180
    # assume linux needs only one source archive, so that srcs is always single path

    overlaySrcDir="$srcs/arch/${armArch}/boot/dts/overlays"
    cp "$overlaySrcDir/README" "$out/dtbs/overlays/"
  '';
}
