{
  fetchCrate,
  rustPlatform,
}:
rustPlatform.buildRustPackage (final: {
  pname = "zerostack";
  version = "1.2.2";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-xJsmBVov6rs9w4R7BE2ydIcEgQPJ5BfpvffHW3ZSM+o=";
  };
  cargoHash = "sha256-AI7CIZNpwql78QIFitNimLFi+FGeOO3espXFkEyHRjI=";
  postPatch = ''
    # shh
    substituteInPlace src/config/mod.rs \
      --replace-fail 'cfg.mcp_servers.is_none()' 'false'
  '';
})
