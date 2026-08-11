let
  defaultscript = src: "unzip ${src} -d $out";
in {
  # base game
  "clonk-rage-4.9.10.7-data" = {
    # unversioned url, but development has ceased more than 15 years ago, so unlikely to change
    url = "http://www.clonkx.de/rage/cr_full_linux.tar.bz2";
    hash = "sha256-UgxqlO0SYUsLCFfcakSfZLjGWWFjuHl6S5cPxh1AQE4=";
    script = src: "tar xvf ${src} -C $out --strip-components=1 --wildcards '*.c4*' '*.txt'";
    homepage = "https://www.clonk.de";
  };
  # expansions which are
  # - above 5MB fetch limit, must be locally installed for network play
  # - developed by core team developers (mostly)
  "hazard-1746" = {
    url = "https://www.westnordost.de/clonk/Hazard1746.zip";
    hash = "sha256-5aG/lugJUn6ZSpaLMCe+TEWd+rRZ7Ujw80ZHI2chFz0=";
    script = defaultscript;
  };
  "s2-tower-of-despair-1.2.0" = {
    url = "https://ccan.de/cgi-bin/ccan/ccan-dl-auth.pl/6058/S2Tower.c4s";
    hash = "sha256-XWWF5abdPibyk5Nm8wz3eBGB0EqroKttIgE/fj0J9rM=";
    homepage = "https://ccan.de/cgi-bin/ccan/ccan-view.pl?a=view&i=6058";
    script = src: "ln -s ${src} $out/S2Tower.c4s";
  };
  "metalmagic-3.1" = {
    name = "metalmagic";
    url = "https://cc-archive.lwrl.de/downloads/dl477/metalmagic3_1.zip";
    hash = "sha256-h1/HVmwLXfl5N/4X2JXlsDnOI9JPjJUiKNs/wmtJMyY=";
    script = defaultscript;
  };
  "inexantros-1" = {
    name = "inexantros";
    url = "https://ccan.de/cgi-bin/ccan/ccan-dl-auth.pl/4135/InExantrosRPG.zip";
    hash = "sha256-7PeLoYo0f0Lxd77XcbyDshDnST2eW8on1SBtbGmkQeo=";
    homepage = "https://ccan.de/cgi-bin/ccan/ccan-view.pl?a=view&i=4135";
    script = defaultscript;
  };
  "clonkmars-1.5" = {
    name = "mars";
    url = "https://clonkspot.org/download/ClonkMars%201.5.zip";
    hash = "sha256-cAy05oaEL+WYzlWeEne/iET1zRQiPwEQxlrc3yBSSB4=";
    script = defaultscript;
  };
}
