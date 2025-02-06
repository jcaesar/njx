{
  fetchFromGitHub,
  callPackage,
}: let
  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "rowserext";
    rev = "e2f323c3fa298fc5dd7a9506aa1e53eca088ecaa";
    hash = "sha256-IcXYhDFoux5oPET4pw+6/zCR0X4l1XDMs37Co9kY8ic=";
  };
in
  callPackage src {}
