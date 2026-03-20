let
  # Kernel version → matching firmware dates
  bundleSpecs = [
    {
      version = "v6_12_47";
      fw = "20250915";
      wFw = "20251008";
    }
    {
      version = "v6_12_44";
      fw = "20250829";
      wFw = "20250408";
    }
    {
      version = "v6_12_34";
      fw = "20250702";
      wFw = "20250408";
    }
    {
      version = "v6_12_25";
      fw = "20250430";
      wFw = "20250408";
    }
    {
      version = "v6_6_74";
      fw = "20250127";
      wFw = "20241223";
    }
    {
      version = "v6_6_51";
      fw = "20241008";
      wFw = "20240226";
    }
    {
      version = "v6_6_31";
      fw = "20240529";
      wFw = "20240226";
    }
    {
      version = "v6_6_28";
      fw = "20240424";
      wFw = "20240226";
    }
    {
      version = "v6_1_73";
      fw = "20240124";
      wFw = "20240226";
    }
    {
      version = "v6_1_63";
      fw = "20231123";
      wFw = "20231115";
    }
  ];

  # linux kernel with compatible firmware
  mkBundle = final: spec: {
    ${spec.version} = rec {
      linux_rpi5 = final."linux_rpi5_${spec.version}";
      linux_rpi4 = final."linux_rpi4_${spec.version}";
      linux_rpi3 = final."linux_rpi3_${spec.version}";
      linux_rpi02 = final."linux_rpi02_${spec.version}";

      linuxPackages_rpi5 = final.linuxPackagesFor linux_rpi5;
      linuxPackages_rpi4 = final.linuxPackagesFor linux_rpi4;
      linuxPackages_rpi3 = final.linuxPackagesFor linux_rpi3;
      linuxPackages_rpi02 = final.linuxPackagesFor linux_rpi02;

      raspberrypifw = final."raspberrypifw_${spec.fw}";
      raspberrypiWirelessFirmware = final."raspberrypiWirelessFirmware_${spec.wFw}";
    };
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

  linuxAndFirmware = prev.lib.mergeAttrsList (
    [
      { default = final.linuxAndFirmware.v6_12_47; }
      { stable = final.linuxAndFirmware.default; }
      { latest = final.linuxAndFirmware.v6_12_47; }
    ]
    ++ map (mkBundle final) bundleSpecs
  );
}
