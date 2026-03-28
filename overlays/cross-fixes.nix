# Fixes for packages that fail during cross-compilation.
# Only applied when hostPlatform != buildPlatform.
final: prev:

prev.lib.optionalAttrs (prev.stdenv.hostPlatform != prev.stdenv.buildPlatform) {

  # gnutls doc build compiles helper programs (errcodes, printlist) for the
  # target arch and then tries to run them on the build host → Exec format error.
  # Upstream only disables docs for MinGW; we extend this to all cross builds.
  gnutls = prev.gnutls.overrideAttrs (old: {
    configureFlags = (old.configureFlags or [ ]) ++ [ "--disable-doc" ];
    outputs = prev.lib.filter (o: o != "devdoc" && o != "man") (old.outputs or [ "out" ]);
  });

}
