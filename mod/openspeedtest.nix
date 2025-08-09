{
  config,
  pkgs,
  lib,
  ...
}: let
  c = "openspeedtest";
  cfg = config.njx.${c};
in {
  options.njx.${c} = {
    package = lib.mkPackageOption {
      pkg = pkgs.callPackage ({
        fetchFromGitHub,
        stdenv,
      }:
        stdenv.mkDerivation {
          pname = c;
          version = "2024-06-04";
          src = fetchFromGitHub {
            owner = c;
            repo = "Speed-Test";
            rev = "3ec39a31ec64858642629991caf0dd14ce7c34ca";
            hash = "sha256-MBVVImy0f+MQnlAYUf77mScpdqkCKi1hdOJEM7Z7KJ0=";
          };
          phases = ["unpackPhase" "installPhase"];
          installPhase = ''
            rm README.md
            mkdir $out
            cp -art $out *
          '';
        }) {};
    } "pkg" {};
    nginx-host = lib.mkOption {
      description = "add config for openspeedtest to this vhost on nginx";
      type = lib.types.str;
      default = null;
    };
  };
  config = lib.mkIf (cfg.nginx-host != null) {
    services.nginx.virtualHosts.${cfg.nginx-host} = {
      root = cfg.package;
      # taken from https://github.com/openspeedtest/Nginx-Configuration/blob/f452c9b25bd28b29f9d23b28b6c1ce709bcfde6c/OpenSpeedTest-Server.conf#L53
      # They ask to donate: https://go.openspeedtest.com/Donate
      locations."/".extraConfig = ''
        if_modified_since off;
        expires off;
        etag off;

        if ($request_method = OPTIONS) {
            add_header 'Access-Control-Allow-Credentials' "true";
            add_header 'Access-Control-Allow-Headers' 'Accept,Authorization,Cache-Control,Content-Type,DNT,If-Modified-Since,Keep-Alive,Origin,User-Agent,X-Mx-ReqToken,X-Requested-With' always;
            add_header 'Access-Control-Allow-Origin' "$http_origin" always;
            add_header 'Access-Control-Allow-Methods' "GET, POST, OPTIONS" always;
            return 200;
        } else {
          add_header 'Access-Control-Allow-Origin' "*" always;
          add_header 'Access-Control-Allow-Headers' 'Accept,Authorization,Cache-Control,Content-Type,DNT,If-Modified-Since,Keep-Alive,Origin,User-Agent,X-Mx-ReqToken,X-Requested-With' always;
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
          add_header Cache-Control 'no-store, no-cache, max-age=0, no-transform';
          add_header Last-Modified $date_gmt;
        }
      '';
      locations."~* ^.+\\.(?:css|cur|js|jpe?g|gif|htc|ico|png|html|xml|otf|ttf|eot|woff|woff2|svg)$".extraConfig = ''
        expires 365d;
        add_header Cache-Control public;
        add_header Vary Accept-Encoding;
        tcp_nodelay off;
        open_file_cache max=3000 inactive=120s;
        open_file_cache_valid 45s;
        open_file_cache_min_uses 2;
        open_file_cache_errors off;
        gzip on;
        gzip_disable "msie6";
        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 6;
        gzip_buffers 16 8k;
        gzip_http_version 1.1;
        gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript image/svg+xml;
      '';
    };
  };
}
