{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
  ];

  system.stateVersion="22.11";
  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "boba-social";
  networking.domain = "";
  services.openssh.enable = true;
  services.redis.servers."".enable = true;
  services.tailscale.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    # ssh keys
  ];
}