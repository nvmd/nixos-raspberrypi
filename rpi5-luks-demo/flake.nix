{
  description = "RPi 5 NVMe LUKS install demo for nixos-raspberrypi";

  inputs = {
    nixos-raspberrypi.url = "path:..";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
    };
  };

  outputs = { self, nixos-raspberrypi, disko, ... }@inputs: {
    nixosConfigurations.rpi5 = nixos-raspberrypi.lib.nixosSystem {
      specialArgs = inputs // {
        inherit disko;
      };

      modules = [
        ./configuration.nix
        ./disko.nix
      ];
    };
  };
}
