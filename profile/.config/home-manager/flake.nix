{
  description = "Home Manager configuration for dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      # 配置先 user の USER/HOME を使うため、この flake は --impure 前提で評価する。
      requiredEnv = name:
        let
          value = builtins.getEnv name;
        in
        if value != "" then value else throw "home-manager flake requires ${name}; run with --impure";
      username = requiredEnv "USER";
      homeDirectory = requiredEnv "HOME";
      mkHomeConfiguration = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit username homeDirectory;
        };
        modules = [
          ./home.nix
        ];
      };
    in
    {
      homeConfigurations = {
        default = mkHomeConfiguration;
      };
    };
}
