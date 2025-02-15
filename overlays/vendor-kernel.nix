let
  argsOverrideFor = pkgs: version: let
    mkArgsOverride = { modDirVersion, tag, srcHash
                     , structuredExtraConfig ? {}
                     , kernelPatches ? []
                     }: rec {
      inherit modDirVersion tag structuredExtraConfig kernelPatches;

      version = "${modDirVersion}-${tag}";
      src = pkgs.fetchFromGitHub {
        owner = "raspberrypi";
        repo = "linux";
        rev = tag;
        hash = srcHash;
      };
    };
  in mkArgsOverride (import ./kernels.nix { inherit pkgs; }).${version};

  mkLinuxFor = pkgs: version: models: let
    linuxVersionForModel = rpiModel: {
      # in nixpkgs this is also in pkgs.linuxKernel.packages.<...>
      # see also https://github.com/NixOS/nixos-hardware/pull/927
      # linux_rpi4_v6_6_28 = pkgs.linux_rpi4.override {
      #   argsOverride = linux_v6_6_28_argsOverride pkgs;
      # };

      # as in https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/linux-kernels.nix#L91
      "linux_rpi${rpiModel}_v${version}" = pkgs.callPackage ../pkgs/linux-rpi.nix {
        argsOverride = argsOverrideFor pkgs version;
        kernelPatches = with pkgs.kernelPatches; [
          bridge_stp_helper
          request_key_helper
        ];
        inherit rpiModel;
      };

      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/linux-rpi.nix
      # overriding other override like this doesn't work
      # linux_rpi5 = self.linux_rpi4.override {
      #   rpiVersion = 5;
      #   argsOverride.defconfig = "bcm2712_defconfig";
      # };
      # linux_rpi5_v6_6_28 = self.linux_rpi4_v6_6_28.override {
      #   rpiVersion = 5;
      #   argsOverride = (linux_v6_6_28_argsOverride pkgs) // {
      #     defconfig = "bcm2712_defconfig";
      #   };
      # };
    };
  in map linuxVersionForModel models;

in self: super: super.lib.mergeAttrsList (
  builtins.concatLists [
    (mkLinuxFor super "6_6_74" [ "02" "4" "5" ])
    (mkLinuxFor super "6_6_51" [ "02" "4" "5" ])
    (mkLinuxFor super "6_6_31" [ "4" "5" ])
    (mkLinuxFor super "6_6_28" [ "4" "5" ])
    (mkLinuxFor super "6_1_73" [ "4" "5" ])
    (mkLinuxFor super "6_1_63" [ "4" "5" ])
  ])
