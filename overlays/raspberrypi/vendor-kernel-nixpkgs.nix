self: super: { # final: prev:

  # 6.1.63 in `nixpkgs-unstable`

  linux_rpi4 = super.linux_rpi4;
  linux_rpi5 = super.linux_rpi4.override {
    rpiVersion = 5;
    argsOverride.defconfig = "bcm2712_defconfig";
  };

  linuxPackages_rpi5 = self.linuxPackagesFor self.linux_rpi5;
}