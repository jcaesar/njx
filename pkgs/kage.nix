{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (final: {
  pname = "kage";
  version = "0.1.1";
  src = fetchFromGitHub {
    owner = "tamnd";
    repo = "kage";
    tag = "v${final.version}";
    hash = "sha256-ZYI1Sy04PZPD/GkqZVuNLhv6HEML8UfLzFxoNdgTDBA=";
  };
  prePatch = ''
    substituteInPlace go.mod --replace-fail "go 1.26.4" "go 1.26.3"
  '';
  vendorHash = "sha256-MwlqhsiOTgQZT1onaxIVwfTBqm6fF8dl7ZJiP7iIKZk=";
  subPackages = ["cmd/kage"];
})
