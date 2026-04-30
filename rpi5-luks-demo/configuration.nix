{ lib
, pkgs
, nixos-raspberrypi
, ...
}:

let
  operatorKeys = import ./ssh-keys.nix;
in
{
  imports = with nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.page-size-16k
    rpi-otp-derived-key
  ];

  networking = {
    hostName = "rpi5-luks-demo";
    useDHCP = lib.mkDefault true;
  };

  boot = {
    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "nvme"
        "dm_mod"
        "dm_crypt"
        "ext4"
      ];
      services.lvm.enable = true;
    };

    loader.raspberry-pi.bootloader = "kernel";
    supportedFilesystems = [
      "ext4"
      "vfat"
    ];
  };

  services.rpiOtpDerivedKey = {
    enable = true;
    secrets.luks-key = {
      format = "hex";
      path = "/run/secrets/luks.key";
      neededForBoot = true;
      before = [ "cryptsetup-pre.target" ];
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users = {
    root.openssh.authorizedKeys.keys = operatorKeys;

    nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = operatorKeys;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    cryptsetup
    lvm2
    raspberrypi-eeprom
    rpi-otp-derived-key
    rpi-otp-derived-key-provision
    rpi-otp-private-key
    tree
  ];

  system.stateVersion = "25.11";
}
