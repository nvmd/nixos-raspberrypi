# The devShells flake output.
{ nixpkgs, systems }:

let
  asciiArt = import ./ascii-art.nix { };
in

nixpkgs.lib.genAttrs systems.allSystems (
  system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    default = pkgs.mkShell {
      name = "nixos-raspberrypi";
      nativeBuildInputs = with pkgs; [
        jp2a # ASCII art from images
        nil # lsp language server for nix
        nixfmt-rfc-style
        deadnix
        statix
        nix-output-monitor
        bash-language-server
        shellcheck
        (pkgs.callPackage ./nix-build-to-cachix.nix { })
      ];
      shellHook = asciiArt;
    };
  }
)
