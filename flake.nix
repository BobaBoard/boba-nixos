{
  description = "Boba Extras";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
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
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # nixConfig = {
  #   extra-substituters = [
  #     "https://bobaboard.cachix.org"
  #   ];
  #   extra-trusted-public-keys = [
  #     "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  #   ];
  # };

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
  
      systems.modules.nixos = with inputs; [
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
