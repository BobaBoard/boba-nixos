{ lib, config, inputs, system, pkgs, ... }:

let
  cfg = config.services.bobaboard;
  bobabackend-packages = inputs.boba-backend.packages."${system}";

  inherit (lib) mkEnableOption mkIf;
in
{
  options.services.bobaboard = {
    enable = mkEnableOption "BobaBoard";
  };
  config = mkIf cfg.enable {
    # @TODO(jakehamilton): Add configuration for BobaBoard here.

    networking.firewall.allowedTCPPorts = [
      4200
    ];
    
    users = {
      users.bobaboard = {
        isSystemUser = true;
        group = "bobaboard";
      };

      groups.bobaboard = {};
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_12;
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
      '';
      initialScript = pkgs.writeText "backend-init-script" ''
        CREATE ROLE the_amazing_bobaboard WITH LOGIN PASSWORD 'how_secure_can_this_db_be' CREATEDB;
        CREATE DATABASE bobaboard_test;
        GRANT ALL PRIVILEGES ON DATABASE bobaboard_test TO the_amazing_bobaboard;
      '';
    };


    services.redis.servers.boba-redis = {
      enable = true;
      port = 6379;
    };
    
    systemd.services.bobabackend = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        POSTGRES_USER="the_amazing_bobaboard";
        POSTGRES_PASSWORD="how_secure_can_this_db_be";
        POSTGRES_DB="bobaboard_test";
        POSTGRES_PORT="5432";
        GOOGLE_APPLICATION_CREDENTIALS_PATH="/var/lib/bobaboard/firebase-sdk.json";
        FORCED_USER="c6HimTlg2RhVH3fC1psXZORdLcx2";
        REDIS_HOST="127.0.0.1";
        REDIS_PORT="6379";
      };

      serviceConfig = {
        Type = "simple";
        User = "bobaboard";
        Group = "bobaboard";
        Restart = "always";
        RestartSec = 20;
        ExecStart = "${bobabackend-packages.default}/bin/bobaserver";
      };
    };

    systemd.services.bobadb = {
      after = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.postgresql_12 pkgs.bash ];
      environment = {
        POSTGRES_USER = "the_amazing_bobaboard";
        POSTGRES_DB = "bobaboard_test";
      };

      serviceConfig = {
        Type = "oneshot";
        User = "bobaboard";
        Group = "bobaboard";
        ExecStart = "${bobabackend-packages.bobaserver-assets}/libexec/bobaserver/deps/bobaserver/db/init.sh ${bobabackend-packages.bobaserver-assets}/libexec/bobaserver/deps/bobaserver/db";
      };
    };
  };
}
