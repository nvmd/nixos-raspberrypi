let
  # linux kernel with compatible firmware
  mkBundle = final: name: firmware: {
    "${name}" = rec {
      linux_rpi5 = final."linux_rpi5_${name}";
      linux_rpi4 = final."linux_rpi4_${name}";
      linux_rpi3 = final."linux_rpi3_${name}";
      linux_rpi02 = final."linux_rpi02_${name}";

      linuxPackages_rpi5 = final.linuxPackagesFor linux_rpi5;
      linuxPackages_rpi4 = final.linuxPackagesFor linux_rpi4;
      linuxPackages_rpi3 = final.linuxPackagesFor linux_rpi3;
      linuxPackages_rpi02 = final.linuxPackagesFor linux_rpi02;
    }
    // (with firmware; {
      # Matching versions of the firmware to the kernel:
      # - https://downloads.raspberrypi.com/raspios_arm64/release_notes.txt
      # - `extra/git_hash` https://github.com/raspberrypi/firmware/ matches
      #   the hash of the https://github.com/raspberrypi/linux

      # used by
      # - `modules/installer/sd-card/sd-image-{aarch64,armv7l-multiplatform,raspberrypi}`,
      # - `omxplayer` (likely broken)
      # - `device-tree_rpi` (`raspberrypi-dtbs`)
      raspberrypifw = fw;
      # used by
      # - `modules/hardware/all-firmware.nix` to populate `hardware.firmware` on aarch64
      raspberrypiWirelessFirmware = wFw;
    });
  };
in
final: prev: {

  inherit (final.linuxAndFirmware.default)
    linux_rpi5
    linuxPackages_rpi5
    linux_rpi4
    linuxPackages_rpi4
    linux_rpi3
    linuxPackages_rpi3
    linux_rpi02
    linuxPackages_rpi02
    raspberrypifw
    raspberrypiWirelessFirmware
    ;

  linuxAndFirmware = prev.lib.mergeAttrsList [

    { default = final.linuxAndFirmware.v6_12_87; }

    { latest = final.linuxAndFirmware.v6_12_87; }

    (mkBundle final "v6_12_87" {
      fw = final.raspberrypifw_20260408;
      wFw = final.raspberrypiWirelessFirmware_20251008;
    })

    (mkBundle final "v6_12_85" {
      fw = final.raspberrypifw_20260408;
      wFw = final.raspberrypiWirelessFirmware_20251008;
    })

    (mkBundle final "v6_12_75" {
      fw = final.raspberrypifw_20260408;
      wFw = final.raspberrypiWirelessFirmware_20251008;
    })

    (mkBundle final "v6_12_47" {
      fw = final.raspberrypifw_20250915;
      wFw = final.raspberrypiWirelessFirmware_20251008;
    })

    (mkBundle final "v6_12_44" {
      fw = final.raspberrypifw_20250829;
      wFw = final.raspberrypiWirelessFirmware_20250408;
    })

    (mkBundle final "v6_12_34" {
      fw = final.raspberrypifw_20250702;
      wFw = final.raspberrypiWirelessFirmware_20250408;
    })

    (mkBundle final "v6_12_25" {
      fw = final.raspberrypifw_20250430;
      wFw = final.raspberrypiWirelessFirmware_20250408;
    })

    (mkBundle final "v6_6_74" {
      fw = final.raspberrypifw_20250127;
      wFw = final.raspberrypiWirelessFirmware_20241223;
    })

    (mkBundle final "v6_6_51" {
      fw = final.raspberrypifw_20241008;
      wFw = final.raspberrypiWirelessFirmware_20240226;
    })
    (mkBundle final "v6_6_31" {
      fw = final.raspberrypifw_20240529;
      wFw = final.raspberrypiWirelessFirmware_20240226;
    })
    (mkBundle final "v6_6_28" {
      fw = final.raspberrypifw_20240424;
      wFw = final.raspberrypiWirelessFirmware_20240226;
    })
    (mkBundle final "v6_1_73" {
      fw = final.raspberrypifw_20240124;
      # as seen in https://github.com/NixOS/nixpkgs/pull/292880:
      wFw = final.raspberrypiWirelessFirmware_20240226;
    })
    (mkBundle final "v6_1_63" {
      fw = final.raspberrypifw_20231123;
      wFw = final.raspberrypiWirelessFirmware_20231115;
    })
  ];
}
