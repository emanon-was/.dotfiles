{
  description = "Home Manager based dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      username = "nixos";
      homeDirectory = "/home/${username}";
      dotfilesPackage = pkgs.callPackage ./pkgs/dotfiles {
        inherit home-manager;
      };
    in
    {
      packages.${system} = {
        dotfiles = dotfilesPackage;
        default = dotfilesPackage;
      };

      apps.${system} = {
        dotfiles = {
          type = "app";
          program = "${dotfilesPackage}/bin/dotfiles";
          meta.description = "Dotfiles management helper";
        };
        default = self.apps.${system}.dotfiles;
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit self username homeDirectory dotfilesPackage;
        };
        modules = [
          ./home
        ];
      };
    };
}
