# hack³ - sure wish I knew a nicer way of doing this
# opposite semantics of nixpkg's pkgsCross too - it varies the build system, not the host
{
  extendModules,
  lib,
  flakes,
  ...
}: {
  # this would be a good place for _module.args - except that only applies to the current module
  system.build.argsCross = lib.flip lib.mapAttrs flakes.nixpkgs.legacyPackages (buildSys: _:
    (extendModules {
      modules = lib.singleton ({
          pkgs,
          lib,
          config,
          ...
        } @ args: {
          nixpkgs = {
            buildPlatform = buildSys;
            hostPlatform = config.nixpkgs.system;
          };
          system.build.args = args;
        });
    }).config.system.build.args);
}
