{ lib, config, inputs, system, pkgs, ... }:

let
  cfg = config.services.bobaboard;

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
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE the_amazing_bobaboard WITH LOGIN PASSWORD 'how_secure_can_this_db_be' CREATEDB;
        CREATE DATABASE bobaboard_test;
        GRANT ALL PRIVILEGES ON DATABASE bobaboard_test TO the_amazing_bobaboard;
      '';
  };
  
    systemd.services.bobabackend = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "bobaboard";
        Group = "bobaboard";
        Restart = "always";
        RestartSec = 20;
        ExecStart = "${inputs.boba-backend.packages."${system}".default}/bin/bobaserver";
      };
    };

    systemd.services.bobadb = {
      after = [ "postgres.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.postgresql_12 ];
      environment = {
        POSTGRES_USER = "the_amazing_bobaboard";
        POSTGRES_DB = "bobaboard_test";
      };

      serviceConfig = {
        Type = "oneshot";
        User = "bobaboard";
        Group = "bobaboard";
        ExecStart = "${inputs.boba-backend.packages."${system}".bobadatabase}/bin/bobadatabase";
      };
    };
  };
}
