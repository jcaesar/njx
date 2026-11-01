{
  lib,
  fetchFromGitHub,
  rustPlatform,
}: let
  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "rust-tool-garden";
    rev = "5ba913792af9145b5f3de7ba601b04e53a2b6e66";
    hash = "sha256-UfBfT/n9TPlca1qLgdYQ21tIcL8zggrg6w12/Ua32oY=";
  };
  plant = name: cargoHash:
    rustPlatform.buildRustPackage {
      inherit name cargoHash;
      meta.mainProgram = name;
      src = "${src}/${name}";
    };
in
  # todo: meh, recurseIntoAttrs only works in legacyPackages. (same for piper-tts-voiced)
  lib.mapAttrs plant {
    "pnnsul" = "sha256-3wF/qGa6+OoT6DEGn41U7XdzuQz+g21OlS1ASQx9/+4=";
    "relarc" = "sha256-4EBXvHXVfreODsX7ab1arrKpmRW9C/n4lGHN1vR67PM=";
    "fstnns" = "sha256-1n0O6S1lwmVhmAYuylGrtQL5UI//h9gEryt4OffjdNg=";
    "sleepier" = "sha256-KBvZ97F8WKRrP00C87mnflGN+GWGyk+MFfbmDIrMJyg=";
  }
