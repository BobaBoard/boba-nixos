{
  description = "Boba Extras";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?rev=b1f87ca164a9684404c8829b851c3586c4d9f089";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    boba-backend.url = "github:bobaboard/boba-backend/devenv";
    boba-frontend.url = "github:jakehamilton/boba-frontend/hack/nix";

    snowfall-lib = {
      url = "github:snowfallorg/lib";
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
