{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (final: {
  pname = "subtui";
  version = "2.14.3";
  src = fetchFromGitHub {
    owner = "MattiaPun";
    repo = "SubTUI";
    tag = "v${final.version}";
    hash = "sha256-LuiWdTfuUsIPV3RhMup6XegZaATFko8cIPI0Xe/O2Sc=";
  };
  vendorHash = "sha256-ZI6K3EupgqPvE1ixd7VpJ9cvND0rwcrvRcPfbdjjK+U=";
})
