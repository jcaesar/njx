{ writeShellScriptBin }: writeShellScriptBin "ghcr-login" ''
  set -euo pipefail
  gh auth refresh --scopes=read:packages,write:packages
  gh config get -h github.com oauth_token | docker login ghcr.io --username "$(gh config get -h github.com user)" --password-stdin
''
