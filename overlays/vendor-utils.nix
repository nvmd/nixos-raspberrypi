self: super: { # final: prev:

  libraspberrypi = super.callPackage ../pkgs/raspberrypi/libraspberrypi.nix {};

  raspberrypi-utils = super.callPackage ../pkgs/raspberrypi/raspberrypi-utils.nix {};

  libpisp = self.callPackage ../pkgs/raspberrypi/libpisp.nix {};

}