# The packages flake output (per-buildSystem with cross-compilation).
#
# Only flat derivations live here (packages.<system>.<name> = <drv>).
# The default target is aarch64-linux (RPi 4/5, most common).
# For explicit target architectures (armv7l, armv6l), use legacyPackages:
#   nix build .#legacyPackages.x86_64-linux.armv7l-linux.linux_rpi3
{
  lib,
  systems,
  pkgHelpers,
}:

let
  inherit (systems) buildSystems rpiSystems;
  inherit (pkgHelpers) mkRpiPkgsSmart extractRpiPackages;
in

{
  # Flat derivations only — schema-compliant packages output.
  # Filters out non-derivation values (e.g., linuxPackages_* attrsets).
  packages = lib.genAttrs buildSystems (
    buildSystem:
    let
      pkgs = mkRpiPkgsSmart {
        inherit buildSystem;
        targetSystem = "aarch64-linux";
      };
    in
    lib.filterAttrs (n: v: lib.isDerivation v) (extractRpiPackages pkgs)
  );

  # Per-target cross packages (nested attrsets — for legacyPackages)
  crossPackagesByTarget = lib.genAttrs buildSystems (
    buildSystem:
    lib.genAttrs rpiSystems (
      targetSystem:
      let
        pkgs = mkRpiPkgsSmart { inherit buildSystem targetSystem; };
      in
      extractRpiPackages pkgs
    )
  );
}
