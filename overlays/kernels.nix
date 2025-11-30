{ pkgs, ... }:

let
  # Default priority is 100 for common kernel options (see common-config.nix
  # file), we need something lower to override them, but we still want users to
  # override options if they need using lib.mkForce (that has 50 priority)
  mkKernelOverride = pkgs.lib.mkOverride 90;

  listToAttrsWName = nameGen: vs: builtins.listToAttrs (map (v: { name = nameGen v; value = v; }) vs);
  listToAttrsWLVer = listToAttrsWName (v: "v${builtins.replaceStrings ["."] ["_"] v.modDirVersion}");

  patches = import ../pkgs/linux-rpi/linux-patches.nix { inherit pkgs; };
  linux = listToAttrsWLVer (import ../pkgs/linux-rpi/linux-sources.nix);

in listToAttrsWLVer [
  linux.v6_12_44
  linux.v6_12_34
  (linux.v6_12_25 // {
    # this is to enforce some of the "_defconfig" kernel options after nixos
    # overrides some of them
    # https://raw.githubusercontent.com/raspberrypi/linux/refs/tags/stable_20250428/arch/arm64/configs/bcm2712_defconfig
    fixupStructuredConfig = let
      common = with pkgs.lib.kernel; {
        # CRYPTO_AES = module ; # =yes in nixos;
        # CRYPTO_SHA512 = module ; # =yes in nixos;
        NET_CLS_BPF = mkKernelOverride yes ; # =module in nixos;
        NR_CPUS = mkKernelOverride (freeform "4"); # =384 in nixos;

        PREEMPT = mkKernelOverride yes;
        # override what nixos sets in `linux/kernel/preempt.common-config.nix`
        PREEMPT_VOLUNTARY = mkKernelOverride no;

        # BINFMT_MISC = module ; # =yes in nixos;
        CMA_SIZE_MBYTES = mkKernelOverride (freeform "5") ; # =32 in nixos;
        CPU_FREQ_DEFAULT_GOV_ONDEMAND = yes;
        # DRM = module ; # =yes in nixos;
        # F2FS_FS = yes ; # =module in nixos;
        FB_SIMPLE = yes;
        # IKCONFIG = module ; # =yes in nixos;
        # IPV6 = module ; # =yes in nixos;
        IP_PNP = mkKernelOverride yes;
        IP_PNP_DHCP = yes;
        IP_PNP_RARP = yes;
        LOGO = mkKernelOverride yes;
        NFS_FS = mkKernelOverride yes ; # =module in nixos;
        NFS_V4 = yes ; # =module in nixos;
        NLS_CODEPAGE_437 = mkKernelOverride yes ; # =module in nixos;
        ROOT_NFS = yes;
        # UEVENT_HELPER = yes;
        # UNICODE = module; # =y in nixos
        # USB_SERIAL = module ; # =yes in nixos;
      };
    in {
      bcm2711.aarch64 = common // {
        # LOCALVERSION = "-v8" ; # ="" in nixos;
      };
      bcm2712.aarch64 = common // {
        # LOCALVERSION = "-v8-16k" ; # ="" in nixos;
      };
    };
  })
  linux.v6_6_74
  linux.v6_6_51
  (linux.v6_6_31 // {
    structuredExtraConfig = with pkgs.lib.kernel; {
      # Workaround https://github.com/raspberrypi/linux/issues/6198
      # Needed because NixOS 24.05+ sets DRM_SIMPLEDRM=y which pulls in
      # DRM_KMS_HELPER=y.
      BACKLIGHT_CLASS_DEVICE = yes;
    };
    kernelPatches = with patches; [
      # Fix compilation errors due to incomplete patch backport.
      # https://github.com/raspberrypi/linux/pull/6223
      gpio-pwm_-_pwm_apply_might_sleep
      ir-rx51_-_pwm_apply_might_sleep
    ];
    # this is to enforce some of the "_defconfig" kernel options after nixos
    # overrides some of them
    # https://raw.githubusercontent.com/raspberrypi/linux/refs/tags/stable_20240529/arch/arm64/configs/bcm2712_defconfig
    fixupStructuredConfig = let
      common = with pkgs.lib.kernel; {
        # CRYPTO_AES = module ; # =yes in nixos;
        # CRYPTO_SHA512 = module ; # =yes in nixos;
        NET_CLS_BPF = mkKernelOverride yes ; # =module in nixos;

        PREEMPT = mkKernelOverride yes;
        # override what nixos sets in `linux/kernel/preempt.common-config.nix`
        PREEMPT_VOLUNTARY = mkKernelOverride no;

        # BINFMT_MISC = module ; # =yes in nixos;
        CMA_SIZE_MBYTES = mkKernelOverride (freeform "5") ; # =32 in nixos;
        # CPU_FREQ_DEFAULT_GOV_POWERSAVE = yes;
        # DRM = module ; # =yes in nixos;
        # F2FS_FS = yes ; # =module in nixos;
        FB_SIMPLE = yes;
        # IKCONFIG = module ; # =yes in nixos;
        # IPV6 = module ; # =yes in nixos;
        IP_PNP = mkKernelOverride yes;
        IP_PNP_DHCP = yes;
        IP_PNP_RARP = yes;
        LOGO = mkKernelOverride yes;
        NFS_FS = mkKernelOverride yes ; # =module in nixos;
        NFS_V4 = yes ; # =module in nixos;
        NLS_CODEPAGE_437 = mkKernelOverride yes ; # =module in nixos;
        # NTFS_FS = mkKernelOverride module;
        # NTFS_RW = yes;
        ROOT_NFS = yes;
        # UEVENT_HELPER = yes;
        # USB_SERIAL = module ; # =yes in nixos;
      };
    in {
      bcm2711.aarch64 = common // {
        # LOCALVERSION = "-v8" ; # ="" in nixos;
      };
      bcm2712.aarch64 = common // {
        # LOCALVERSION = "-v8-16k" ; # ="" in nixos;
      };
    };
  })
  (linux.v6_6_28 // {
    structuredExtraConfig = with pkgs.lib.kernel; {
      GPIO_PWM = no;
    };
  })
  (linux.v6_1_73 // {
    kernelPatches = with patches; [
      drm-rp1-depends-on-instead-of-select-MFD_RP1
      iommu-bcm2712-don-t-allow-building-as-module
    ];
  })
  (linux.v6_1_63 // {
    kernelPatches = with patches; [
      drm-rp1-depends-on-instead-of-select-MFD_RP1
      iommu-bcm2712-don-t-allow-building-as-module
    ];
  })
]