{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) genList length elemAt attrValues;
  inherit (lib) types mkOption flatten mapAttrsToList unique listToAttrs mkIf;
  slugify = lib.replaceChars ["/" "@"] ["_" "_"];
  cfg = config.services.sftpgo.overwriteUserData;
  enable = config.services.sftpgo.enable && cfg != {} && cfg != null;
  folders = unique (
    flatten
    (mapAttrsToList (_: user: attrValues user.mounts) cfg.users)
  );
  folderId = folder:
    (listToAttrs (genList (idx: {
      name = elemAt folders idx;
      value = idx + 1;
    }) (length folders))).${
      folder
    };
  mkFolder = folder: {
    filesystem.provider = 0;
    id = folderId folder;
    mapped_path = folder;
    name = slugify folder;
  };
  users = lib.attrsToList cfg.users;
  mkUser = idx: let
    user = elemAt users idx;
  in {
    username =
      if user.value.userName or null != null
      then user.value.userName
      else user.name;
    home_dir = user.value.home;
    id = idx + 1;
    virtual_folders =
      mapAttrsToList (
        to: from:
          mkFolder from // {virtual_path = to;}
      )
      user.value.mounts;
    permissions."/" = ["*"];
    has_password = true;
    max_sessions = 0;
    status = 1;
    uid = 0;
    gid = 0;
    download_data_transfer = 0;
    filesystem.provider = 0;
  };
  settings = {
    folders = map mkFolder folders;
    users = genList mkUser (length users);
    version = 16;
  };
  settingsJson = pkgs.writeText "sftpgo-data.json" (builtins.toJSON settings);
  startPre = pkgs.writeScript "loadsftpgo" ''
    #!${pkgs.runtimeShell}
    cd /var/lib/sftpgo
    umask 0137
    rm sftpgo.db
    ${lib.getExe pkgs.jq} \
      --slurpfile data ${settingsJson} \
      --slurpfile pws /etc/secrets/sftpgo.json \
      -n '$data[] | . * {users: (.["users"] | [.[] | . + {password: ($pws[0][.username])}])}' \
      >${config.services.sftpgo.loadDataFile}
  '';
in {
  options.services.sftpgo.overwriteUserData.passwordFile = mkOption {
    type = types.path;
    description = ''
      JSON file containing one dictionary mapping user names to password hashes.
      The hashes can e.g. be obtained from `openssl passwd -6`
    '';
  };
  options.services.sftpgo.overwriteUserData.users = mkOption {
    description = ''
      Reset user data (users, folders, quotas, …) to this config on every start.
      Only allows to configure local folders.
    '';
    type = types.attrsOf (
      types.submodule {
        options = {
          userName = mkOption {
            type = types.nullOr types.str;
            description = "Attribute name is default";
            default = null;
          };
          home = mkOption {
            type = types.path;
          };
          mounts = mkOption {
            type = types.attrsOf types.path;
            default = {};
          };
        };
      }
    );
  };
  config.services.sftpgo.loadDataFile = mkIf enable "/var/lib/sftpgo/nix-load.json";
  config.systemd.services.sftpgo = mkIf enable {
    serviceConfig.ExecStartPre = [startPre];
  };
}
