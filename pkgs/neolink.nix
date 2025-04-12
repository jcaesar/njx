{
  rustPlatform,
  fetchFromGitHub,
  gst_all_1,
  pkg-config,
  glib,
  rust-jemalloc-sys,
  lib,
}:
rustPlatform.buildRustPackage rec {
  pname = "neolink";
  version = "2025-01-30"; # latest release doesn't work with Rust 1.80 - time crate fun

  src = fetchFromGitHub {
    owner = "QuantumEntangledAndy";
    repo = pname;
    rev = "6e05e7844b5b50f89787d30bffcbbd3471bfcfde";
    hash = "sha256-/byGj3Gz+dcriPwyAN54Nppl/UQK2WMD8bYh74wy2t8=";
  };
  cargoLock.lockFile = "${src}/Cargo.lock";

  buildInputs = [
    glib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-rtsp-server
    rust-jemalloc-sys
  ];
  nativeBuildInputs = [
    pkg-config
  ];

  meta = {
    description = "An RTSP bridge to Reolink IP cameras";
    license = lib.licenses.agpl3Plus;
    maintainers = [lib.maintainers.jcaesar];
    homepage = "https://github.com/QuantumEntangledAndy/neolink/";
    mainProgram = "ruri";
  };
}
