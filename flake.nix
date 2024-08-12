{
  description = "Flake for RaspberryPi support on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # for `config.txt` generation
    raspberry-pi-nix.url = "github:nvmd/raspberry-pi-nix";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, ... }: let
    system = "aarch64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "nixos-raspberrypi";
      nativeBuildInputs = with pkgs-unstable; [
        nil # lsp language server for nix
        nixpkgs-fmt
        nix-output-monitor
        bash-language-server
        shellcheck
      ];
    };

    nixosModules = {
      default = import ./modules/raspberrypi.nix;
      bootloader = import ./modules/system/boot/loader/raspberrypi;
      rpi5 = {
        sd-image = import ./modules/installer/sd-card/sd-image-raspberrypi5.nix;
        sd-image-installer = import ./modules/installer/sd-card/sd-image-raspberrypi5-installer.nix;
      };
    };

    overlays = {
      bootloader = import ./overlays/bootloader.nix;
      pkgs-global = import ./overlays/pkgs-global.nix;
      pkgs = import ./overlays/pkgs.nix;
      vendor-kernel-nixpkgs = import ./overlays/vendor-kernel-nixpkgs.nix;
      vendor-kernel = import ./overlays/vendor-kernel.nix;
      vendor-utils = import ./overlays/vendor-utils.nix;
    };

  };
}
