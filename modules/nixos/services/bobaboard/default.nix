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
  
    systemd.services.bobabackend = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "msboba";
        Group = "msboba";
        Restart = "always";
        RestartSec = 20;
        ExecStart = "${inputs.boba-backend.packages."${system}".default}/bin/bobaserver";
      };
    };
  };
}
