{
  lib,
  rustPlatform,
  fetchCrate,
  nushell,
}: let
  versions = {
    "0.110.0" = {
      hash = "sha256-NYo93QNbD2e5xtH7ekiFSdkDUe4LIy26i2JLOpliTl4=";
      cargoHash = "sha256-o8v3H89pNb8HrOdBIaeRr0tmSvG9+xziba3G6LTVSkY=";
      version = "0.21.0";
    };
    "0.111.0" = {
      hash = "sha256-goAq14bTMZFNqRRYdGexFhBu4xZNRidem57btMQUlbI=";
      cargoHash = "sha256-lGxwrkjQPK054cmMs0livc8g3MBlQex+m1XUBlDxjWs=";
      version = "0.22.0";
    };
  };
  version = versions.${nushell.version};
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "nu_plugin_file";
    inherit (version) version cargoHash;
    src = fetchCrate {
      inherit (finalAttrs) version pname;
      inherit (version) hash;
    };

    meta = {
      description = "Nushell plugin that will inspect a file and return information based on it's magic number";
      homepage = "https://github.com/fdncred/nu_plugin_file/";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [jcaesar];
      mainProgram = "nu_plugin_file";
    };
  })
