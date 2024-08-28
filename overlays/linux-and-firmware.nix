let
  # linux kernel with compatible firmware
  mkBundle = self: name: firmware: {
    "${name}" = rec {
      linux_rpi5 = self."linux_rpi5_${name}";
      linux_rpi4 = self."linux_rpi4_${name}";

      linuxPackages_rpi5 = self.linuxPackagesFor linux_rpi5;
      linuxPackages_rpi4 = self.linuxPackagesFor linux_rpi4;
    } // (with firmware; {
      raspberrypifw = fw;
      raspberrypiWirelessFirmware = wFw;
    });
  };
in self: super: {

  inherit (self.linuxAndFirmware.latest)
    linux_rpi5 linuxPackages_rpi5
    linux_rpi4 linuxPackages_rpi4
    raspberrypifw raspberrypiWirelessFirmware;

  linuxAndFirmware = super.lib.mergeAttrsList [

    { latest = self.linuxAndFirmware.v6_6_31; }

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