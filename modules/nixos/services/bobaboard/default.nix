{ lib, config, ... }:

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
  };
}
