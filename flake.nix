{
  description = "Home Manager based dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
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
      dotfilesDist = pkgs.callPackage ./pkgs/dotfiles/dist.nix {
        homeFiles = "${self.homeConfigurations.${username}.activationPackage}/home-files";
      };
    in
    {
      packages.${system} = {
        dotfiles = dotfilesPackage;
        dotfiles-dist = dotfilesDist;
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
