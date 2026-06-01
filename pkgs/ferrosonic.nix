{
  fetchCrate,
  rustPlatform,
  openssl,
  pkg-config,
}:
rustPlatform.buildRustPackage (final: {
  pname = "ferrosonic";
  version = "0.8.1";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-eYXZpWmCmRvlWm+ciTJoA46JbG2fQjbSOrM1vn8OzGg=";
  };
  cargoHash = "sha256-KN+Lg+N/XOvAg3+TTeoJLW/y0rgY0ji6ubTzoU6oLdI=";
  buildInputs = [openssl];
  nativeBuildInputs = [pkg-config];
})
