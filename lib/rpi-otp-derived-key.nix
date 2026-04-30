{}:

let
  isSafeSaltPathComponent = name: builtins.match "[A-Za-z0-9._-]+" name != null;
in
{
  inherit isSafeSaltPathComponent;

  saltPathComponentForName =
    name:
    if isSafeSaltPathComponent name then
      name
    else
      "secret-${builtins.substring 0 32 (builtins.hashString "sha256" name)}";
}
