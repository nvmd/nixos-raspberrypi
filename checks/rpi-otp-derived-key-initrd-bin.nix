{
  nixpkgs,
  pkgs,
  self,
}:

let
  evaluated = nixpkgs.lib.nixosSystem {
    system = pkgs.stdenv.hostPlatform.system;
    modules = [
      self.nixosModules.rpi-otp-derived-key
      (
        { lib, ... }:
        {
          options.boot.loader.raspberry-pi.variant = lib.mkOption {
            type = lib.types.enum [ "5" ];
          };

          config = {
            nixpkgs.pkgs = pkgs;
            system.stateVersion = "25.11";

            boot.initrd.systemd.enable = true;
            boot.loader.supportsInitrdSecrets = true;
            boot.loader.raspberry-pi.variant = "5";

            services.rpiOtpDerivedKey = {
              enable = true;
              secrets.luks-key = {
                scheme = "legacy-hkdf-v1";
                format = "hex";
                neededForBoot = true;
              };
            };
          };
        }
      )
    ];
  };
  cfg = evaluated.config;
  initrdBin = cfg.boot.initrd.systemd.contents."/bin".source;
  initrdStorePaths = map (entry: entry.source) cfg.boot.initrd.systemd.storePaths;
in
assert !(builtins.elem pkgs.libraspberrypi cfg.boot.initrd.systemd.initrdBin);
assert builtins.elem pkgs.libraspberrypi initrdStorePaths;
pkgs.runCommand "rpi-otp-derived-key-initrd-bin" { } ''
  test -x ${initrdBin}/rpi-fw-crypto
  test -x ${initrdBin}/rpi-otp-private-key
  touch $out
''
