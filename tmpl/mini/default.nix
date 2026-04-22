{stdenv}:
stdenv.mkDerivation {
  pname = "mini-example";
  version = "0.1.0";
  src = ./.;
  # just so this actually builds - remove it!
  installPhase = "mkdir $out";
}
