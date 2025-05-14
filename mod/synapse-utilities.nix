{
  pkgs,
  lib,
  config,
  ...
}: {
  environment.systemPackages = lib.optional config.services.matrix-synapse.enable (
    pkgs.writeShellScriptBin "synapse_hash_password" ''
      ${lib.getExe' pkgs.matrix-synapse "hash_password"} \
        -c ${config.services.matrix-synapse.configFile} "$@"
    ''
  );
  # bcrypt_rounds and password_pepper aren't even likely to be defined in that file… oh well.
}
