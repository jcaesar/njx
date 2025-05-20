pkgs:
pkgs.helix.overrideAttrs (final: {
  # patch out $PROJECTDIR/.helix/languages.toml loading
  # only on x86 because I'm qemu-compiling for aarch.
  patches = (final.patches or []) ++ pkgs.lib.optional pkgs.stdenv.isx86_64 ./helix.patch;
})
