self: super: { # final: prev:

  raspberrypi-utils = super.callPackage ../../pkgs/raspberrypi-utils.nix {};

  libpisp = self.callPackage ../../pkgs/raspberrypi/libpisp.nix {};

}