{
  fetchFromGitHub,
  callPackage,
}: let
  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "rowserext";
    rev = "527ea5618da50343c98e26d8919591f3220779bc";
    hash = "sha256-s+3EyIVyUfPkJHzHhqBprpCHlG1G4NNE3bZ98J5W6zI=";
  };
in
  callPackage src {}
