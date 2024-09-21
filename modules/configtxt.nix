{ config, lib, pkgs, ... }:

{
  # Default config.txt as provided with the official Raspberry Pi OS images
  # https://github.com/RPi-Distro/pi-gen/blob/master/stage1/00-boot-files/files/config.txt

  # More options and information: http://rptl.io/configtxt

  # Additional overlays' (base-dt-params,dt-overlays) documentation:
  # * /boot/firmware/overlays/README
  # * https://github.com/raspberrypi/linux/blob/rpi-6.6.y/arch/arm/boot/dts/overlays/README

  hardware.raspberry-pi.config = {
    all = {
      options = {
        # Automatically load overlays for detected cameras
        camera_auto_detect = {
          enable = lib.mkDefault true;
          value = lib.mkDefault true;
        };

        # Automatically load overlays for detected DSI displays
        display_auto_detect = {
          enable = lib.mkDefault true;
          value = lib.mkDefault true;
        };

        # Automatically load initramfs files, if found
        # auto_initramfs = {
        #   enable = true;
        #   value = 1;
        # };

        # For DRM VC4 V3D driver (vc4-kms-v3d) below
        max_framebuffers = {
          enable = lib.mkDefault true;
          value = lib.mkDefault 2;
        };

        # Don't have the firmware create an initial video= setting in cmdline.txt.
        # Use the kernel's default instead.
        disable_fw_kms_setup = {
          enable = lib.mkDefault true;
          value = lib.mkDefault true;
        };

        # Disable compensation for displays with overscan
        disable_overscan = {
          enable = lib.mkDefault true;
          value = lib.mkDefault true;
        };

        # Run as fast as firmware / board allows
        arm_boost = {
          enable = lib.mkDefault true;
          value = lib.mkDefault true;
        };
      };
      base-dt-params = {
        # Uncomment some or all of these to enable the optional hardware interfaces
        # i2c_arm = {
        #   enable = true;
        #   value = "on";
        # };
        # i2s = {
        #   enable = true;
        #   value = "on";
        # };
        # spi = {
        #   enable = true;
        #   value = "on";
        # };

        # Enable audio (loads snd_bcm2835)
        audio = {
          enable = true;
          value = "on";
        };
      };
      dt-overlays = {
        # Enable DRM VC4 V3D driver
        vc4-kms-v3d = {
          enable = lib.mkDefault true;
          params = { };
        };
      };
    };
    cm4 = {
      options = {
        # Enable host mode on the 2711 built-in XHCI USB controller.
        # This line should be removed if the legacy DWC2 controller is required
        # (e.g. for USB device mode) or if USB support is not required.
        otg_mode = {
          enable = lib.mkDefault true;
          value = lib.mkDefault true;
        };
      };
    };
    cm5 = {
      dt-overlays = {
        dwc2 = {
          enable = lib.mkDefault true;
          params = {
            dr_mode = {
              enable = true;
              value = "host";
            };
          };
        };
      };
    };
  };
}