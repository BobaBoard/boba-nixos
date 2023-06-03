{ pkgs, ... }: {
  imports = [
    ./hardware.nix

    # Generated at runtime by nixos-infect
    ./networking.nix
  ];

  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.redis.servers.boba-redis.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRad/cUomx3C2aMaLm+2qlFPLYH/T5is9EF9JFYfMKD" 
  ];

  users.users.msboba = {
    isNormalUser = true;

    name = "msboba";
    initialPassword = "password";

    home = "/home/msboba";
    group = "users";
  
    shell = pkgs.zsh;

    # wheel is needed for sudo
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRad/cUomx3C2aMaLm+2qlFPLYH/T5is9EF9JFYfMKD" 
    ];

  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11";
}
