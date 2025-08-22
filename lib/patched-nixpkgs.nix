{self, ...}: let
  pre-pkgs = import self.inputs.nixpkgs {};

  patchedSrc =
    pre-pkgs.applyPatches
    {
      name = "nixpkgs";
      src = self.inputs.nixpkgs.outPath;
      patches = [
        (
          pre-pkgs.fetchpatch {
            name = "pr-398456";
            url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/398456.patch";
            sha256 = "sha256-N4gry4cH0UqumhTmOH6jyHNWpvW11eRDlGsnj5uSi+0=";
          }
        )
      ];
    };
in
  (import self.inputs.flake-compat {src = patchedSrc;}).outputs
