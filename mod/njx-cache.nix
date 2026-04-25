{...}: {
  nix = {
    settings = {
      substituters = [
        "https://nix-cache.liftm.de/"
      ];
      trusted-public-keys = [
        "nix-cache.liftm.de:Yq9o+2P3aw5miJmJtsjATsNGnKqXt0DCLOsu1nb/cLw="
      ];
      always-allow-substitutes = true;
    };
  };
}
