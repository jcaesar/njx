{
  pkgs,
  lib,
  ...
}: {
  nixpkgs.overlays = lib.singleton (_final: prev: {
    # we got use flags at home
    enableX11 = false;
    # x11Support = false; # too much recompiling
    enableWayland = false;
    sdlSupport = false;
    gtkSupport = false;
    openGLSupport = false;
    qt5Support = false;
    qt6Support = false;
    raspiCameraSupport = false;
    pipewireSupport = false;
    pulseSupport = false;
    jackSupport = false;
    enableJack = false;
    alsaSupport = false;
    enableAlsa = false;
    smartcardSupport = false;
    # compile hack fix
    pythonPackagesExtensions =
      prev.pythonPackagesExtensions
      ++ pkgs.lib.singleton (_pfinal: pprev: {
        paramiko = pprev.paramiko.override {pytestCheckHook = null;};
      });
  });
  system.forbiddenDependenciesRegexes = ["gtk.*" "wayland" "jack.*" "alsa-lib.*"];
  environment.systemPackages = [pkgs.qemu];
}
