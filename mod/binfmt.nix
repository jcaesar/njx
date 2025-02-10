{lib, ...}: let
  systems = ["aarch64-linux" "armv7l-linux" "riscv64-linux" "wasm32-wasi" "wasm64-wasi"];
  qusAttrs = _: {
    wrapInterpreterInShell = false;
    preserveArgvZero = true;
    matchCredentials = true;
    fixBinary = true;
  };
in {
  boot.binfmt.emulatedSystems = systems ++ ["x86_64-windows"];
  boot.binfmt.registrations = lib.genAttrs systems qusAttrs;
  boot.binfmt.preferStaticEmulators = true;
}
