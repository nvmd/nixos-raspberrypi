final: prev: {

  libraspberrypi = prev.callPackage ../pkgs/raspberrypi/libraspberrypi.nix {};

  raspberrypi-userland = final.libraspberrypi;

  raspberrypi-udev-rules = prev.callPackage ../pkgs/raspberrypi/udev-rules.nix {};

  raspberrypi-utils = prev.callPackage ../pkgs/raspberrypi/raspberrypi-utils.nix {};

  rpi-otp-private-key = prev.callPackage ../pkgs/raspberrypi/rpi-otp-private-key.nix {};

  rpi-otp-derived-key = prev.callPackage ../pkgs/raspberrypi/rpi-otp-derived-key.nix {
    rpi-otp-private-key = final.rpi-otp-private-key;
  };

  rpi-otp-derived-key-provision = prev.callPackage ../pkgs/raspberrypi/rpi-otp-derived-key-provision.nix {
    rpi-otp-private-key = final.rpi-otp-private-key;
    rpi-otp-derived-key = final.rpi-otp-derived-key;
  };

  rpi-userland = final.libraspberrypi;

  rpicam-apps = prev.callPackage ../pkgs/raspberrypi/rpicam-apps.nix {
    libcamera = final.libcamera_rpi;
  };

}
