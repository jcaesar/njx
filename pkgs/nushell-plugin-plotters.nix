{
  lib,
  rustPlatform,
  fetchCrate,
  fontconfig,
  pkg-config,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "nu_plugin_plotters";
  version = "0.2.4+0.110.0";

  src = fetchCrate {
    inherit (finalAttrs) version pname;
    hash = "sha256-fddkK468X+bkSklZXwv83/ZlT/rf2l8LhD8s9mTEHTA=";
  };
  cargoHash = "sha256-x6+YKx7TfQfJg2JB03UMyPGgpVQaPtofGXtxb6QNlr4=";

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
