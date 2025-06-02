let
  # linux kernel with compatible firmware
  mkBundle = self: name: firmware: {
    "${name}" = rec {
      linux_rpi5 = self."linux_rpi5_${name}";
      linux_rpi4 = self."linux_rpi4_${name}";
      linux_rpi3 = self."linux_rpi3_${name}";
      linux_rpi02 = self."linux_rpi02_${name}";

      linuxPackages_rpi5 = self.linuxPackagesFor linux_rpi5;
      linuxPackages_rpi4 = self.linuxPackagesFor linux_rpi4;
      linuxPackages_rpi3 = self.linuxPackagesFor linux_rpi3;
      linuxPackages_rpi02 = self.linuxPackagesFor linux_rpi02;
    } // (with firmware; {
      raspberrypifw = fw;
      raspberrypiWirelessFirmware = wFw;
    });
  };
in self: super: {

  inherit (self.linuxAndFirmware.default)
    linux_rpi5 linuxPackages_rpi5
    linux_rpi4 linuxPackages_rpi4
    linux_rpi3 linuxPackages_rpi3
    linux_rpi02 linuxPackages_rpi02
    raspberrypifw raspberrypiWirelessFirmware;

  linuxAndFirmware = super.lib.mergeAttrsList [

    { default = self.linuxAndFirmware.v6_12_25; }

    { latest = self.linuxAndFirmware.v6_12_25; }

    (mkBundle self "v6_12_25" {
      fw = self.raspberrypifw_20250430;
      wFw = self.raspberrypiWirelessFirmware_20250408;
    })

    (mkBundle self "v6_6_74" {
      fw = self.raspberrypifw_20250127;
      wFw = self.raspberrypiWirelessFirmware_20241223;
    })

    (mkBundle self "v6_6_51" {
      fw = self.raspberrypifw_20241008;
      wFw = self.raspberrypiWirelessFirmware_20240226;
    })
    (mkBundle self "v6_6_31" {
      fw = self.raspberrypifw_20240529;
      wFw = self.raspberrypiWirelessFirmware_20240226;
    })
    (mkBundle self "v6_6_28" {
      fw = self.raspberrypifw_20240424;
      wFw = self.raspberrypiWirelessFirmware_20240226;
    })
    (mkBundle self "v6_1_73" {
      fw = self.raspberrypifw_20240124;
      # as seen in https://github.com/NixOS/nixpkgs/pull/292880:
      wFw = self.raspberrypiWirelessFirmware_20240226;
    })
    (mkBundle self "v6_1_63" {
      fw = self.raspberrypifw_20231123;
      wFw = self.raspberrypiWirelessFirmware_20231115;
    })
  ];
}
