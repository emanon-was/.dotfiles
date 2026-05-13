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
      distUsername = "dotfiles";
      distHomeDirectory = "/home/${distUsername}";
      currentUsername =
        let
          value = builtins.getEnv "DOTFILES_USERNAME";
        in
        if value != "" then value else distUsername;
      currentHomeDirectory =
        let
          value = builtins.getEnv "DOTFILES_HOME_DIRECTORY";
        in
        if value != "" then value else "/home/${currentUsername}";
      dotfilesPackage = pkgs.callPackage ./pkgs/dotfiles {
        inherit home-manager;
      };
      dotfilesDist = pkgs.callPackage ./pkgs/dist {
        inherit dotfilesPackage;
        username = distUsername;
        homeFiles = "${self.homeConfigurations.dist.activationPackage}/home-files";
        homeSessionVars = "${self.homeConfigurations.dist.activationPackage}/home-path/etc/profile.d/hm-session-vars.sh";
      };
      mkHomeConfigurationFor = { username, homeDirectory }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit self username homeDirectory dotfilesPackage;
          };
          modules = [
            ./home
          ];
        };
    in
    {
      packages.${system} = {
        dotfiles = dotfilesPackage;
        dotfiles-dist = dotfilesDist;
        default = dotfilesPackage;
      };

      checks.${system} = {
        dotfiles-tests = pkgs.runCommand "dotfiles-tests"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              diffutils
              findutils
              gawk
              gnugrep
              gnused
            ];
          }
          ''
            bash ${self.outPath}/tests/dotfiles-flake-switch.sh
            bash ${self.outPath}/tests/dotfiles-commands.sh
            DOTFILES_TEST_DIST_ROOT=${dotfilesDist} bash ${self.outPath}/tests/dotfiles-dist-install.sh
            touch "$out"
          '';
      };

      apps.${system} = {
        dotfiles = {
          type = "app";
          program = "${dotfilesPackage}/bin/dotfiles";
          meta.description = "Dotfiles management helper";
        };
        default = self.apps.${system}.dotfiles;
      };

      homeConfigurations = {
        current = mkHomeConfigurationFor {
          username = currentUsername;
          homeDirectory = currentHomeDirectory;
        };
        dist = mkHomeConfigurationFor {
          username = distUsername;
          homeDirectory = distHomeDirectory;
        };
      };
    };
}
