{
  lib,
  rustPlatform,
  fetchCrate,
  fontconfig,
  pkg-config,
  nushell,
}: let
  origNu = "0.110.0";
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "nu_plugin_plotters";
    version = "0.2.4+${origNu}";

    src = fetchCrate {
      inherit (finalAttrs) version pname;
      hash = "sha256-fddkK468X+bkSklZXwv83/ZlT/rf2l8LhD8s9mTEHTA=";
    };
    cargoLock.lockFile =
      {
        "${origNu}" = "${finalAttrs.src}/Cargo.lock";
        "0.111.0" = ./lock-0.111.0.toml;
      }.${
        nushell.version
      } or (throw "Need to prepare lock file for nushell version ${nushell.version}");
    prePatch = ''
      sed -ri 's/"${origNu}"/"*"/' Cargo.toml
      cp ../cargo-vendor-dir/Cargo.lock Cargo.lock
    '';

    buildInputs = [fontconfig];
    nativeBuildInputs = [pkg-config];

    meta = {
      description = "Plugin for Nushell that provides easy plotting of data using plotters";
      homepage = "https://github.com/cptpiepmatz/nu-jupyter-kernel/tree/main/crates/nu_plugin_plotters";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [jcaesar];
      mainProgram = "nu_plugin_plotters";
    };
  })
