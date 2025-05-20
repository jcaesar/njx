pkgs:
pkgs.rq.overrideAttrs (
  final: prev: {
    version = "unstable-2025-05-20";

    src = pkgs.fetchFromGitHub {
      owner = "jcaesar";
      repo = "fork-rq";
      rev = "2ae985b835595d47769b9e83bd99f413044895ec";
      hash = "sha256-+ItBvPWRiJ0QIF9H8h/KnBsjTZDa9NhIdAvDNQkC70g=";
    };

    cargoDeps = pkgs.rustPlatform.importCargoLock {
      lockFile = "${final.src}/Cargo.lock";
      allowBuiltinFetchGit = true;
    };
    cargoHash = null;
    env.VERGEN_GIT_SEMVER = final.src.rev;
    doInstallCheck = false;
  }
)
