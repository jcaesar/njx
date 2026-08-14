{
  lib,
  stdenv,
  fetchFromGitHub,
  legacyclonk,
}:
stdenv.mkDerivation (final: {
  pname = "legacyclonk-content";
  version = "4.9.11.13";
  src = fetchFromGitHub {
    repo = "content";
    owner = "legacyclonk";
    rev = "e311300c8f44fc1290d0e4d5a77d69d588ae91cf"; # no tags for 2 years - gotta look for a "Bump version" commit
    hash = "sha256-fUYTfUAH7bpCviUPHWGbH+QYOSoSrQN4m7tHrBtwJTg=";
  };
  dontConfigure = true;
  dontFixup = true;
  nativeBuildInputs = [legacyclonk.engine];
  buildPhase = ''
    runHook preBuild
    for f in *.c4?; do
      echo -n "$f: "
      c4group $f -p # todo not reproducible
    done
    runHook postBuild
  '';
  installPhase = ''
    mkdir $out
    runHook preInstall
    mv -t $out *.c4?
    runHook postInstall
  '';

  meta = {
    description = "The LegacyClonk main game assets (graphics, maps, scripts)";
    # there's also some trademark stuff (must be named "somethingclonk", never just "clonk"), but -nc is unfree anyway, the trademark restriction applies independently of copyright, and the use here is fine
    license = [lib.licenses.cc-by-nc-40];
    maintainers = [lib.maintainers.jcaesar];
    homepage = "https://clonkspot.org/lc-en";
  };
})
