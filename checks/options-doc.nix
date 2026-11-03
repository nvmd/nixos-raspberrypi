{ inputs }:
let
  lib = inputs.nixpkgs.lib;
  eval =
    module:
    (inputs.self.lib.nixosSystem {
      modules = [
        {
          # This forces evaluation of all types/descriptions in all modules
          documentation.nixos.includeAllModules = true;
        }
        module
      ];
    }).config.system.build.manual.optionsJSON;
  modules = lib.mapAttrsToListRecursive (attrPath: module: {
    name = "options-${lib.concatStringsSep "-" attrPath}";
    value = eval module;
  }) inputs.self.nixosModules;
in
# Return the options JSON derivation.
# If any option type has a circular reference or missing attribute,
# evaluation will fail here.
lib.listToAttrs modules
