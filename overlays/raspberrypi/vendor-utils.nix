self: super: { # final: prev:

  libraspberrypi = super.callPackage ../../pkgs/libraspberrypi.nix {};

  raspberrypi-utils = super.callPackage ../../pkgs/raspberrypi-utils.nix {};

  libpisp = self.callPackage ../../pkgs/raspberrypi/libpisp.nix {};

}