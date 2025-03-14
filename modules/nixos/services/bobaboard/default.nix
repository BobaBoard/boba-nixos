{ lib, config, inputs, system, pkgs, ... }:

let
  cfg = config.services.bobaboard;
  bobabackend-packages = inputs.boba-backend.packages."${system}";
  bobafrontend-packages = inputs.boba-frontend.packages."${system}";
  boolToString = b: if b then "true" else "false";


  optional-seed-database = lib.optionalString cfg.database.seed ''
    ${bobabackend-packages.bobadatabase-seed}/bin/bobadatabase-seed
  '';

  inherit (lib) mkEnableOption mkIf mkOption types;
in
{
  options.services.bobaboard = {
    enable = mkEnableOption "BobaBoard";

    ssl = {
      certificate = mkOption {
        type = types.str;
        description = lib.mdDoc "The path to an SSL certificate on the machine (fullchain.pem)";
      };
      key = mkOption {
        type = types.str;
        description = lib.mdDoc "The path to the key of an SSL certificate on the machin (key.pem)";
      };
    };

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

      local = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Whether to start a local database.";
      };

      sslRootCertPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc "A ssl certificate for the connection, if needed.";
      };

      seed = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Whether to seed the DB upon first init";
      };
    };

    firebaseCredentials = mkOption {
      type = types.str;
      description = lib.mdDoc "Where the firebase credentials are strored.";
    };

    server = {
      name = mkOption {
        type = types.str;
        description = lib.mdDoc "The NGNIX server name";
      };
  
      backend = {
        address = mkOption {
          type = types.str;
          description = lib.mdDoc "The NGINX server address for the backend";
        };
        port = mkOption {
          type = types.port;
          default = 6900;
          description = lib.mdDoc "The port used when connecting to the backend host.";
        };
      };

      env-file = mkOption {
        type = types.nullOr types.path;
        description = lib.mdDoc "The path of a file with additional env variables";
      };
    };

    dev = {
      forced-user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc "The dev user any valid credentials will connect as.";
      };
    };

  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 
      80
      443
      cfg.server.backend.port
    ];
    
    users = {
      users.bobaboard = {
        isSystemUser = true;
        group = "bobaboard";
      };

      groups.bobaboard = {};
    };

    services.postgresql = {
      enable = cfg.database.local;
      # TODO: configure this with an option
      package = pkgs.postgresql_14;
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
        DEFAULT_BACKEND="https://${cfg.server.backend.address}:6900/";
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
        POSTGRES_DB=cfg.database.name;
        POSTGRES_HOST=cfg.database.host;
        POSTGRES_PORT=builtins.toString cfg.database.port;
        POSTGRES_SSL_ROOT_CERT_PATH=builtins.toString cfg.database.sslRootCertPath;
        GOOGLE_APPLICATION_CREDENTIALS_PATH=cfg.firebaseCredentials;
        FORCED_USER=cfg.dev.forced-user;
        REDIS_HOST="127.0.0.1";
        REDIS_PORT=builtins.toString config.services.redis.servers.bobaboard.port;
        DB_CONNECTION_TIMEOUT="10000";
        QUERY_CONNECTION_TIMEOUT="10000";
      };

      serviceConfig = {
        Type = "simple";
        User = "bobaboard";
        Group = "bobaboard";
        Restart = "on-failure";
        RestartSec = 40;
        ExecStart = "${bobabackend-packages.default}/bin/bobaserver";
        EnvironmentFile = cfg.database.passwordFile;
      };

      startLimitIntervalSec=30;
      startLimitBurst=2;
    };

    systemd.services.bobaboard-postgres-init = {
      after = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        POSTGRES_USER = cfg.database.user;
        POSTGRES_DB = cfg.database.name;        
        POSTGRES_HOST=cfg.database.host;
        POSTGRES_PORT=builtins.toString cfg.database.port;
      };
      serviceConfig = {
        Type = "oneshot";
        User = "bobaboard";
        Group = "bobaboard";
        EnvironmentFile = cfg.database.passwordFile;
        # ExecStart = "${bobabackend-packages.bobadatabase}/bin/bobadatabase";
        
        # Uncomment this to have the script re-run when boba-server restarts
        # RemainAfterExit = "yes";
      };

      # Only run the script if the .migrate file is not present
      # Remove ExecStart when enabling this
      script = ''
        if ! [ -f /var/lib/bobaboard/.migrate ]; then
          ${bobabackend-packages.bobadatabase-init}/bin/bobadatabase-init
          ${optional-seed-database}
          touch /var/lib/bobaboard/.migrate
        fi
      '';
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      proxyTimeout = "180s";
      virtualHosts."bobaboard-frontend" =  {
        forceSSL = true; 
        sslCertificate = cfg.ssl.certificate;
        sslCertificateKey = cfg.ssl.key;

        serverName = cfg.server.name;
        # TODO: enable configuring the internal frontend port
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
        forceSSL = true;
        sslCertificate = cfg.ssl.certificate;
        sslCertificateKey = cfg.ssl.key;

        listen = [{
          addr = cfg.server.backend.address; 
          port = cfg.server.backend.port;
          ssl = true;
        }];
        serverName = cfg.server.name;
        locations."/" = {
          # TODO: enable configuring the internal server port
          proxyPass = "http://127.0.0.1:4200";
          proxyWebsockets = true; # needed if you need to use WebSocket
          extraConfig =
            # required when the target is also TLS server with multiple hosts
            "proxy_ssl_server_name on;" +
            # required when the server wants to use HTTP Authentication
            "proxy_pass_header Authorization;" +
            "proxy_set_header   X-Real-IP $remote_addr;" +
            "proxy_set_header   Host      $host;" +
            "proxy_set_header Connection \"\";";
        };
      };
    };
  };
}
