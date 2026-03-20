# The nixosModules flake output attrset.
{ self, argononed }:

{
  trusted-nix-caches = import ./trusted-nix-caches.nix;
  nixpkgs-rpi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    import ./nixpkgs-rpi.nix {
      inherit
        config
        lib
        pkgs
        self
        ;
    };

  bootloader = import ./system/boot/loader/raspberrypi;
  default =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    import ./raspberrypi.nix {
      inherit
        config
        lib
        pkgs
        self
        ;
    };

  sd-image = import ./installer/sd-card/sd-image-raspberrypi.nix;

  pisugar-3 = import ./pisugar-3.nix;

  usb-gadget-ethernet = import ./usb-gadget-ethernet.nix;

  raspberry-pi-5 = {
    base =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      import ./raspberry-pi-5 {
        inherit
          config
          lib
          pkgs
          self
          ;
      };
    display-vc4 = import ./display-vc4.nix;
    display-rp1 = import ./raspberry-pi-5/display-rp1.nix;
    bluetooth = import ./bluetooth.nix;
    page-size-16k =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      import ./raspberry-pi-5/page-size-16k.nix {
        inherit
          config
          lib
          pkgs
          self
          ;
      };
  };

  raspberry-pi-4 = {
    base =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      import ./raspberry-pi-4.nix {
        inherit
          config
          lib
          pkgs
          self
          ;
      };
    display-vc4 = import ./display-vc4.nix;
    bluetooth = import ./bluetooth.nix;
    # work-in-progress, untested
    case-argonone = import ./case-argononev2.nix { inherit argononed; };
  };

  raspberry-pi-3 = {
    base =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      import ./raspberry-pi-3.nix {
        inherit
          config
          lib
          pkgs
          self
          ;
      };
  };

  raspberry-pi-02 = {
    base =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      import ./raspberry-pi-02.nix {
        inherit
          config
          lib
          pkgs
          self
          ;
      };
    display-vc4 = import ./display-vc4.nix;
    bluetooth = import ./bluetooth.nix;
  };
}
