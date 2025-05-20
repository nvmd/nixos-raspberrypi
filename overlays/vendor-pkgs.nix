self: super: { # final: prev:

  # now available from nixpkgs
  # libpisp = self.callPackage ../pkgs/raspberrypi/libpisp.nix {};

  libraspberrypi = super.callPackage ../pkgs/raspberrypi/libraspberrypi.nix {};

  raspberrypi-userland = self.libraspberrypi;

  raspberrypi-udev-rules = super.callPackage ../pkgs/raspberrypi/udev-rules.nix {};

  raspberrypi-utils = super.callPackage ../pkgs/raspberrypi/raspberrypi-utils.nix {};

  rpi-userland = self.libraspberrypi;

  rpicam-apps = super.callPackage ../pkgs/raspberrypi/rpicam-apps.nix {
    libcamera = self.libcamera_rpi;
  };

}