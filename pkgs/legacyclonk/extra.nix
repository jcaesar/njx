{
  # expansions which are
  # - above 5MB fetch limit, must be locally installed for network play
  # - developed by core team developers (mostly)
  "s2-tower-of-despair" = {
    version = "1.2.0";
    url = "https://ccan.de/cgi-bin/ccan/ccan-dl-auth.pl/6058/S2Tower.c4s";
    hash = "sha256-XWWF5abdPibyk5Nm8wz3eBGB0EqroKttIgE/fj0J9rM=";
    homepage = "https://ccan.de/cgi-bin/ccan/ccan-view.pl?a=view&i=6058";
    script = src: "ln -s ${src} $out/S2Tower.c4s";
  };
  "metalmagic" = {
    version = "3.1";
    url = "https://cc-archive.lwrl.de/downloads/dl477/metalmagic3_1.zip";
    hash = "sha256-h1/HVmwLXfl5N/4X2JXlsDnOI9JPjJUiKNs/wmtJMyY=";
  };
  "inexantros" = {
    version = "1";
    url = "https://ccan.de/cgi-bin/ccan/ccan-dl-auth.pl/4135/InExantrosRPG.zip";
    hash = "sha256-7PeLoYo0f0Lxd77XcbyDshDnST2eW8on1SBtbGmkQeo=";
    homepage = "https://ccan.de/cgi-bin/ccan/ccan-view.pl?a=view&i=4135";
  };
  "clonkmars" = {
    version = "1.5";
    url = "https://clonkspot.org/download/ClonkMars%201.5.zip";
    hash = "sha256-cAy05oaEL+WYzlWeEne/iET1zRQiPwEQxlrc3yBSSB4=";
  };
  "ultimate-compilation" = {
    version = "3";
    url = "https://www.westnordost.de/clonk/UltimateClonkCompilation-v3.0.zip";
    hash = "sha256-9vzha2u0yeFQuiOYdlaKhBh6sMPirUVhnRH9teCCFMM=";
    script = src: ''
      # iffy, because it contains CR in full,
      # and we don't want the CR content clashing with the LC content
      # Skylies is iffy because of its cp1252 filename.
      unzip ${src} \
          "Clonk Rage/Collection/" \
          "Clonk Rage/*.c4*" \
          "Clonk Rage/*.txt" \
        -x \
          "Clonk Rage/System.c4g" \
          "Clonk Rage/Graphics.c4g" \
          "Clonk Rage/Fantasy.c4d" \
          "Clonk Rage/Fantasy.c4f" \
          "Clonk Rage/FarWorlds.c4d" \
          "Clonk Rage/FarWorlds.c4f" \
          "Clonk Rage/Hazard.c4d" \
          "Clonk Rage/Hazard.c4f" \
          "Clonk Rage/Knights.c4d" \
          "Clonk Rage/Knights.c4f" \
          "Clonk Rage/Material.c4g" \
          "Clonk Rage/Melees.c4f" \
          "Clonk Rage/Missions.c4f" \
          "Clonk Rage/Music.c4g" \
          "Clonk Rage/Objects.c4d" \
          "Clonk Rage/Races.c4f" \
          "Clonk Rage/Sound.c4g" \
          "Clonk Rage/Tutorial.c4f" \
          "Clonk Rage/Western.c4d" \
          "Clonk Rage/Western.c4f" \
          "Clonk Rage/Worlds.c4f" \
          "Clonk Rage/*.c4p" \
          "Clonk Rage/Collection/Hazard/Hazard.c4f" \
          "Clonk Rage/Collection/BaseMelees/*Skylies.c4s" \
          "Clonk Rage/OpenSSL.txt" \
        -d $out
      mv "$out/Clonk Rage"/* $out
      rmdir "$out/Clonk Rage"
      mv $out/*.txt $out/Collection/
    '';
  };
}
