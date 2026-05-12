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
      usernames = [
        "nixos"
        "emanon"
      ];
      distUsername = builtins.elemAt usernames 0;
      dotfilesPackage = pkgs.callPackage ./pkgs/dotfiles {
        inherit home-manager;
      };
      dotfilesDist = pkgs.callPackage ./pkgs/dist {
        inherit dotfilesPackage;
        username = distUsername;
        homeFiles = "${self.homeConfigurations.${distUsername}.activationPackage}/home-files";
        homeSessionVars = "${self.homeConfigurations.${distUsername}.activationPackage}/home-path/etc/profile.d/hm-session-vars.sh";
      };
      mkHomeConfiguration = username:
        let
          homeDirectory = "/home/${username}";
        in
        {
          name = username;
          value = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit self username homeDirectory dotfilesPackage;
            };
            modules = [
              ./home
            ];
          };
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

      homeConfigurations = builtins.listToAttrs (map mkHomeConfiguration usernames);
    };
}
