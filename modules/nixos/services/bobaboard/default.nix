{ lib, config, inputs, system, ... }:

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
  };
}
