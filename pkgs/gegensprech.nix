{
  fetchFromGitHub,
  callPackage,
}: let
  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "gegensprech";
    rev = "1370c03bfbd2d21b490e347b32053da241c9a681";
    hash = "sha256-SmdH9/ckrF7JFWLzpBIHBvzWZ+uAriH4JnwTpNnzyOE=";
  };
in
  callPackage src {}
