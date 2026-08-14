{
  lib,
  stdenv,
  fetchFromGitHub,
  legacyclonk,
}:
stdenv.mkDerivation (final: {
  pname = "legacyclonk-content";
  version = "4.9.10.15";
  src = fetchFromGitHub {
    repo = "content";
    owner = "legacyclonk";
    tag = "v${final.version}";
    hash = "sha256-t3UAZ+sOt5aUncoWsdXQts3SNPcvK6hT5PKYUvy/xN0=";
  };
  phases = ["installPhase"];
  nativeBuildInputs = [legacyclonk.engine];
  installPhase = ''
    runHook preInstall
    for f in *.c4?; do
      c4group $out/$(basename $f) -p $f/
    done
    runHook postInstall
  '';
})
