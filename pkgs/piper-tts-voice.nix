{
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  lib,
  piper-tts-small,
}: let
  # name is "voice-quality", e.g. "ryan-high" or "hi_fi_captain-medium"
  voice = params @ {
    locale,
    name,
    quality,
    alias ? name,
    modelHash,
    configHash,
  }: let
    base =
      "https://huggingface.co/rhasspy/piper-voices/resolve/main"
      + "/${lib.toLower (lib.head (lib.strings.split "_" locale))}"
      + "/${locale}/${name}/${quality}/${locale}-${name}-${quality}";
    model = fetchurl {
      url = base + ".onnx";
      hash = modelHash;
    };
    config = fetchurl {
      url = base + ".onnx.json";
      hash = configHash;
    };
  in
    # piper's CLI ignores --config and loads <model>.json, so the config
    # must live next to the model under the same name
    stdenvNoCC.mkDerivation {
      nativeBuildInputs = [makeWrapper];
      name = "piper-voice-${alias}";
      dontUnpack = true;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/share/piper-voices/
        m=$out/share/piper-voices/${locale}-${name}-${quality}.onnx
        ln -s ${model} $m
        ln -s ${config} $m.json
        makeWrapper ${lib.getExe piper-tts-small} $out/bin/piper-${alias} \
          --add-flags "--model $m --config $m.json"
      '';
      meta = {
        description = "Piper TTS preset to the ${name}-${quality} (${locale}) voice";
        homepage = "https://github.com/rhasspy/piper";
        mainProgram = "piper-${alias}";
      };
      passthru = {
        inherit base model config;
        voice = params;
      };
    };
in rec {
  inherit voice;
  all = [ryan-high cori-high alan-medium thorsten-high hi_fi_captain-medium];
  ryan-high = voice {
    locale = "en_US";
    name = "ryan";
    quality = "high";
    modelHash = "sha256-s5kNdgbhg+yNv7pwpGBwdPFi3hoMQS4BgNH/YLsVTso==";
    configHash = "sha256-xtO5jwgxXLS+vw1J1Q/E/0kbUDxkuUDNPVyihUO0gBE==";
  };
  cori-high = voice {
    locale = "en_GB";
    name = "cori";
    quality = "high";
    modelHash = "sha256-RwtN1jTJj4pIUNdib/w9/JB3Riju72YFpt2PiPMKWQM==";
    configHash = "sha256-nn+1tWcWEsIvPIHL5Gwa6HsDGkYyvLUJ5Jna1vHirew==";
  };
  alan-medium = voice {
    locale = "en_GB";
    name = "alan";
    quality = "medium";
    modelHash = "sha256-CjCWaJMiBedigB8e/Cc2zUsBIDKWIq32K+CeVjOdMzA==";
    configHash = "sha256-wPDRJOWJXADnwDs13MgofzGaaZijZbGC3rXI51LujB4==";
  };
  thorsten-high = voice {
    locale = "de_DE";
    name = "thorsten";
    quality = "high";
    modelHash = "sha256-nfHEPGEUnvmznmGOK4YfvkHh/OqTkLLaxi6HYVc+pPE==";
    configHash = "sha256-bec0RE5MP54zt+vidG28GbcehfYT55xlrPYjIAuZp2o==";
  };
  hi_fi_captain-medium = voice {
    locale = "ja_JA";
    name = "hi_fi_captain";
    alias = "ja";
    quality = "medium";
    modelHash = "sha256-Xq+hYQ/HoP8uf96cvgly2HYmbiPY2zMXJ+skZvGUYOs==";
    configHash = "sha256-VC6wtjic2JygKuZicA4d7Enr8bYSghxO0uHRyk4NJXw==";
  };
}
