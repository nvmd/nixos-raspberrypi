{ argononed }:
{ config, pkgs, lib, ... }:

{
  # module in nixpkgs is outdated (Aug 2022)
  # https://github.com/NixOS/nixpkgs/blob/nixos-22.11/nixos/modules/services/hardware/argonone.nix
  disabledModules = [ "services/hardware/argonone.nix" ];
  # and the package is even more outdated (Apr 2022, with version from March 2022)
  # https://github.com/NixOS/nixpkgs/blob/nixos-22.11/pkgs/misc/drivers/argononed/default.nix

  imports = [
    "${argononed}/OS/nixos"
  ];

  # https://gitlab.com/DarkElvenAngel/argononed/-/blob/master/OS/nixos/default.nix
  services.argonone = {
    enable = lib.mkDefault true;
    logLevel = lib.mkDefault 4; # 4 for WARNING
    # Default values are the same as the OEM:
    # * at 55℃ the fan will start at 10%,
    # * at 60℃ the speed will increase to 55% and
    # * finally after 65℃ the fan will spin at 100%.
    # Default hysteresis is 3℃
  };

}