{
  fetchCrate,
  rustPlatform,
}:
rustPlatform.buildRustPackage (final: {
  pname = "dirge-agent";
  version = "0.6.4";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-Dbh+/gwYqHr1YcH/fmcU0UUsMZHFcLu8LbPFZEtzS8o=";
  };
  cargoHash = "sha256-dC7RjOt/2RGpd/zsTI5WG8Yct+n/7e3L5SmDguXTYlI=";
  prePatch = "rm -rf .cargo # forces mold";
  nativeBuildInputs = [rustPlatform.bindgenHook];
  doCheck = false;
})
