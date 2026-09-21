{ }:

let
  pathComponents = path: builtins.filter builtins.isString (builtins.split "/" path);

  isCanonicalAbsolutePath =
    path:
    path == "/"
    || (
      builtins.match "/[^/]+(/[^/]+)*" path != null
      && builtins.all (component: component != "." && component != "..") (pathComponents path)
    );

  isSafePathComponent =
    name: name != "." && name != ".." && builtins.match "[A-Za-z0-9._-]+" name != null;

  pathComponentForName =
    name:
    if isSafePathComponent name then
      name
    else
      "secret-${builtins.substring 0 32 (builtins.hashString "sha256" name)}";
in
{
  inherit
    isCanonicalAbsolutePath
    isSafePathComponent
    pathComponentForName
    ;

  # Kept as a compatibility alias for callers that use the salt-specific name.
  isSafeSaltPathComponent = isSafePathComponent;
  saltPathComponentForName = pathComponentForName;
}
