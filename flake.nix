{
  description = "Boba Extras";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    boba-backend = {
      url = "github:bobaboard/boba-backend/nixos-fix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    boba-frontend = {
      url = "github:bobaboard/boba-frontend";
      inputs.nixpkgs.follows = "nixpkgs";
     };

    snowfall-lib = {
      url = "github:snowfallorg/lib/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;

      src = ./.;

      # Configuration for deploy-rs
      deploy.nodes = {
        boba-social = {
          hostname = "boba-social";
          profiles.system = {
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.boba-social;
            user = "root";
            sshUser = "root";
          };
        };
      };
  
      systems.modules = with inputs; [
        vscode-server.nixosModules.default
      ];

      # These checks will run before deployment to check that everything
      # is configured correctly.
      # NOTE: commented out because it will run checks on MacOS and fail.
      # checks =
      #   builtins.mapAttrs
      #     (system: deploy-lib:
      #       deploy-lib.deployChecks inputs.self.deploy)
      #     inputs.deploy-rs.lib;
    };
}
