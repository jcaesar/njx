{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.njx.log-to-aws;
in {
  options.njx.log-to-aws = {
    enable = lib.mkEnableOption "Copy system journal to AWS CloudWatch";
    group = lib.mkOption {
      description = "CloudWatch log group";
      type = lib.types.str;
    };
    region = lib.mkOption {
      description = "AWS region";
      type = lib.types.str;
      default = "ap-northeast-1";
    };
  };
  config = lib.mkIf cfg.enable {
    services.vector = {
      enable = true;
      package = pkgs.vector-cloudwatchsyslogs;
      journaldAccess = true;
      settings = {
        sources.journal.type = "journald";
        sinks.cw = {
          type = "aws_cloudwatch_logs";
          inputs = ["journal"];
          group_name = cfg.group;
          stream_name = "{{ host }}";
          encoding.codec = "json";
          region = cfg.region;
          auth.credentials_file = "/run/credentials/vector.service/cloudwatch"; # I'd prefer to use "\${CREDENTIALS_DIRECTORY}/cloudwatch", but that fails the verify check
          batch.timeout_secs = 10;
          create_missing_group = true;
          create_missing_stream = true;
        };
      };
    };
    systemd.services.vector = {
      serviceConfig.LoadCredential = "cloudwatch:/etc/secrets/cloudwatch";
      environment.VECTOR_LOG = "warn"; # It'll log "Putting events successfull" to the syslog, and then try to log that. Indefinitely.
    };
    njx.manual.vector-aws-cloudwatch = let name = config.networking.hostName; in ''
      1. Create access
         ```
         aws iam create-user --user-name ${name}-log-appender
         aws iam attach-user-policy --user-name ${name}-log-appender --policy-arn arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs
         aws iam create-access-key --user-name ${name}-log-appender
         ```
      2. Create credential file at `/etc/secrets/cloudwatch`
         ```
         touch /etc/secrets/cloudwatch
         chmod 400 /etc/secrets/cloudwatch
         ```
         ```
         [default]
         aws_access_key_id = (output from create-access-key)
         aws_secret_access_key = (output from create-access-key)
         ```
      3. After vector's first run, fix log retention policy
         ```
         aws logs put-retention-policy --log-group-name ${cfg.group} --retention-in-days 30
         ```
         (Vector itself has functionality for that, but it requires allowing changing the retention policy, including shortening it unreasonably)
    '';
  };
}
