{ pkgs, inputs, config, lib, environment, ... } : {
  imports = [
    ./hardware.nix
    # Generated at runtime by nixos-infect
    ./networking.nix
  ];

  services.openssh.enable = true;
  # Might need to run `sudo tailscale up --ssh=false` if SSH hangs on update
  services.tailscale.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    lego = inputs.unstable.legacyPackages.${pkgs.system}.lego;
  };

  services.bobaboard = {
    enable = true;
    database = {
      user = "bobaboard";
      host = "private-big-global-dboi-do-user-12927016-0.c.db.ondigitalocean.com";
      local = false;
      port = 25060;
      name = "bobadb";
      passwordFile = "/var/lib/bobaboard/db-password";
      sslRootCertPath = "/var/lib/bobaboard/db-ca";
      seed = true;
    };

    server = {
      # This has to be an address whose DNS is mapped to this
      # server. It can be the address of any realm (or of no realm),
      # as long as the DNS is mapped.
      backend = {
        address = "fandom-coders.boba.social";
      };
      name =  "^(?<subdomain>.+)boba\.social$";
    };

    firebaseCredentials = "/var/lib/bobaboard/firebase-sdk.json";

    ssl = {
      certificate = "${config.security.acme.certs."boba.social".directory}/fullchain.pem";
      key = "${config.security.acme.certs."boba.social".directory}/key.pem";
    };
  };

  security.acme = {
    acceptTerms = true;

    defaults = {
      email = "essential.randomn3ss@gmail.com";
      dnsProvider = "porkbun";
      dnsPropagationCheck = true;

      # Must be owned by user "acme" and group "nginx"
      credentialsFile = "/var/lib/acme-secrets/porkbun";

      # Makes certificates readable by nginx
      group = lib.mkIf config.services.nginx.enable "nginx";

      # Uncomment this to use the staging server
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory";

      # Reload nginx when certs change.
      reloadServices = lib.optional config.services.nginx.enable "nginx.service";
    };

    certs."boba.social" = {
      domain = "*.boba.social";
    };
  };

  programs.git.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;

    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins=["git" "vi-mode" "systemd" "z"];
    };
  };
  services.vscode-server.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRad/cUomx3C2aMaLm+2qlFPLYH/T5is9EF9JFYfMKD"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwaaCUq3Ooq1BaHbg5IwVxWj/xmNJY2dDthHKPZefrHXv/ksM/IREgm38J0CdoMpVS0Zp1C/vFrwGfaYZ2lCF5hBVdV3gf+mvj8Yb8Xpm6aM4L5ig+oBMp/3cz1+g/I4aLMJfCKCtdD6Q2o4vtkTpid6X+kL3UGZbX0HFn3pxoDinzOXQnVGSGw+pQhLASvQeVXWTJjVfIWhj9L2NRJau42cBRRlAH9kE3HUbcgLgyPUZ28aGXLLmiQ6CUjiIlce5ee16WNLHQHOzVfPJfF1e1F0HwGMMBe39ey3IEQz6ab1YqlIzjRx9fQ9hQK6Du+Duupby8JmBlbUAxhh8KJFCJB2cXW/K5Et4R8GHMS6MyIoKQwFUXGyrszVfiuNTGZIkPAYx9zlCq9M/J+x1xUZLHymL85WLPyxhlhN4ysM9ILYiyiJ3gYrPIn5FIZrW7MCQX4h8k0bEjWUwH5kF3dZpEvIT2ssyIu12fGzXkYaNQcJEb5D9gT1mNyi2dxQ62NPZ5orfYyIZ7fn22d1P/jegG+7LQeXPiy5NLE6b7MP5Rq2dL8Y9Oi8pOBtoY9BpLh7saSBbNFXTBtH/8OfAQacxDsZD/zTFtCzZjtTK6yiAaXCZTvMIOuoYGZvEk6zWXrjVsU8FlqF+4JOTfePqr/SSUXNJyKnrvQJ1BfHQiYsrckw=="
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
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwaaCUq3Ooq1BaHbg5IwVxWj/xmNJY2dDthHKPZefrHXv/ksM/IREgm38J0CdoMpVS0Zp1C/vFrwGfaYZ2lCF5hBVdV3gf+mvj8Yb8Xpm6aM4L5ig+oBMp/3cz1+g/I4aLMJfCKCtdD6Q2o4vtkTpid6X+kL3UGZbX0HFn3pxoDinzOXQnVGSGw+pQhLASvQeVXWTJjVfIWhj9L2NRJau42cBRRlAH9kE3HUbcgLgyPUZ28aGXLLmiQ6CUjiIlce5ee16WNLHQHOzVfPJfF1e1F0HwGMMBe39ey3IEQz6ab1YqlIzjRx9fQ9hQK6Du+Duupby8JmBlbUAxhh8KJFCJB2cXW/K5Et4R8GHMS6MyIoKQwFUXGyrszVfiuNTGZIkPAYx9zlCq9M/J+x1xUZLHymL85WLPyxhlhN4ysM9ILYiyiJ3gYrPIn5FIZrW7MCQX4h8k0bEjWUwH5kF3dZpEvIT2ssyIu12fGzXkYaNQcJEb5D9gT1mNyi2dxQ62NPZ5orfYyIZ7fn22d1P/jegG+7LQeXPiy5NLE6b7MP5Rq2dL8Y9Oi8pOBtoY9BpLh7saSBbNFXTBtH/8OfAQacxDsZD/zTFtCzZjtTK6yiAaXCZTvMIOuoYGZvEk6zWXrjVsU8FlqF+4JOTfePqr/SSUXNJyKnrvQJ1BfHQiYsrckw=="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11";
}
