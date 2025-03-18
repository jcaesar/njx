final: prev: {
  picard = prev.picard.overrideAttrs { doCheck = false; };
}
