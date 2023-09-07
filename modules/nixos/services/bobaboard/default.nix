{ lib, config, inputs, system, pkgs, ... }:

let
  cfg = config.services.bobaboard;
  bobabackend-packages = inputs.boba-backend.packages."${system}";
  bobafrontend-packages = inputs.boba-frontend.packages."${system}";

  inherit (lib) mkEnableOption mkIf;
in
{
  options.services.bobaboard = {
    enable = mkEnableOption "BobaBoard";

    database = {
      name = mkOption {
        type = types.str;
        default = "bobadb";
        description = lib.mdDoc "The name of the database to store data in.";
      };

      user = mkOption {
        type = types.nullOr types.str;
        default = "the_amazing_bobaboard";
        description = lib.mdDoc "The database user to connect as.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = lib.mdDoc "The file to load the database password from.";
      };

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = lib.mdDoc "The database host to connect to.";
      };

      port = mkOption {
        type = types.port;
        default = 5432;
        description = lib.mdDoc "The port used when connecting to the database host.";
      };

      # migrate = mkOption {
      #   type = types.bool;
      #   default = true;
      #   description =
      #     lib.mdDoc "Whether or not to automatically run migrations on startup.";
      # };

      # createLocally = mkOption {
      #   type = types.bool;
      #   default = false;
      #   description = lib.mdDoc ''
      #     When {option}`services.writefreely.database.type` is set to
      #     `"mysql"`, this option will enable the MySQL service locally.
      #   '';
      # };
    };

  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      #TODO: configure these with an option
      80
      443
      6900
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
      # TODO: configure this with an option
      package = pkgs.postgresql_12;
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
      '';
      # TODO: add initial username/password configuration
      initialScript = pkgs.writeText "backend-init-script" ''
        CREATE ROLE ${cfg.database.user} WITH LOGIN PASSWORD 'how_secure_can_this_db_be' CREATEDB;
        CREATE DATABASE ${cfg.database.name};
        GRANT ALL PRIVILEGES ON DATABASE ${cfg.database.name} TO ${cfg.database.user};
      '';
    };


    services.redis.servers.bobaboard = {
      enable = true;
      port = 6379;
    };

    systemd.services.boba-frontend = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      requires = [ "bobabackend.service" ];
      environment = {
        # TODO: the PUBLIC variables will not take effect as they are swapped at build time.
        NEXT_PUBLIC_RELEASE_SUBSCRIPTION_STRING_ID="a87800a6-21e5-46dd-a979-a901cdcea563";
        NEXT_PUBLIC_RELEASE_THREAD_URL="/!memes/thread/2765f36a-b4f9-4efe-96f2-cb34f055d032";
        DEFAULT_BACKEND="https://twisted-minds.bobaboard.com:6900/";
      };

      serviceConfig = {
        Type = "simple";
        User = "bobaboard";
        Group = "bobaboard";
        Restart = "on-failure";
        RestartSec=40;
        ExecStart = "${bobafrontend-packages.default}/bin/boba-frontend";
      };

      startLimitIntervalSec=30;
      startLimitBurst=2;
    };
    
    systemd.services.bobabackend = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      requires = [ "bobaboard-postgres-init.service" ];
      environment = {
        POSTGRES_USER=cfg.database.user;
        POSTGRES_PASSWORD="how_secure_can_this_db_be";
        POSTGRES_DB=${cfg.database.name};
        POSTGRES_PORT=cfg.database.port;
        GOOGLE_APPLICATION_CREDENTIALS_PATH="/var/lib/bobaboard/firebase-sdk.json";
        FORCED_USER="c6HimTlg2RhVH3fC1psXZORdLcx2";
        REDIS_HOST="127.0.0.1";
        REDIS_PORT=builtins.toString config.services.redis.servers.bobaboard.port;
      };

      serviceConfig = {
        Type = "simple";
        User = "bobaboard";
        Group = "bobaboard";
        Restart = "on-failure";
        RestartSec = 40;
        ExecStart = "${bobabackend-packages.default}/bin/bobaserver";
      };

      startLimitIntervalSec=30;
      startLimitBurst=2;
    };

    systemd.services.bobaboard-postgres-init = {
      after = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        POSTGRES_USER = cfg.database.user;
        POSTGRES_DB = ${cfg.database.name};
      };

      serviceConfig = {
        Type = "oneshot";
        User = "bobaboard";
        Group = "bobaboard";
        # ExecStart = "${bobabackend-packages.bobadatabase}/bin/bobadatabase";
        
        # Uncomment this to have the script re-run when boba-server restarts
        # RemainAfterExit = "yes";
      };

      # Only run the script if the .migrate file is not present
      # Remove ExecStart when enabling this
      script = ''
        if ! [ -f /var/lib/bobaboard/.migrate ]; then
          touch /var/lib/bobaboard/.migrate
          ${bobabackend-packages.bobadatabase}/bin/bobadatabase
        fi
      '';
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."bobaboard-frontend" =  {
        enableACME = true;
        forceSSL = true;
        # TODO: enable configuring the server name
        serverName = "twisted-minds.bobaboard.com";
        # TODO: enable configuring the port
        locations."/" = {
          proxyPass = "http://127.0.0.1:3010";
          proxyWebsockets = true; # needed if you need to use WebSocket
          extraConfig =
            # required when the target is also TLS server with multiple hosts
            "proxy_ssl_server_name on;" +
            # required when the server wants to use HTTP Authentication
            "proxy_pass_header Authorization;"
            ;
        };
      };
      virtualHosts."bobaboard-backend" =  {
        enableACME = true;
        forceSSL = true;
        listen = [{         
          # TODO: enable configuring the server name
          addr = "twisted-minds.bobaboard.com";
          port = 6900;
          ssl = true;
        }];
        # TODO: enable configuring the server name
        serverName = "twisted-minds.bobaboard.com";
        locations."/" = {
          # TODO: enable configuring the server port
          proxyPass = "http://127.0.0.1:4200";
          proxyWebsockets = true; # needed if you need to use WebSocket
          extraConfig =
            # required when the target is also TLS server with multiple hosts
            "proxy_ssl_server_name on;" +
            # required when the server wants to use HTTP Authentication
            "proxy_pass_header Authorization;"
            ;
        };
      };
    };
  };
}
