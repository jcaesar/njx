{
  maven,
  fetchFromGitHub,
  lib,
  makeWrapper,
  jre_minimal,
  jdk_headless,
  opentripplanner_jre ?
    jre_minimal.override {
      modules = [
        "java.base"
        "java.desktop"
        "java.logging"
        "java.management"
        "java.naming"
        "java.prefs"
        "java.sql"
        "java.xml"
        "jdk.unsupported"
      ];
      jdk = jdk_headless;
    },
}:
maven.buildMavenPackage rec {
  pname = "OpenTripPlanner";
  version = "2.7.0";
  src = fetchFromGitHub {
    owner = "opentripplanner";
    repo = pname;
    tag = "v${version}";
    leaveDotGit = true;
    postFetch = ''
      cat > $out/application/src/main/resources/otp-project-info.properties << EOF
      git.commit.id = $(git -C $out rev-parse HEAD)
      project.version = \''${project.version}
      otp.serialization.version.id = \''${otp.serialization.version.id}
      git.commit.id.describe = v${version}
      git.commit.time = $(git -C $out show --format='%aI' -s)
      git.build.time = $(git -C $out show --format='%cI' -s)
      git.branch = v${version}
      git.dirty = false
      EOF
      rm -rf $out/.git
    '';
    hash = "sha256-yVLpyWGMRMo4trBpEbPOi6fKSxjV3kTfXr9EFcmvC5I=";
  };
  mvnJdk = jdk_headless;
  mvnHash = "sha256-c7Oyv6BW18/ZdLjd864AaACjP6BLy3ugCM3dO8QwYXE=";
  mvnParameters = lib.escapeShellArgs [
    "-Dplugin.prettier.skip=true"
    "-Dmaven.gitcommitid.skip=true"
  ];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    runHook preInstall
    install -D otp-shaded/target/otp-shaded-${version}.jar $out/share/otp-${version}.jar
    makeWrapper ${lib.getExe' opentripplanner_jre "java"} $out/bin/opentripplanner \
      --add-flags "\$OPENTRIPPLANNER_JAVA_ARGS -jar $out/share/otp-${version}.jar"
    ln -s otp-${version}.jar $out/share/otp.jar
    runHook postInstall
  '';
  passthru.jre = opentripplanner_jre;
  meta = with lib; {
    description = "An open source multi-modal trip planner";
    license = [
      licenses.lgpl3
      licenses.asl20
    ];
    maintainers = [maintainers.jcaesar];
    platforms = platforms.all;
    homepage = "https://github.com/opentripplanner/OpenTripPlanner";
    mainProgram = "opentripplanner";
  };
}
